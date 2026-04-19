# windrose-egg

Run a Windrose dedicated server on HypeServ using a custom Docker image with Wine and Xvfb.

## Running on Pterodactyl or Pelican
> [!WARNING]
> This egg and the corresponding docker image are built for the custom Software we are running at HypeServ, most bits are probably compatible with Pterodactyl or Pelican, but we have not tested this functionality!

1. Import the egg file
Download the egg-windrose.json file and import it into Pterodactyl or Pelican.

That's it! The Egg will use our custom docker image on runtime, and setup the server automatically.


## Build a custom image

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
