# Local example

Applies circuit-bun to a throwaway Rocky Linux 10 container with systemd, installing Bun 1.4.4. You need Conn3x and Podman.

```sh
./up.sh
conn3x init
conn3x apply
conn3x plan
```

The second plan says `No changes.` To see it working:

```sh
ssh -p 2311 -i id_ed25519 -o UserKnownHostsFile=known_hosts root@127.0.0.1 'bun --version; mkdir -p /tmp/t && cd /tmp/t && bun init -y >/dev/null && bun add --exact semver@7.8.5 && grep semver package.json'
```

`up.sh` listens on `127.0.0.1:2311`. Set `PORT` to use another port, and pass the same port to Conn3x with `-var port=PORT`. Set `CONTAINERFILE` to test another distro, such as one of the images in Conn3x's `test/images`, which CI uses.

`./down.sh` stops the container, which removes it and its volumes, then removes the key and the state.
