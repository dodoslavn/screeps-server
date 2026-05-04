# Screeps Private Server with screeps-launcher

Official **screeps-launcher** setup with MongoDB and Redis for high-performance Screeps private server.

## Why screeps-launcher?

- ✅ **Official community solution** - Used by thousands of server operators
- ✅ **Automatic mod management** - Installs screepsmod-mongo, screepsmod-auth, etc.
- ✅ **Uses your Steam files** - Leverages the game you already own
- ✅ **MongoDB + Redis included** - Better performance than default LokiJS
- ✅ **Simple config file** - No manual dependency management
- ✅ **Docker-ready** - Complete stack with one command

## Quick Start

### 1. Get Steam API Key

1. Visit: https://steamcommunity.com/dev/apikey
2. Login with Steam (must own Screeps)
3. Enter domain or IP address
4. Copy your API key

### 2. Configure

Set your Steam API key as an environment variable and create the config:

```bash
export STEAM_KEY="your_actual_steam_api_key_here"
./setup-config.sh
```

Or manually create `.screepsrc` file with your Steam key.

### 3. Deploy

```bash
# Start the server
./deploy.sh start

# Initialize database (first time only)
./deploy.sh init-db
# Then in CLI: system.resetAllData()
```

That's it! Your server is running with MongoDB and Redis.

## Usage

```bash
# Start server
./deploy.sh start

# Stop server
./deploy.sh stop

# Restart server
./deploy.sh restart

# Check status
./deploy.sh status

# View logs
./deploy.sh logs

# Access CLI console
./deploy.sh cli

# Initialize database (first time)
./deploy.sh init-db

# Backup data
./deploy.sh backup

# Reset server (delete all data)
./deploy.sh reset
```

## First-Time Setup

When you start the server for the first time:

1. **Start the server**: `./deploy.sh start`
2. **Initialize database**: `./deploy.sh init-db`
3. **In the CLI**, run: `system.resetAllData()`
4. **Restart**: `./deploy.sh restart`

Now you can connect!

## Connecting

### Via Steam Client

1. Open Screeps in Steam
2. Click "Change Server"
3. Add: `<your-server-ip>:21025`
4. Connect

### Via CLI

```bash
./deploy.sh cli
```

Available CLI commands:
- `system.resetAllData()` - Reset all game data
- `help()` - Show available commands

## Configuration

### config.yml

The `config.yml` file controls everything:

```yaml
env:
  STEAM_KEY: "your_key_here"  # REQUIRED

mods:
  - "screepsmod-mongo"         # MongoDB storage
  - "screepsmod-auth"          # Authentication
  - "screepsmod-admin-utils"   # Admin tools

config:
  port: 21025                  # Game port
  password: ""                 # Optional server password
  runners_cnt: 2               # Parallel runners
  processors_cnt: 2            # Parallel processors
```

### Available Mods

screeps-launcher automatically downloads and installs mods:

- `screepsmod-mongo` - MongoDB + Redis storage (included)
- `screepsmod-auth` - Steam authentication (included)
- `screepsmod-admin-utils` - Admin commands (included)
- `screepsmod-features` - Experimental features
- `screepsmod-tickrate` - Adjust tick rate
- `screepsmod-map-tool` - Map editing tools

Add more mods to the `mods:` section in config.yml.

### Performance Tuning

Edit `config.yml`:

```yaml
config:
  runners_cnt: 4      # More CPU cores = faster ticks
  processors_cnt: 4   # More processors = faster processing
```

## Weekly Reset Schedule

### Manual Reset

```bash
./deploy.sh reset
```

### Automatic (Cron)

```bash
# Edit crontab
crontab -e

# Add this line: Reset every Sunday at 3 AM
0 3 * * 0 cd /home/dodanek/screeps-server && echo "DELETE" | ./deploy.sh reset >> /var/log/screeps-reset.log 2>&1
```

### Jenkins

Create a scheduled Jenkins job:

