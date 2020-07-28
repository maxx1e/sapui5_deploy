FROM debian:stable-slim
# Build Arguments
ARG NODE_VERSION=v12.16.1
ARG NPM_CONFIG_LOGLEVEL=info
ARG NODE_HOME="/opt/nodejs"
ARG CM_VERSION=2.0.1
ARG JAVA_KEYSTORE=cacerts
ARG JAVA_KEYSTORE_PWD=changeit
# Run environment and shell
ENV ROOT_CERT="root.cer"
ENV INTER_CERT="inter.cer"
ENV HOST_CERT="srv.cer"
ENV CM_HOME=/opt/sap
ENV CM_USER_HOME=/home/cmtool
ENV CMCLIENT_OPTS="-Djavax.net.ssl.trustStore=/usr/lib/jvm/java-11-openjdk-amd64/lib/security/cacerts"
ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
ARG DEBIAN_FRONTEND=noninteractive
ENV NODE_PATH="${NODE_HOME}/node-${NODE_VERSION}-linux-x64/lib/node_modules"
# Image issue while JRE installation (https://github.com/debuerreotype/docker-debian-artifacts/issues/24)
RUN mkdir -p /usr/share/man/man1
# Update repo and install some tools
RUN apt-get update && apt-get install -y --no-install-recommends git wget ca-certificates curl openjdk-11-jre-headless && \
    rm -rf /var/lib/apt/lists/*
# Handle user permissions
RUN groupadd --system node && \
useradd --system --create-home --gid node --groups audio,video node && \
mkdir --parents /home/node && \
chmod a+w "/home/node" && \
useradd --home-dir "${CM_USER_HOME}" --create-home --shell /bin/bash --user-group --uid 1000 --comment 'DevOps CM tool' --password "$(echo weUseCm |openssl passwd -1 -stdin)" cmtool && \
    # Allow anybody to write into the images HOME
    chmod a+w "${CM_USER_HOME}"
# Download and install Node + SAPUI5 deployer module
RUN echo "[INFO] Install Node $NODE_VERSION." && \
mkdir -p "${NODE_HOME}" && \
wget -qO- "http://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.gz" | tar -xzf - -C "${NODE_HOME}" && \
ln -s "${NODE_HOME}/node-${NODE_VERSION}-linux-x64/bin/node" /usr/local/bin/node && \
ln -s "${NODE_HOME}/node-${NODE_VERSION}-linux-x64/bin/npm" /usr/local/bin/npm && \
ln -s "${NODE_HOME}/node-${NODE_VERSION}-linux-x64/bin/npx" /usr/local/bin/ && \
# Config NPM
npm install ui5-task-nwabap-deployer --global && \
npm config set @sap:registry https://npm.sap.com --global && \
npm install --global @ui5/cli && \
ln -s "${NODE_HOME}/node-${NODE_VERSION}-linux-x64/bin/ui5" /usr/local/bin/ui5 && \
# smoke tests
node --version && \
npm --version
# Download CM client and install LICENSE
RUN echo "[INFO] Install CM clinet $CM_VERSION." && \
    mkdir -p "${CM_HOME}" && \
    curl --silent --show-error "https://repo1.maven.org/maven2/com/sap/devops/cmclient/dist.cli/${CM_VERSION}/dist.cli-${CM_VERSION}.tar.gz" | tar -xzf - -C "${CM_HOME}" && \
    curl --silent --show-error --output ${CM_HOME}/LICENSE "https://raw.githubusercontent.com/SAP/devops-cm-client/master/LICENSE" && \
    chown -R root:root "${CM_HOME}" && \
    ln -s "${CM_HOME}/bin/cmclient" "/usr/local/bin/cmclient"
WORKDIR $CM_HOME/bin
