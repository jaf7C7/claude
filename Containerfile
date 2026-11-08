# Base image: `podman` (quay.io/podman/stable) or `debian`.
ARG BASE=podman

FROM debian:stable-slim AS base-debian

RUN apt-get update && apt-get install --assume-yes --no-install-recommends \
	locales curl ca-certificates git podman crun uidmap catatonit passt \
	libcap2-bin

# Debian ships newuidmap/newgidmap setuid-root but built without
# capability support, so inside a rootless container they can't write
# uid_map. Swap the setuid bit for file capabilities.  See
# <https://samuel.forestier.app/blog/security/podman-rootless-in-podman-rootless-the-debian-way>
RUN chmod 0755 /usr/bin/newuidmap /usr/bin/newgidmap && \
	setcap cap_setuid=ep /usr/bin/newuidmap && \
	setcap cap_setgid=ep /usr/bin/newgidmap && \
	apt-get purge --assume-yes --autoremove libcap2-bin

# Nested podman maps the claude user's sub[ug]ids, so they must exist
# inside this container. `./run` gives it ids 0-65536, so skip the
# default allocation (100000+) and hand out everything above claude's
# own uid.
RUN useradd --key SUB_UID_COUNT=0 --key SUB_GID_COUNT=0 --create-home claude && \
	usermod --add-subuids 1001-65536 --add-subgids 1001-65536 claude

COPY containers.conf /etc/containers/containers.conf
COPY --chown=claude:claude podman-containers.conf /home/claude/.config/containers/containers.conf

# Tell nested podman it's already in a configured user namespace.
ENV _CONTAINERS_USERNS_CONFIGURED=""

# The official podman image already has the nested podman config (the
# same files as containers.conf and podman-containers.conf), file
# capabilities on newuidmap/newgidmap, and a uid 1000 `podman` user with
# sub[ug]ids. It also declares VOLUMEs on /var/lib/containers and
# /home/podman/.local/share/containers, which can't be undone here.
FROM quay.io/podman/stable AS base-podman

RUN dnf install --assumeyes git-core && dnf clean all

# `./run` expects uid 1000 to be claude, with its home in /home/claude.
RUN usermod --login claude --home /home/claude --move-home podman && \
	groupmod --new-name claude podman && \
	sed --in-place 's/^podman:/claude:/' /etc/subuid /etc/subgid

COPY --chown=claude:claude podman-storage.conf /home/claude/.config/containers/storage.conf

FROM base-${BASE}

ENV LANG=C.UTF-8

USER claude

# Nested image storage lives in .local/share/containers. `./run` mounts
# a volume there, because overlay can't use the outer container's
# overlay root as its upper dir.
RUN mkdir --parents /home/claude/work /home/claude/.local/share/containers
WORKDIR /home/claude/work

COPY --chown=claude:claude .claude.json   /home/claude/.claude.json
COPY --chown=claude:claude settings.json /home/claude/.claude/settings.json

ARG CLAUDE_VERSION=stable
RUN curl -fsSL https://claude.ai/install.sh | bash -sl $CLAUDE_VERSION

ENV TERM=xterm-256color

ENTRYPOINT ["/home/claude/.local/bin/claude"]
