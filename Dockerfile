FROM node:22-alpine

# Install dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git

# Create app directory
WORKDIR /screeps

# Install screeps and mods
RUN npm install -g screeps@latest

# Expose ports
EXPOSE 21025 21026

# Start command
CMD ["npx", "screeps", "start"]
