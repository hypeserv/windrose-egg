#!/bin/bash
# HypeServ runtime entrypoint for Windrose Dedicated Server

source /home/container/scripts/functions.sh

SERVER_FILES="/home/container"
SERVER_EXEC="$SERVER_FILES/R5/Binaries/Win64/WindroseServer-Win64-Shipping.exe"
SERVER_DESC="$SERVER_FILES/R5/ServerDescription.json"

# Env defaults 
UPDATE_ON_START="${UPDATE_ON_START:-true}"
INVITE_CODE="${INVITE_CODE:-}"
SERVER_NAME="${SERVER_NAME:-Windrose Server}"
SERVER_PASSWORD="${SERVER_PASSWORD:-}"
MAX_PLAYERS="${MAX_PLAYERS:-10}"
P2P_PROXY_ADDRESS="${P2P_PROXY_ADDRESS:-0.0.0.0}"
GENERATE_SETTINGS="${GENERATE_SETTINGS:-true}"

export WINEPREFIX="${WINEPREFIX:-/home/container/.wine}"
export WINEARCH="win64"
export WINEDEBUG="${WINEDEBUG:-fixme-all}"
export WINEDLLOVERRIDES="mscoree,mshtml="
export DISPLAY=:99

echo "    __  __                _____                ";
echo "   / / / /_  ______  ___ / ___/___  ______   __";
echo "  / /_/ / / / / __ \\/ _ \\\\__ \\/ _ \\/ ___/ | / /";
echo " / __  / /_/ / /_/ /  __/__/ /  __/ /   | |/ / ";
echo "/_/ /_/\\__, / .___/\\___/____/\\___/_/    |___/  ";
echo "      /____/_/                                 ";

# Optional update / validate on start 
if [[ "$UPDATE_ON_START" == "true" ]]; then
    install_server
else
    LogWarn "UPDATE_ON_START=false — skipping server update"
fi

# Verify executable 
if [[ ! -f "$SERVER_EXEC" ]]; then
    LogError "Server executable not found at: $SERVER_EXEC"
    LogError "Run the installer or set UPDATE_ON_START=true"
    exit 1
fi

# First-boot: let server generate ServerDescription.json 
if [[ "$GENERATE_SETTINGS" != "false" && ! -f "$SERVER_DESC" ]]; then
    LogAction "First boot — generating default config files"
    LogInfo "Starting server temporarily to create ServerDescription.json…"

    Xvfb :99 -screen 0 1024x768x16 &
    XVFB_PID=$!
    sleep 2

    wine "$SERVER_EXEC" -log -STDOUT >/dev/null 2>&1 &
    FIRSTRUN_PID=$!

    count=0
    until [[ -f "$SERVER_DESC" ]] || (( count >= 120 )); do
        sleep 1
        (( count++ ))
    done

    if [[ ! -f "$SERVER_DESC" ]]; then
        LogError "ServerDescription.json was not created after ${count}s — aborting"
        kill "$FIRSTRUN_PID" 2>/dev/null
        wait "$FIRSTRUN_PID" 2>/dev/null
        wineserver -k 2>/dev/null
        kill "$XVFB_PID" 2>/dev/null
        exit 1
    fi

    LogSuccess "ServerDescription.json generated"
    kill "$FIRSTRUN_PID" 2>/dev/null
    wait "$FIRSTRUN_PID" 2>/dev/null
    wineserver -k 2>/dev/null
    sleep 2
    # Xvfb stays running for the main server process below
else
    # Start Xvfb for the main process
    Xvfb :99 -screen 0 1024x768x16 &
    XVFB_PID=$!
    sleep 2
fi

# Patch ServerDescription.json 
if [[ "$GENERATE_SETTINGS" != "false" ]]; then
    LogAction "Patching server config"
    tr -d '\r' < "$SERVER_DESC" | jq \
        --arg proxy       "${P2P_PROXY_ADDRESS}" \
        --arg invite      "${INVITE_CODE}" \
        --arg name        "${SERVER_NAME}" \
        --arg password    "${SERVER_PASSWORD}" \
        --argjson maxp    "${MAX_PLAYERS}" \
    '
      .ServerDescription_Persistent.P2pProxyAddress = $proxy |
      .ServerDescription_Persistent.MaxPlayerCount  = $maxp  |
      if $invite   != "" then .ServerDescription_Persistent.InviteCode           = $invite   else . end |
      if $name     != "" then .ServerDescription_Persistent.ServerName           = $name     else . end |
      if $password != "" then
          .ServerDescription_Persistent.IsPasswordProtected = true  |
          .ServerDescription_Persistent.Password            = $password
      else
          .ServerDescription_Persistent.IsPasswordProtected = false |
          .ServerDescription_Persistent.Password            = ""
      end
    ' > "${SERVER_DESC}.tmp" && mv "${SERVER_DESC}.tmp" "$SERVER_DESC"
    LogSuccess "Config patched"
fi

# Graceful shutdown trap 
term_handler() {
    shutdown_server || {
        local pid
        pid=$(pgrep -f "wineserver64" | head -1)
        [[ -n "$pid" ]] && kill -SIGKILL "$pid"
    }
    kill "$XVFB_PID" 2>/dev/null
    sleep 2
    [[ -n "$WINE_PID" ]] && wait "$WINE_PID"
}
trap 'term_handler' SIGTERM SIGINT

# Launch server 
LogAction "Starting Windrose Dedicated Server"

LOG_FILE="$SERVER_FILES/R5/Saved/Logs/R5.log"

wine "$SERVER_EXEC" -log >/dev/null 2>&1 &
WINE_PID=$!

# Tail the Unreal log to stdout so Wings can show it in the console
tail -F "$LOG_FILE" 2>/dev/null &

wait "$WINE_PID"