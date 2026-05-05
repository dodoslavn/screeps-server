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
    echo 'mkdir -p logs .screepsdb' >> /entrypoint.sh && \
    echo 'if [ -f /screepsrc ]; then' >> /entrypoint.sh && \
    echo '  cp /screepsrc .screepsrc' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    echo 'if [ ! -f mods.json ]; then' >> /entrypoint.sh && \
    echo '  echo "{}" > mods.json' >> /entrypoint.sh && \
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
