# HypeServ Wings Egg Docker Image — Windrose Dedicated Server
# This Egg is built for the proprietary HypeServ Infrastructure,
# it might work with standard Pterodactyl or Pelican but this has not been tested
FROM --platform=linux/amd64 debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install System deps + Wine
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        gnupg \
        unzip \
        procps \
        libicu-dev \
        gettext-base \
        xvfb \
        xauth \
        jq \
    && curl -fsSL https://dl.winehq.org/wine-builds/winehq.key | \
        gpg --dearmor -o /usr/share/keyrings/winehq-archive.key \
    && echo "deb [arch=amd64,i386 signed-by=/usr/share/keyrings/winehq-archive.key] \
        https://dl.winehq.org/wine-builds/debian/ bookworm main" \
        > /etc/apt/sources.list.d/winehq.list \
    && apt-get update \
    && apt-get install -y --install-recommends winehq-stable \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install .NET 8 runtime (required by DepotDownloader)
RUN curl -sL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh && \
    chmod +x /tmp/dotnet-install.sh && \
    /tmp/dotnet-install.sh --channel 8.0 --runtime dotnet \
        --install-dir /usr/share/dotnet && \
    ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet && \
    rm /tmp/dotnet-install.sh

# Install DepotDownloader 
ARG DEPOT_DOWNLOADER_VERSION=3.4.0
RUN curl -sL \
    "https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_${DEPOT_DOWNLOADER_VERSION}/DepotDownloader-linux-x64.zip" \
    -o /tmp/dd.zip && \
    mkdir -p /depotdownloader && \
    unzip /tmp/dd.zip -d /depotdownloader && \
    chmod +x /depotdownloader/DepotDownloader && \
    rm /tmp/dd.zip

# ── Container user (uid 1000 — Pterodactyl standard) ───────────────────────
RUN useradd -m -u 1000 -s /bin/bash container

# ── Pre-initialise Wine prefix ──────────────────────────────────────────────
ENV WINEPREFIX=/home/container/.wine \
    WINEARCH=win64 \
    WINEDLLOVERRIDES="mscoree,mshtml=" \
    DISPLAY=:99

RUN Xvfb :99 -screen 0 1024x768x16 & \
    sleep 3 && \
    su -l container -c \
      "DISPLAY=:99 WINEPREFIX=/home/container/.wine WINEARCH=win64 \
       WINEDLLOVERRIDES='mscoree,mshtml=' \
       winecfg -v win10 >/dev/null 2>&1; wineboot --init >/dev/null 2>&1" && \
    kill %1 2>/dev/null; true

# ── Copy scripts ─────────────────────────────────────────────────────────────
COPY scripts/ /home/container/scripts/
RUN chmod +x /home/container/scripts/*.sh && \
    chown -R container:container /home/container/

# Pterodactyl bind-mounts /home/container as the persistent server root
WORKDIR /home/container
USER    container

ENTRYPOINT ["/home/container/scripts/entrypoint.sh"]