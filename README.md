# windrose-egg

Run a Windrose dedicated server on HypeServ using a custom Docker image with Wine and Xvfb.

## Setup for a custom image

1. Build and push the image:
   ```bash
   docker build -t ghcr.io/yourname/windrose-pterodactyl:latest .
   docker push ghcr.io/yourname/windrose-pterodactyl:latest
   ```

2. Update the image in `egg-windrose.json`.

3. Import the egg into Pterodactyl (you might have to change the version property in the json to a value that pterodactyl accepts) and create a server.

## Variables

- `UPDATE_ON_START`
- `INVITE_CODE`
- `SERVER_NAME`
- `SERVER_PASSWORD`
- `MAX_PLAYERS`
- `P2P_PROXY_ADDRESS`
- `GENERATE_SETTINGS`
- `STEAM_USER`
- `STEAM_PASS`

## Notes

- Windrose uses a Windows server binary, so we use Wine in this image.
- Server files are installed into `/home/container/server-files`.
- `ServerDescription.json` will be generated and patched automatically on first boot.

## License

Apache-2.0