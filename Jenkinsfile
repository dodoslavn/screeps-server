pipeline {
    agent any

    parameters {
        choice(
            name: 'ACTION',
            choices: ['deploy', 'restart', 'stop', 'reset', 'init-db', 'status', 'backup'],
            description: 'Action to perform on the Screeps server'
        )
        string(
            name: 'STEAM_API_KEY',
            defaultValue: '',
            description: 'Steam API Key (optional, uses existing config if empty)'
        )
    }

    environment {
        DEPLOY_DIR = '/home/dodanek/screeps-server'
    }

    stages {
        stage('Validate') {
            steps {
                script {
                    echo "==================================="
                    echo "Screeps Server - ${params.ACTION}"
                    echo "==================================="
                    echo "Deploy directory: ${DEPLOY_DIR}"
                }
            }
        }

        stage('Update Configuration') {
            when {
                expression { params.STEAM_API_KEY != '' }
            }
            steps {
                script {
                    echo "Updating Steam API key in config..."
                    sh """
                        cd ${DEPLOY_DIR}
                        sed -i 's/STEAM_KEY: ".*"/STEAM_KEY: "${params.STEAM_API_KEY}"/' config.yml
                        echo "✓ Configuration updated"
                    """
                }
            }
        }

        stage('Deploy') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                script {
                    sh """
                        cd ${DEPLOY_DIR}
                        ./deploy.sh start
                    """
                }
            }
        }

        stage('Restart') {
            when {
                expression { params.ACTION == 'restart' }
            }
            steps {
                script {
                    sh """
                        cd ${DEPLOY_DIR}
                        ./deploy.sh restart
                    """
                }
            }
        }

        stage('Stop') {
            when {
                expression { params.ACTION == 'stop' }
            }
            steps {
                script {
                    sh """
                        cd ${DEPLOY_DIR}
                        ./deploy.sh stop
                    """
                }
            }
        }

        stage('Reset') {
            when {
                expression { params.ACTION == 'reset' }
            }
            steps {
                script {
                    echo "⚠️  RESETTING SERVER - ALL DATA WILL BE DELETED ⚠️"
                    sh """
                        cd ${DEPLOY_DIR}
                        echo "DELETE" | ./deploy.sh reset
                    """
                }
            }
        }

        stage('Backup') {
            when {
                expression { params.ACTION == 'backup' }
            }
            steps {
                script {
                    sh """
                        cd ${DEPLOY_DIR}
                        ./deploy.sh backup
                    """
                }
            }
        }

        stage('Initialize Database') {
            when {
                expression { params.ACTION == 'init-db' }
            }
            steps {
                script {
                    sh """
                        cd ${DEPLOY_DIR}
                        ./deploy.sh init-db
                    """
                }
            }
        }

        stage('Status') {
            when {
                expression { params.ACTION == 'status' }
            }
            steps {
                script {
                    sh """
                        cd ${DEPLOY_DIR}
                        ./deploy.sh status
                    """
                }
            }
        }

        stage('Verify') {
            when {
                expression { params.ACTION in ['deploy', 'restart'] }
            }
            steps {
                script {
                    echo "Waiting for services to stabilize..."
                    sleep(10)

                    sh """
                        cd ${DEPLOY_DIR}
                        docker compose ps

                        if docker ps --format '{{.Names}}' | grep -q 'screeps-server'; then
                            echo "✓ Screeps server is running"
                        else
                            echo "✗ Screeps server failed to start"
                            exit 1
                        fi

                        if docker ps --format '{{.Names}}' | grep -q 'screeps-mongo'; then
                            echo "✓ MongoDB is running"
                        else
                            echo "✗ MongoDB failed to start"
                            exit 1
                        fi

                        if docker ps --format '{{.Names}}' | grep -q 'screeps-redis'; then
                            echo "✓ Redis is running"
                        else
                            echo "✗ Redis failed to start"
                            exit 1
                        fi
                    """
                }
            }
        }

        stage('Show Connection Info') {
            when {
                expression { params.ACTION in ['deploy', 'restart'] }
            }
            steps {
                script {
                    echo """
=================================
   Screeps Server Ready!
=================================

Connection Information:
  Port: 21025

Connect via Steam:
  1. Open Screeps
  2. Change Server
  3. Add: <server-ip>:21025

First-time setup:
  Run this Jenkins job again with ACTION=init-db
  Or manually: cd ${DEPLOY_DIR} && ./deploy.sh init-db

View logs:
  cd ${DEPLOY_DIR}
  ./deploy.sh logs

=================================
"""
                }
            }
        }
    }

    post {
        success {
            echo "✓ Action '${params.ACTION}' completed successfully"
        }
        failure {
            echo "✗ Action '${params.ACTION}' failed"
            sh """
                cd ${DEPLOY_DIR}
                echo ""
                echo "Recent logs:"
                docker-compose logs --tail=50 screeps || true
            """
        }
        always {
            script {
                sh """
                    cd ${DEPLOY_DIR}
                    echo ""
                    echo "Current status:"
                    docker-compose ps || true
                """
            }
        }
    }
}
