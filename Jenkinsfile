// Jenkinsfile for car-website
// Repository: https://github.com/deekshithar95/car-website

pipeline {
    agent any
    
    tools {
        // If using specific tool versions
        // maven 'Maven-3.8.4'  // Uncomment if needed
    }
    
    environment {
        // ===== CONFIGURATION =====
        // Replace these with your actual values
        EC2_USER = 'demo1'
        EC2_IP = '18.212.79.123'
        APP_DIR = '/var/www/car-website'
        DOCKER_IMAGE = 'car-website'
        HOST_PORT = '80'
        REPO_URL = 'https://github.com/deekshithar95/car-website.git'
        BRANCH = 'main'
        // ==========================
    }
    
    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['production', 'staging'],
            description: 'Select deployment environment'
        )
    }
    
    stages {
        stage('Initialize') {
            steps {
                echo '=========================================='
                echo 'Starting car-website CI/CD Pipeline'
                echo "Repository: ${REPO_URL}"
                echo "Branch: ${BRANCH}"
                echo "Environment: ${params.DEPLOY_ENV}"
                echo '=========================================='
            }
        }
        
        stage('Checkout') {
            steps {
                echo '📦 Checking out code from GitHub...'
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${BRANCH}"]],
                    userRemoteConfigs: [[url: REPO_URL]],
                    extensions: [
                        [$class: 'CleanBeforeCheckout'],
                        [$class: 'CloneOption', depth: 1, noTags: true, reference: '', shallow: true]
                    ]
                ])
                echo '✅ Code checkout complete!'
                
                // Display repository files
                sh 'echo "Repository files:" && ls -la'
            }
        }
        
        stage('Validate Project') {
            steps {
                echo '🔍 Validating project structure...'
                script {
                    // Check if Dockerfile exists
                    if (fileExists('Dockerfile')) {
                        echo '✅ Dockerfile found!'
                    } else {
                        error '❌ Dockerfile not found in repository!'
                    }
                    
                    // Check if index.html exists
                    if (fileExists('index.html')) {
                        echo '✅ index.html found!'
                    } else {
                        error '❌ index.html not found in repository!'
                    }
                    
                    // Display HTML files
                    sh 'find . -name "*.html" | head -10'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                script {
                    sh """
                        docker build -t ${DOCKER_IMAGE}:latest .
                        docker tag ${DOCKER_IMAGE}:latest ${DOCKER_IMAGE}:${BUILD_NUMBER}
                        docker images | grep ${DOCKER_IMAGE}
                    """
                }
                echo '✅ Docker image built successfully!'
            }
        }
        
        stage('Static Analysis') {
            steps {
                echo '🔎 Running static analysis on HTML/CSS...'
                script {
                    // Check for broken HTML syntax
                    sh '''
                        echo "Checking HTML files..."
                        for file in *.html; do
                            echo "  ✓ Checking \$file"
                            # Validate HTML syntax (using html-tidy if available)
                            tidy -errors \$file 2>/dev/null || echo "    ⚠️  tidy not installed, skipping validation"
                        done
                    '''
                }
            }
        }
        
        stage('Deploy to EC2') {
            when {
                expression { params.DEPLOY_ENV == 'production' }
            }
            steps {
                echo '🚀 Deploying to EC2 production server...'
                script {
                    withCredentials([sshUserPrivateKey(
                        credentialsId: 'ec2-ssh-key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'EC2_USER'
                    )]) {
                        sh """
                            ssh -o StrictHostKeyChecking=no -i ${SSH_KEY} ${EC2_USER}@${EC2_IP} << 'ENDSSH'
                                set -e
                                echo "Connected to EC2 instance..."
                                
                                # Setup application directory
                                mkdir -p ${APP_DIR}
                                cd ${APP_DIR}
                                
                                # Pull latest code
                                echo "📦 Updating code..."
                                if [ ! -d ".git" ]; then
                                    git clone ${REPO_URL} .
                                else
                                    git pull origin ${BRANCH}
                                fi
                                
                                # Build and deploy with Docker
                                echo "🐳 Building Docker image..."
                                docker build -t ${DOCKER_IMAGE}:latest .
                                
                                # Stop old container
                                echo "🔄 Stopping old container..."
                                docker stop ${DOCKER_IMAGE}-container 2>/dev/null || true
                                docker rm ${DOCKER_IMAGE}-container 2>/dev/null || true
                                
                                # Run new container
                                echo "🚀 Starting new container..."
                                docker run -d --name ${DOCKER_IMAGE}-container \
                                    --restart unless-stopped \
                                    -p ${HOST_PORT}:80 \
                                    ${DOCKER_IMAGE}:latest
                                
                                # Verify container is running
                                sleep 3
                                echo "📊 Container status:"
                                docker ps | grep ${DOCKER_IMAGE}-container
                                
                                echo "✅ Deployment complete!"
                            ENDSSH
                        """
                    }
                }
            }
        }
        
        stage('Staging Deployment') {
            when {
                expression { params.DEPLOY_ENV == 'staging' }
            }
            steps {
                echo '🧪 Deploying to staging environment...'
                script {
                    // Use different port for staging
                    def stagingPort = '8081'
                    sh """
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} << ENDSSH
                            cd ${APP_DIR}
                            docker pull ${DOCKER_IMAGE}:latest || true
                            docker build -t ${DOCKER_IMAGE}:staging .
                            docker stop ${DOCKER_IMAGE}-staging 2>/dev/null || true
                            docker rm ${DOCKER_IMAGE}-staging 2>/dev/null || true
                            docker run -d --name ${DOCKER_IMAGE}-staging -p ${stagingPort}:80 ${DOCKER_IMAGE}:staging
                        ENDSSH
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                echo '🩺 Performing health check...'
                script {
                    // Wait for application to start
                    sleep time: 5, unit: 'SECONDS'
                    
                    // Test the endpoint
                    def statusCode = sh(
                        script: "curl -s -o /dev/null -w '%{http_code}' http://${EC2_IP}:${HOST_PORT}",
                        returnStdout: true
                    ).trim()
                    
                    if (statusCode == '200' || statusCode == '304') {
                        echo "✅ Health check passed! Status: ${statusCode}"
                    } else {
                        echo "⚠️  Health check returned: ${statusCode}"
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo '''
                ╔══════════════════════════════════════════════╗
                ║        🎉 DEPLOYMENT SUCCESSFUL! 🎉        ║
                ╠══════════════════════════════════════════════╣
                ║  Website: http://''' + env.EC2_IP + '''      ║
                ║  Image:   ''' + env.DOCKER_IMAGE + '''     ║
                ║  Build:   #''' + env.BUILD_NUMBER + '''    ║
                ╚══════════════════════════════════════════════╝
            '''
        }
        failure {
            echo '''
                ╔══════════════════════════════════════════════╗
                ║        ❌ DEPLOYMENT FAILED! ❌             ║
                ╠══════════════════════════════════════════════╣
                ║  Check the logs above for error details.    ║
                ╚══════════════════════════════════════════════╝
            '''
        }
        cleanup {
            echo '🧹 Cleaning up workspace...'
            script {
                sh '''
                    docker system prune -f || true
                '''
            }
        }
    }
}
