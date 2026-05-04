# Jenkins Setup for Screeps Server

This guide explains how to set up Jenkins to manage your Screeps server.

## Prerequisites

1. Jenkins installed and running
2. Jenkins has access to the server where Screeps will run
3. Steam API key from https://steamcommunity.com/dev/apikey

## Setup Steps

### Option 1: Direct Jenkins Job (Server on Same Machine)

If Jenkins runs on the same machine as the Screeps server:

#### 1. Create Jenkins Pipeline Job

1. Jenkins → New Item
2. Name: **screeps-server**
3. Type: **Pipeline**
4. Click OK

#### 2. Configure Pipeline

In the Pipeline section:

**Definition**: Pipeline script from SCM

**SCM**: Git (or None if using direct script)

**If using Git**:
- Repository URL: Your git repository
- Script Path: `Jenkinsfile`

**If using direct script**:
- Copy the entire content of `Jenkinsfile` into the Pipeline script box

#### 3. Configure Build Parameters

The Jenkinsfile already defines parameters:
- **ACTION**: Choose what to do (deploy/restart/stop/reset/status/backup)
- **STEAM_API_KEY**: Optional, only needed for first deploy

#### 4. Save and Build

1. Click "Build with Parameters"
2. Choose ACTION: `deploy`
3. Enter your Steam API key (first time only)
4. Click Build

### Option 2: Remote Server via SSH

If Jenkins and Screeps run on different machines:

#### 1. Install SSH Agent Plugin

1. Manage Jenkins → Manage Plugins
2. Available → Search "SSH Agent"
3. Install and restart

#### 2. Add SSH Credentials

1. Manage Jenkins → Manage Credentials
2. Add Credentials → SSH Username with private key
3. ID: `screeps-server-ssh`
4. Username: Your server username
5. Private Key: Paste your SSH private key
6. Save

#### 3. Create Pipeline with SSH

Use this modified Jenkinsfile:

```groovy
pipeline {
    agent any

    parameters {
        choice(
            name: 'ACTION',
            choices: ['deploy', 'restart', 'stop', 'reset', 'status', 'backup'],
            description: 'Action to perform'
        )
        string(
            name: 'STEAM_API_KEY',
            defaultValue: '',
            description: 'Steam API Key (optional)'
        )
    }

    environment {
        REMOTE_HOST = 'your-server-ip-or-hostname'
        REMOTE_USER = 'dodanek'
        DEPLOY_DIR = '/home/dodanek/screeps-server'
    }

    stages {
        stage('Deploy via SSH') {
            steps {
                sshagent(['screeps-server-ssh']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} '
                            cd ${DEPLOY_DIR}
                            
                            if [ "${params.STEAM_API_KEY}" != "" ]; then
                                sed -i "s/STEAM_KEY: \\".*\\"/STEAM_KEY: \\"${params.STEAM_API_KEY}\\"/" config.yml
                            fi
                            
                            if [ "${params.ACTION}" == "reset" ]; then
                                echo "DELETE" | ./deploy.sh reset
                            else
                                ./deploy.sh ${params.ACTION}
                            fi
                        '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✓ ${params.ACTION} completed successfully"
        }
        failure {
            echo "✗ ${params.ACTION} failed"
        }
    }
}
```

### Option 3: Weekly Reset Schedule

To automatically reset the server every week:

#### 1. Create Scheduled Job

1. Create new Pipeline job: **screeps-weekly-reset**
2. Configure → Build Triggers
3. Check "Build periodically"
4. Schedule: `0 3 * * 0` (Every Sunday at 3 AM)
5. Pipeline script:

```groovy
pipeline {
    agent any

    environment {
        DEPLOY_DIR = '/home/dodanek/screeps-server'
    }

    stages {
        stage('Weekly Reset') {
            steps {
                script {
                    echo "Performing weekly server reset..."
                    sh """
                        cd ${DEPLOY_DIR}
                        echo "DELETE" | ./deploy.sh reset
                    """
                }
            }
        }

        stage('Verify') {
            steps {
                script {
                    sleep(15)
                    sh """
                        cd ${DEPLOY_DIR}
                        ./deploy.sh status
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✓ Weekly reset completed successfully"
        }
        failure {
            echo "✗ Weekly reset failed - manual intervention required"
        }
    }
}
```

## Using the Jenkins Job

### Deploy Server (First Time)

1. Go to your Jenkins job
2. Click "Build with Parameters"
3. ACTION: `deploy`
4. STEAM_API_KEY: Your actual Steam key
5. Click Build

**After first deploy**, initialize the database:
```bash
ssh your-server
cd /home/dodanek/screeps-server
./deploy.sh init-db
# In CLI: system.resetAllData()
./deploy.sh restart
```

### Restart Server

1. Build with Parameters
2. ACTION: `restart`
3. STEAM_API_KEY: Leave empty
4. Click Build

### Reset Server (Weekly)

1. Build with Parameters
2. ACTION: `reset`
3. Click Build

### Check Status

1. Build with Parameters
2. ACTION: `status`
3. Click Build

### Backup Data

1. Build with Parameters
2. ACTION: `backup`
3. Click Build

## Troubleshooting

### Permission Denied

Jenkins user needs Docker permissions:
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### SSH Connection Failed

Test SSH manually:
```bash
ssh -i /path/to/key user@server
```

Add to Jenkins SSH credentials if working.

### Docker Command Not Found

Jenkins needs Docker in PATH:
```bash
# Add to Jenkins environment
Manage Jenkins → Configure System → Global properties
Check "Environment variables"
Add: PATH = /usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin
```

### Config Not Updated

Check file permissions:
```bash
ls -la /home/dodanek/screeps-server/config.yml
# Should be writable by Jenkins user
```

## Security Notes

1. **Never commit Steam API key to git**
   - Use Jenkins credentials or parameters
   - Keep config.yml in .gitignore

2. **Restrict Jenkins job permissions**
   - Use role-based authorization
   - Limit who can trigger resets

3. **Use SSH keys, not passwords**
   - Generate SSH key for Jenkins
   - Add public key to server's authorized_keys

4. **Firewall rules**
   - Only allow Jenkins IP to SSH into server
   - Restrict port 21025 access

## Example: Complete Setup from Scratch

```bash
# On your server
cd /home/dodanek
git clone <your-repo> screeps-server
cd screeps-server

# Edit config
nano config.yml
# Add your Steam API key

# Test locally first
./deploy.sh start
./deploy.sh init-db
./deploy.sh status

# On Jenkins
# 1. Create new Pipeline job
# 2. Use Jenkinsfile from this repo
# 3. Build with ACTION=deploy
# 4. Done!
```

## Monitoring

Add these stages to Jenkinsfile for monitoring:

```groovy
stage('Health Check') {
    steps {
        script {
            sh """
                cd ${DEPLOY_DIR}
                
                # Check container health
                docker ps --filter health=healthy | grep screeps-mongo || exit 1
                docker ps --filter health=healthy | grep screeps-redis || exit 1
                
                # Check port is listening
                nc -zv localhost 21025 || exit 1
                
                echo "✓ All health checks passed"
            """
        }
    }
}
```
