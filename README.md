# Containerised claude on debian stable.

## Authentication

```
$ claude setup-token  # authenticate and copy CLAUDE_CODE_OATH_TOKEN
$ wl-paste | podman secret create claude_token -
```

## Building the container

```
$ sh build.sh
```

## Running the container

```
$ ./run
```
