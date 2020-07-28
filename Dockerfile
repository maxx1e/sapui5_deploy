# Build Arguments
ARG NODE_VERSION=v12.16.1
ARG NPM_CONFIG_LOGLEVEL=info
#ARG JAVA_KEYSTORE=cacerts
#ARG JAVA_KEYSTORE_PWD=changeit
#ARG ROOT_CERT="root.cer"
#ARG INTER_CERT="inter.cer"
#ARG HOST_CERT="srv.cer"
#ARG SELF_CERT="sm2.cer"
ARG NODE_HOME="/opt/nodejs"
ARG DEBIAN_FRONTEND=noninteractive
ENV NODE_PATH="${NODE_HOME}/node-${NODE_VERSION}-linux-x64/lib/node_modules"
# Update repo and install some tools
RUN apt-get update && apt-get install -y --no-install-recommends git wget ca-certificates && \
    rm -rf /var/lib/apt/lists/*
# Handle user permissions
RUN groupadd --system node && \
useradd --system --create-home --gid node --groups audio,video node && \
mkdir --parents /home/node && \
chmod a+w "/home/node"
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
# Install certs. However instead of using COPY instruction. it is possible to provide path via docker volume
# RUN echo "[INFO] Install certificates in the JRA truststore." && \
#    keytool -import -trustcacerts -noprompt -keystore /usr/lib/jvm/java-11-openjdk-amd64/lib/security/cacerts -storepass changeit -alias "${HOST_CERT%.*}" -file "${CM_USER_HOME}/${HOST_CERT}" && \
#    keytool -import -trustcacerts -noprompt -keystore /usr/lib/jvm/java-11-openjdk-amd64/lib/security/cacerts -storepass changeit -alias "${INTER_CERT%.*}" -file "${CM_USER_HOME}/${INTER_CERT}" && \
#    keytool -import -trustcacerts -noprompt -keystore /usr/lib/jvm/java-11-openjdk-amd64/lib/security/cacerts -storepass changeit -alias "${ROOT_CERT%.*}" -file "${CM_USER_HOME}/${ROOT_CERT}"  && \
#    keytool -import -trustcacerts -noprompt -keystore /usr/lib/jvm/java-11-openjdk-amd64/lib/security/cacerts -storepass changeit -alias "${SELF_CERT%.*}" -file "${CM_USER_HOME}/${SELF_CERT}"
WORKDIR /usr/node/home