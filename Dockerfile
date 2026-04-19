FROM --platform=linux/amd64 debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install prerequisites, tini, and WineHQ Stable
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
        xauth \
        tzdata \
        tini \
    && mkdir -pm755 /etc/apt/keyrings \
    && curl -fsSL https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key \
    && echo "deb [arch=amd64,i386 signed-by=/etc/apt/keyrings/winehq-archive.key] https://dl.winehq.org/wine-builds/debian/ bookworm main" > /etc/apt/sources.list.d/winehq.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends winehq-stable \
    && apt-get purge -y gnupg \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -d /home/container -m -s /bin/bash container
COPY --chmod=755 scripts/entrypoint.sh /home/container/entrypoint.sh

# Switch to container user
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

# Ensure clean shutdown
STOPSIGNAL SIGINT

# Use tini as init process to handle signals correctly
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/home/container/entrypoint.sh"]