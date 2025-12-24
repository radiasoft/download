# Development

## starting the dev server

This will call dev-setup.sh the first time:

```sh
bash dev-server.sh
```

The server runs in ~/src so don't use this on a public network.

## build rpm-code container

```sh
bash dev-build.sh common
```

This creates the rpm-code container after it creates the common rpm.

## building packages

```sh
bash dev-build.sh test
```

## debugging

You can insert

```sh
sleep 100000 || true
```

May be good to put a `set -x` before so you see the commands leading
up to it. You can then `docker exec -it <container> bash` to poke
around. Then kill the `sleep`, and the build will continue if you want
it to. Or, you can kill the container.

Add a `sleep 100000` at the first line of `install_err_trap` and after
the `install_msg` in `install_err` so you can poke around when there's
an error.
