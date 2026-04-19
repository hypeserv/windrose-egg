#!/bin/bash
cd /home/container

    echo "    __  __                _____                ";
    echo "   / / / /_  ______  ___ / ___/___  ______   __";
    echo "  / /_/ / / / / __ \\/ _ \\\\__ \\/ _ \\/ ___/ | / /";
    echo " / __  / /_/ / /_/ /  __/__/ /  __/ /   | |/ / ";
    echo "/_/ /_/\\__, / .___/\\___/____/\\___/_/    |___/  ";
    echo "      /____/_/                                 ";

# Setup Wine & Xvfb Environment
export WINEPREFIX="/home/container/.wine"
export WINEDLLOVERRIDES="mscoree,mshtml="
export WINEARCH="win64"
export DISPLAY=":99"

echo "[Info] Starting Xvfb on display :99..."
rm -f /tmp/.X99-lock
Xvfb :99 -screen 0 1024x768x16 -nolisten tcp &
XVFB_PID=$!
sleep 2

# Initialize Wine prefix if it doesn't exist
if [ ! -d "$WINEPREFIX" ]; then
    echo "[Info] Initializing Wine prefix..."
    winecfg -v win10 >/dev/null 2>&1
    wineboot --init >/dev/null 2>&1
    sleep 2
fi

# Optional SteamCMD Update on Start
UPDATE_ON_START="${UPDATE_ON_START:-true}"
if [ "${UPDATE_ON_START}" == "true" ] || [ "${UPDATE_ON_START}" == "1" ]; then
    if [ -f "/home/container/steamcmd/steamcmd.sh" ]; then
        echo "[Info] Checking for game updates via SteamCMD..."
        STEAM_LOGIN="anonymous"
        if [ -n "${STEAM_USER}" ] && [ "${STEAM_USER}" != "null" ]; then
            STEAM_LOGIN="${STEAM_USER} ${STEAM_PASS}"
        fi
        /home/container/steamcmd/steamcmd.sh +force_install_dir /home/container +login ${STEAM_LOGIN} +app_update 4129620 validate +quit
    else
        echo "[Warn] SteamCMD not found at /home/container/steamcmd/steamcmd.sh. Skipping update."
    fi
fi

# Execute Startup Command
echo "[Info] Starting Windrose Server..."
PARSED=$(echo "$STARTUP" | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo "[Exec] ${PARSED}"

eval "$PARSED"
EXIT_CODE=$?

# Cleanup
echo "[Info] Server process exited with code $EXIT_CODE. Cleaning up..."
wineserver -k 2>/dev/null
kill "$XVFB_PID" 2>/dev/null

exit $EXIT_CODE