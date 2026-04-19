FROM --platform=linux/amd64 debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        jq \
        lib32gcc-s1 \
        procps \
        xvfb \
        xauth && \
    curl -fsSL https://dl.winehq.org/wine-builds/winehq.key | \
        gpg --dearmor -o /usr/share/keyrings/winehq-archive.key && \
    echo "deb [arch=amd64,i386 signed-by=/usr/share/keyrings/winehq-archive.key] https://dl.winehq.org/wine-builds/debian/ bookworm main" \
        > /etc/apt/sources.list.d/winehq.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends winehq-stable && \
    apt-get purge -y gnupg && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /steamcmd && \
    curl -sL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | \
    tar -C /steamcmd -zx && \
    chmod +x /steamcmd/steamcmd.sh

RUN useradd -m -u 1000 -s /bin/bash container

ENV WINEPREFIX=/home/container/.wine \
    WINEARCH=win64 \
    WINEDLLOVERRIDES="mscoree,mshtml=" \
    DISPLAY=:99

RUN Xvfb :99 -screen 0 1024x768x16 & \
    sleep 3 && \
    su -l container -c "DISPLAY=:99 WINEPREFIX=/home/container/.wine WINEARCH=win64 WINEDLLOVERRIDES='mscoree,mshtml=' winecfg -v win10 >/dev/null 2>&1; wineboot --init >/dev/null 2>&1" && \
    kill %1 2>/dev/null || true

COPY scripts/ /home/container/scripts/
RUN chmod +x /home/container/scripts/*.sh && \
    chown -R container:container /home/container/

WORKDIR /home/container
USER container

ENTRYPOINT ["/home/container/scripts/entrypoint.sh"]