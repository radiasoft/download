# Development

## starting the dev server

This will call dev-setup.sh the first time:

```sh
bash dev-server.sh
```

The server runs in ~/src so don't use this on a public network.

## building packages

```sh
dev-build.sh test
```

## build rpm-code container

```sh
dev-build.sh common
```

This creates the rpm-code container after it creates the common rpm.