```groovy
pipeline {
    agent any
    
    triggers {
        cron('0 3 * * 0')  // Every Sunday 3 AM
    }
    
    stages {
        stage('Reset Server') {
            steps {
                sh '''
                    cd /path/to/screeps-server
                    echo "DELETE" | ./deploy.sh reset
                '''
            }
        }
    }
}
```

## Architecture

```
┌──────────────────────────────────────┐
│  screeps-launcher (Port 21025)       │
│                                      │
│  ┌──────────────────────────────┐   │
│  │  Game Engine                 │   │
│  │  + screepsmod-mongo          │   │
│  │  + screepsmod-auth           │   │
│  │  + screepsmod-admin-utils    │   │
│  └────────┬─────────────┬───────┘   │
│           │             │            │
│           ▼             ▼            │
│     ┌─────────┐   ┌─────────┐       │
│     │ MongoDB │   │  Redis  │       │
│     │    8    │   │    7    │       │
│     └─────────┘   └─────────┘       │
│                                      │
└──────────────────────────────────────┘
```

## Troubleshooting

### Check Status

```bash
./deploy.sh status
docker-compose ps
```

### View Logs

```bash
./deploy.sh logs
docker-compose logs mongo
docker-compose logs redis
```

### Server Won't Start

1. Check Steam API key in `config.yml`
2. Verify port 21025 is available:
   ```bash
   netstat -tlnp | grep 21025
   ```
3. Check Docker logs:
   ```bash
   docker-compose logs screeps
   ```

### Database Not Initialized

Run the initialization:
```bash
./deploy.sh init-db
# Then in CLI: system.resetAllData()
./deploy.sh restart
```

### MongoDB Connection Failed

```bash
# Check MongoDB status
docker exec screeps-mongo mongosh --eval "db.adminCommand('ping')"

# View MongoDB logs
docker-compose logs mongo
```

### Redis Connection Failed

```bash
# Check Redis status
docker exec screeps-redis redis-cli ping

# View Redis logs
docker-compose logs redis
```

### Mods Not Loading

The launcher downloads mods automatically on first start. Check logs:
```bash
docker-compose logs screeps | grep -i "mod"
```

## Backups

### Create Backup

```bash
./deploy.sh backup
```

Backups are saved in `./backups/`

### Restore Backup

```bash
# Stop server
./deploy.sh stop

# Extract backup
tar xzf backups/screeps-backup-YYYYMMDD-HHMMSS.tar.gz

# Start server
./deploy.sh start
```

## Data Persistence

All data stored in Docker volumes:
- `screeps-server_screeps-data` - Server files
- `screeps-server_mongo-data` - MongoDB database
- `screeps-server_redis-data` - Redis cache

## Upgrading

```bash
# Pull latest images
docker-compose pull

# Restart with new images
./deploy.sh restart
```

## Security

### Firewall

```bash
# Allow specific IP only
ufw allow from YOUR_IP to any port 21025

# Or use iptables
iptables -A INPUT -p tcp --dport 21025 -s YOUR_IP -j ACCEPT
iptables -A INPUT -p tcp --dport 21025 -j DROP
```

### Server Password

In `config.yml`:
```yaml
config:
  password: "your_secure_password"
```

## Resources

- screeps-launcher: https://github.com/screepers/screeps-launcher
- Official Screeps: https://screeps.com/
- Community Slack: https://chat.screeps.com/
- Steam API Key: https://steamcommunity.com/dev/apikey
- Mods: https://github.com/screepsmods

## Differences from Manual Setup

| Feature | Manual Setup | screeps-launcher |
|---------|--------------|------------------|
| Mod installation | Manual npm install | Automatic from config |
| Configuration | Multiple files | Single config.yml |
| Updates | Manual | Simple docker pull |
| Maintenance | Complex | Single script |
| Community support | Limited | Extensive |

**Recommendation**: Use screeps-launcher unless you have specific customization needs.
