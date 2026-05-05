#!/bin/bash
# Setup .screepsrc with Steam API key from environment

if [ -z "$STEAM_KEY" ]; then
    echo "Error: STEAM_KEY environment variable not set"
    exit 1
fi

cat > .screepsrc << EOF
[steamKey]
$STEAM_KEY
[assetdir]
/usr/local/lib/node_modules/screeps/assets
[runners_cnt]
6
[processors_cnt]
6
[logdir]
logs
[port]
21025
[host]
0.0.0.0
[mongo_host]
mongo
[mongo_port]
27017
[mongo_database]
screeps
[redis_host]
redis
[redis_port]
6379
EOF

echo "✓ .screepsrc created with Steam API key"
