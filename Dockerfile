# https://docs.ghost.org/faq/node-versions/
# https://github.com/nodejs/Release (looking for "LTS")
# https://github.com/TryGhost/Ghost/blob/v4.1.2/package.json#L38

FROM node:hydrogen-bookworm-slim 

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get upgrade --no-install-recommends -y && apt-get install --no-install-recommends -y \
    ca-certificates \
    git \
    nano \
    openssh-client \
    && apt-get clean -y || true && rm -rf /var/lib/apt/lists/* \
    && apt-get autoclean -y && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /var/apt/cache/* 

ENV NODE_ENV production 

RUN npm install -g "ghost-cli@latest" && \
    npm cache clean 

ARG GHOST_VERSION
ENV GHOST_VERSION $GHOST_VERSION 

ENV GHOST_INSTALL /var/lib/ghost
ENV GHOST_CONTENT /var/lib/ghost/content

RUN mkdir -p "$GHOST_INSTALL" && \
    chown node:node "$GHOST_INSTALL" && \
    mkdir -p "$GHOST_CONTENT" && \
    chown node:node "$GHOST_CONTENT" && \
    chmod 1777 "$GHOST_CONTENT"

WORKDIR ${GHOST_INSTALL} 
USER node

RUN rm -Rf "$GHOST_INSTALL"/* && \
    ghost install "$GHOST_VERSION" --db mysql --dbhost mysql --no-prompt --no-stack --no-setup --dir "$GHOST_INSTALL"

RUN ghost config --no-prompt --ip '::' --port 2368 --url 'http://localhost:2368' && \
    ghost config paths.contentPath "$GHOST_CONTENT" && \
    ln -s config.production.json "$GHOST_INSTALL/config.development.json" && \
    readlink -f "$GHOST_INSTALL/config.development.json" 

USER root

RUN mv "$GHOST_CONTENT" "$GHOST_INSTALL/content.orig" && \
    mkdir -p "$GHOST_CONTENT" && \
    chown node:node "$GHOST_CONTENT" && \
    chmod 1777 "$GHOST_CONTENT" 

USER node

WORKDIR $GHOST_INSTALL
VOLUME $GHOST_CONTENT

COPY entrypoint.sh /usr/local/bin/
# RUN chmod +x /usr/local/bin/entrypoint.sh
# ENV PATH $PATH:/usr/local/bin:$GHOST_INSTALL/current/node_modules/.bin
ENTRYPOINT ["entrypoint.sh"]

EXPOSE 2368
CMD ["node", "current/index.js"]
