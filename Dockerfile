FROM node:lts-alpine

WORKDIR /app

# openssl is required by prisma, git is required to clone the meshtastic protobufs
RUN apk add --no-cache openssl git

# Copy only package files and install deps
# This layer will be cached as long as package*.json don't change
COPY package*.json package-lock.json* ./
RUN npm ci

# Copy the rest of your source
COPY . .

# Clone the Meshtastic protobufs required by the MQTT collector (src/mqtt.js).
# These are GPLv3 licensed and therefore intentionally not committed to this MIT
# licensed repo (see .gitignore and the notice in src/mqtt.js). They are fetched
# at build time instead. Override PROTOBUFS_REF to build against a specific
# branch or tag of https://github.com/meshtastic/protobufs
ARG PROTOBUFS_REF=master
RUN rm -rf src/external/protobufs \
    && git clone --depth 1 --branch "${PROTOBUFS_REF}" https://github.com/meshtastic/protobufs.git src/external/protobufs

# ensure entrypoint scripts are executable
RUN chmod +x docker/*.sh

EXPOSE 8080

# default to running the map ui; docker-compose overrides this to run the collector
CMD ["/app/docker/map.sh"]
