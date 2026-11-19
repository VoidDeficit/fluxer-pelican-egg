# Fluxer Pelican Egg

A [Pelican Panel](https://pelican.dev) egg for [Fluxer](https://github.com/fluxerapp/fluxer), the open-source chat and voice platform.

## Build the image

Fluxer does not publish a public image, so build it first in a clone of `fluxerapp/fluxer`:

```bash
make toolchain native-deps dist && make image   # tags fluxer:dev
```

GitHub Actions builds and pushes `ghcr.io/voiddeficit/fluxer-pelican` on every push to `main`, weekly, and on demand (Actions → Build image → Run workflow). To build by hand instead, run this from this repo:

```bash
docker build -t ghcr.io/voiddeficit/fluxer-pelican:latest .
docker push ghcr.io/voiddeficit/fluxer-pelican:latest
```

## Install

1. Admin → Eggs → Import → `egg-fluxer.json`.
2. Create a server with that egg.
3. Set **Domain**. PostgreSQL runs inside the container (data in `/home/container/postgres`, listening on 127.0.0.1 only). To use an external server instead, set **External Postgres URL**.
4. Put a TLS reverse proxy in front of the allocated port.
5. Start the server, open the domain and enter the setup token printed in the console.

## Notes

- The built-in database password is generated on first start and kept in `/home/container/.pgpass_fluxer` (hidden from the file manager).
- Uses Postgres for cache/queues (no Valkey) and stores uploads in `/home/container/data`.
- Voice (LiveKit) is not configured.
- Untested: startup command and port handling may need adjusting.
