# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.241.1/containers/debian/.devcontainer/base.Dockerfile

# [Choice] Debian version (use bullseye on local arm64/Apple Silicon): bullseye, buster
ARG VARIANT="buster"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}


ENV SOURCEMOD_DIR "/addons"
RUN mkdir $SOURCEMOD_DIR \
    && cd $SOURCEMOD_DIR \
    && curl -sL "https://mms.alliedmods.net/mmsdrop/1.11/mmsource-1.11.0-git1148-linux.tar.gz" | tar -xz addons --strip-components 1 \
    && curl -sL "https://sm.alliedmods.net/smdrop/1.11/sourcemod-1.11.0-git6906-linux.tar.gz" | tar -xz addons --strip-components 1


RUN mkdir /tmp/plugin \
    && cd /tmp/plugin \
    && curl -sL "https://github.com/clugg/sm-json/archive/refs/tags/v4.1.1.tar.gz" | tar -xz --strip-components 1 \
    && cp -R addons/* $SOURCEMOD_DIR/ \
    && rm -rf /tmp/plugin