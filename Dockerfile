FROM node:22-alpine

# Install dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git \
    bash

# Create app directory
WORKDIR /screeps

# Install screeps globally
RUN npm install -g screeps@latest

# Expose ports
EXPOSE 21025 21026

# Create entrypoint script
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'set -e' >> /entrypoint.sh && \
    echo 'cd /screeps' >> /entrypoint.sh && \
    echo 'mkdir -p logs' >> /entrypoint.sh && \
    echo 'if [ -f /screepsrc ]; then' >> /entrypoint.sh && \
    echo '  cp -f /screepsrc .screepsrc' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    echo 'if [ ! -f mods.json ]; then' >> /entrypoint.sh && \
    echo '  echo "{}" > mods.json' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    echo 'if [ ! -f .screepsdb ] || [ ! -s .screepsdb ]; then' >> /entrypoint.sh && \
    echo '  echo "{\"filename\":\".screepsdb\",\"collections\":[{\"name\":\"env\",\"data\":[{\"databaseVersion\":4,\"meta\":{\"revision\":0,\"created\":1620000000000,\"version\":0},\"\$loki\":1}],\"idIndex\":[1],\"binaryIndices\":{},\"constraints\":null,\"uniqueNames\":[],\"transforms\":{},\"objType\":\"env\",\"dirty\":false,\"cachedIndex\":null,\"cachedBinaryIndex\":null,\"cachedData\":null,\"adaptiveBinaryIndices\":true,\"transactional\":false,\"cloneObjects\":false,\"cloneMethod\":\"parse-stringify\",\"asyncListeners\":false,\"disableMeta\":false,\"disableChangesApi\":true,\"disableDeltaChangesApi\":true,\"autoupdate\":false,\"serializableIndices\":true,\"disableFreeze\":true,\"ttl\":null,\"maxId\":1,\"DynamicViews\":[],\"events\":{\"insert\":[null],\"update\":[null],\"pre-insert\":[],\"pre-update\":[],\"close\":[],\"flushbuffer\":[],\"error\":[],\"delete\":[null],\"warning\":[null]},\"changes\":[],\"dirtyIds\":[]}],\"databaseVersion\":1.5,\"engineVersion\":1.5,\"autosave\":true,\"autosaveInterval\":10000,\"autosaveHandle\":null,\"throttledSaves\":true,\"options\":{\"autosave\":true,\"autosaveInterval\":10000,\"serializationMethod\":\"normal\",\"destructureDelimiter\":\"\$<\\\n\"},\"persistenceMethod\":\"fs\",\"persistenceAdapter\":null,\"verbose\":false,\"events\":{\"init\":[null],\"loaded\":[],\"flushChanges\":[],\"close\":[],\"changes\":[],\"warning\":[]},\"ENV\":\"NODEJS\"}" > .screepsdb' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    echo 'if [ ! -f package.json ]; then' >> /entrypoint.sh && \
    echo '  echo "Initializing Screeps..."' >> /entrypoint.sh && \
    echo '  npx screeps init' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    echo 'echo "Starting Screeps server..."' >> /entrypoint.sh && \
    echo 'npx screeps start' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Start command
CMD ["/entrypoint.sh"]
