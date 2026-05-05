# Resource Tuning Guide

This guide explains how to tune Screeps server resources for your hardware.

## Default Resource Limits

The default `docker-compose.yml` includes conservative resource limits:

| Service | CPU Limit | Memory Limit | Reserved CPU | Reserved RAM |
|---------|-----------|--------------|--------------|--------------|
| Screeps | 30 CPUs   | 32 GB        | 10 CPUs      | 8 GB         |
| MongoDB | 8 CPUs    | 16 GB        | 2 CPUs       | 2 GB         |
| Redis   | 4 CPUs    | 4 GB         | 1 CPU        | 512 MB       |
| **Total** | **42 CPUs** | **52 GB** | **13 CPUs** | **10.5 GB** |

These defaults work well for servers with **50+ CPUs and 64+ GB RAM**.

## Overriding Resource Limits

Create a `docker-compose.override.yml` file to customize limits without modifying the base config:

```bash
cp docker-compose.override.yml.example docker-compose.override.yml
nano docker-compose.override.yml
```

Docker Compose automatically merges both files when you run commands.

## Tuning for Different Server Sizes

### Small Server (4 CPUs, 8 GB RAM)

**docker-compose.override.yml:**
```yaml
services:
  screeps:
    deploy:
      resources:
        limits:
          cpus: '3'
          memory: 4G
        reservations:
          cpus: '2'
          memory: 2G

  mongo:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 2G

  redis:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G
```

**Also update .screepsrc:**
```ini
[runners_cnt]
2
[processors_cnt]
2
```

### Medium Server (16 CPUs, 32 GB RAM)

**docker-compose.override.yml:**
```yaml
services:
  screeps:
    deploy:
      resources:
        limits:
          cpus: '12'
          memory: 20G
        reservations:
          cpus: '8'
          memory: 12G

  mongo:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G

  redis:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
```

**Also update .screepsrc:**
```ini
[runners_cnt]
6
[processors_cnt]
6
```

### Large Server (50+ CPUs, 128 GB RAM)

**docker-compose.override.yml:**
```yaml
services:
  screeps:
    deploy:
      resources:
        limits:
          cpus: '40'
          memory: 64G
        reservations:
          cpus: '20'
          memory: 24G

  mongo:
    deploy:
      resources:
        limits:
          cpus: '12'
          memory: 32G
        reservations:
          cpus: '4'
          memory: 8G

  redis:
    deploy:
      resources:
        limits:
          cpus: '6'
          memory: 8G
        reservations:
          cpus: '2'
          memory: 2G
```

**Also update .screepsrc:**
```ini
[runners_cnt]
15
[processors_cnt]
15
```

## Monitoring Resource Usage

Check actual resource consumption:

```bash
# Real-time monitoring
docker stats screeps-server screeps-mongo screeps-redis

# Check container limits
docker inspect screeps-server | grep -A 10 "NanoCpus\|Memory"
```

## Tuning Guidelines

### runners_cnt and processors_cnt

These control parallelization in Screeps:

| Total CPUs Available | Recommended runners_cnt | Recommended processors_cnt |
|---------------------|------------------------|---------------------------|
| 2-4                 | 2                      | 2                         |
| 4-8                 | 3-4                    | 3-4                       |
| 8-16                | 6-8                    | 6-8                       |
| 16-32               | 10-12                  | 10-12                     |
| 32-50+              | 15-20                  | 15-20                     |

**Rule of thumb:**
- Set `runners_cnt + processors_cnt ≤ CPU limit - 5`
- Leave headroom for MongoDB, Redis, and system overhead
- Each runner/processor uses ~200-500 MB RAM

### MongoDB

- **CPU**: Scales with data size and query complexity
- **RAM**: Benefits from more memory for caching
- **For large worlds**: Increase to 16+ GB RAM

### Redis

- **CPU**: Usually low (1-4 CPUs sufficient)
- **RAM**: Depends on cache size (2-8 GB typical)
- **For high traffic**: Increase RAM, not CPU

## Memory Calculation

Estimate total memory needed:

```
Screeps Memory = (runners_cnt + processors_cnt) × 300 MB + 2 GB base
MongoDB Memory = 2-16 GB (depends on data size)
Redis Memory = 0.5-4 GB (depends on cache size)
System Overhead = 2-4 GB

Total = Screeps + MongoDB + Redis + System
```

**Example for 15/15 runners/processors:**
- Screeps: 15+15 × 300 MB + 2 GB = ~11 GB
- MongoDB: 8 GB
- Redis: 2 GB
- System: 3 GB
- **Total: ~24 GB**

## Performance Testing

After changing settings:

1. **Restart services:**
   ```bash
   docker compose restart
   ```

2. **Monitor for 10 minutes:**
   ```bash
   docker stats
   ```

3. **Check tick times** in game
   - Good: < 3 seconds per tick
   - Acceptable: 3-5 seconds per tick
   - Slow: > 5 seconds per tick

4. **Look for signs of overload:**
   - CPU at 100% constantly = need more CPUs or reduce runners/processors
   - Memory growing continuously = potential memory leak or need more RAM
   - High iowait = MongoDB needs faster disk

## Applying Changes

After modifying `docker-compose.override.yml` or `.screepsrc`:

```bash
# Rebuild and restart
./deploy.sh restart

# Or manually
docker compose up -d --force-recreate
```

Changes to `.screepsrc` require a container restart.
Changes to `docker-compose.override.yml` require `docker compose up -d`.

## Troubleshooting

### Container OOM Killed

If containers are being killed:
- Increase memory limits in override file
- Reduce runners_cnt/processors_cnt
- Check for memory leaks with `docker stats`

### Poor Performance

If game is slow:
- Increase runners_cnt/processors_cnt
- Give Screeps more CPU in override file
- Check MongoDB performance
- Ensure SSD storage for MongoDB

### High CPU Usage

If CPU usage is constantly maxed:
- Reduce runners_cnt/processors_cnt
- Give more CPU limit
- Check for inefficient player code in game
