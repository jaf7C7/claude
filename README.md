# Containerised claude on the official podman image (or debian stable).

## Authentication

```
$ claude setup-token  # authenticate and copy CLAUDE_CODE_OATH_TOKEN
$ wl-paste | podman secret create claude_token -
```

## Building the container

```
$ sh build.sh                          # official podman image, tagged claude
$ sh build.sh --build-arg BASE=debian  # debian stable instead
$ sh build.sh --tag claude:podman      # choose the tag (default: claude)
```

Other options are passed through to `podman build`. `./run` always
starts the image tagged `claude`.

## Running the container

```
$ ./run
```
