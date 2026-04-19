#!/bin/bash
# Shared logging helpers

export RESET='\033[0m'
export WhiteText='\033[0;37m'
export RedBoldText='\033[1;31m'
export GreenBoldText='\033[1;32m'
export YellowBoldText='\033[1;33m'
export CyanBoldText='\033[1;36m'

Log()       { printf "${2}%s${RESET}\n" "${3}${1}${4}"; }
LogInfo()   { Log "$1" "$WhiteText"; }
LogWarn()   { Log "$1" "$YellowBoldText"; }
LogError()  { Log "$1" "$RedBoldText"; }
LogSuccess(){ Log "$1" "$GreenBoldText"; }
LogAction() { Log "$1" "$CyanBoldText" "==== " " ===="; }

# Download / validate the Windrose server files via steamcmd.
install_server() {
    echo "    __  __                _____                ";
    echo "   / / / /_  ______  ___ / ___/___  ______   __";
    echo "  / /_/ / / / / __ \\/ _ \\\\__ \\/ _ \\/ ___/ | / /";
    echo " / __  / /_/ / /_/ /  __/__/ /  __/ /   | |/ / ";
    echo "/_/ /_/\\__, / .___/\\___/____/\\___/_/    |___/  ";
    echo "      /____/_/                                 ";
    echo "Windrose Server Utils";
   LogAction "Installing / validating Windrose Dedicated Server (App 4129620)"

    local steam_login="anonymous"
    if [[ -n "${STEAM_USER:-}" && "${STEAM_USER}" != "null" ]]; then
        steam_login="${STEAM_USER} ${STEAM_PASS:-}"
    fi

    # Ensure SteamCMD is present in the volume
    if [[ ! -f "/home/container/steamcmd/steamcmd.sh" ]]; then
        LogWarn "SteamCMD missing in /home/container/steamcmd. Downloading..."
        mkdir -p /home/container/steamcmd
        curl -sSL -o /home/container/steamcmd/steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
        tar -xzvf /home/container/steamcmd/steamcmd.tar.gz -C /home/container/steamcmd
        rm /home/container/steamcmd/steamcmd.tar.gz
    fi

    /home/container/steamcmd/steamcmd.sh \
        +force_install_dir /home/container/server-files \
        +login ${steam_login} \
        +app_update 4129620 validate \
        +quit

    LogSuccess "Server files ready"
}

# Graceful shutdown — sends SIGTERM to the Wine server process.
shutdown_server() {
    LogAction "Attempting graceful server shutdown"
    local pid
    pid=$(pgrep -f "wineserver64" | head -1)

    if [[ -z "$pid" ]]; then
        LogWarn "No wineserver64 process found"
        return 1
    fi

    kill -SIGTERM "$pid"
    local count=0
    while kill -0 "$pid" 2>/dev/null && (( count < 30 )); do
        sleep 1
        (( count++ ))
    done

    if kill -0 "$pid" 2>/dev/null; then
        LogWarn "Server did not stop in time — forcing"
        return 1
    fi

    LogSuccess "Server stopped gracefully"
    return 0
}