// Jenkinsfile for car-website (Static Web Deployment)
// Repository: https://github.com/deekshithar95/car-website

pipeline {
    agent any
    
    environment {
        // ===== CONFIGURATION =====
        EC2_USER = 'ubuntu'
        EC2_IP = '18.212.79.123'  // REPLACE WITH YOUR EC2 IP
        APP_DIR = '/var/www/car-website'
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
                echo '🚀 Starting car-website Deployment Pipeline'
                echo "Repository: ${REPO_URL}"
                echo "Branch: ${BRANCH}"
                echo "Environment: ${params.DEPLOY_ENV}"
                echo '=========================================='
            }
        }
        
        stage('Checkout') {
            steps {
                echo '📦 Checking out code...'
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${BRANCH}"]],
                    userRemoteConfigs: [[url: REPO_URL]],
                    extensions: [[$class: 'CleanBeforeCheckout']]
                ])
                echo '✅ Code checkout complete!'
                
                // Display files
                sh 'echo "Repository files:" && ls -la'
            }
        }
        
        stage('Validate Website') {
            steps {
                echo '🔍 Validating website files...'
                script {
                    // Check if index.html exists
                    if (fileExists('index.html')) {
                        echo '✅ index.html found!'
                    } else {
                        error '❌ index.html not found!'
                    }
                    
                    // Count HTML files
                    def htmlCount = sh(
                        script: 'find . -name "*.html" | wc -l',
                        returnStdout: true
                    ).trim()
                    echo "📄 Found ${htmlCount} HTML files"
                }
            }
        }
        
        stage('Deploy to Production') {
            when {
                expression { params.DEPLOY_ENV == 'production' }
            }
            steps {
                echo '🚀 Deploying to production...'
                script {
                    // Using rsync to copy files
                    sh """
                        # Install rsync if not available
                        which rsync || sudo apt install rsync -y
                        
                        # Create directory on EC2
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} "sudo mkdir -p ${APP_DIR}"
                        
                        # Copy files to EC2
                        rsync -avz --delete -e "ssh -o StrictHostKeyChecking=no" \
                            --exclude='.git' \
                            --exclude='Jenkinsfile' \
                            --exclude='README.md' \
                            ./ ${EC2_USER}@${EC2_IP}:${APP_DIR}/
                    """
                    
                    // Configure web server
                    sh """
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} << 'ENDSSH'
                            set -e
                            
                            # Set proper permissions
                            sudo chown -R www-data:www-data ${APP_DIR}
                            sudo chmod -R 755 ${APP_DIR}
                            
                            # Create Nginx configuration
                            sudo tee /etc/nginx/sites-available/car-website << 'NGINXCONF'
server {
    listen 80;
    server_name _;
    root ${APP_DIR};
    index index.html;
    
    # Enable gzip compression
    gzip on;
    gzip_types text/html text/css text/javascript application/javascript;
    
    # Cache static files
    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location / {
        try_files \$uri \$uri/ =404;
    }
}
NGINXCONF
                            
                            # Enable site
                            sudo ln -sf /etc/nginx/sites-available/car-website /etc/nginx/sites-enabled/
                            
                            # Remove default site if exists
                            sudo rm -f /etc/nginx/sites-enabled/default
                            
                            # Test and reload Nginx
                            sudo nginx -t
                            sudo systemctl reload nginx
                            
                            echo "✅ Nginx configured!"
                            echo "🌐 Website: http://${EC2_IP}"
                        ENDSSH
                    """
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                expression { params.DEPLOY_ENV == 'staging' }
            }
            steps {
                echo '🧪 Deploying to staging...'
                script {
                    def stagingDir = '/var/www/car-website-staging'
                    def stagingPort = '8081'
                    
                    sh """
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} << 'ENDSSH'
                            set -e
                            
                            # Create staging directory
                            sudo mkdir -p ${stagingDir}
                            
                            # Copy files
                            rsync -avz --delete ./ ${stagingDir}/
                            
                            # Set permissions
                            sudo chown -R www-data:www-data ${stagingDir}
                            sudo chmod -R 755 ${stagingDir}
                            
                            # Create Nginx config for staging
                            sudo tee /etc/nginx/sites-available/car-website-staging << 'STAGINGCONF'
server {
    listen ${stagingPort};
    server_name _;
    root ${stagingDir};
    index index.html;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
}
STAGINGCONF
                            
                            # Enable staging site
                            sudo ln -sf /etc/nginx/sites-available/car-website-staging /etc/nginx/sites-enabled/
                            
                            # Test and reload Nginx
                            sudo nginx -t
                            sudo systemctl reload nginx
                            
                            echo "✅ Staging deployment complete!"
                            echo "🌐 Staging: http://${EC2_IP}:${stagingPort}"
                        ENDSSH
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                echo '🩺 Performing health check...'
                script {
                    sleep time: 3, unit: 'SECONDS'
                    
                    def statusCode = sh(
                        script: "curl -s -o /dev/null -w '%{http_code}' http://${EC2_IP}",
                        returnStdout: true
                    ).trim()
                    
                    if (statusCode == '200' || statusCode == '304') {
                        echo "✅ Website is running (Status: ${statusCode})"
                    } else {
                        echo "⚠️  Website returned: ${statusCode}"
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo '''
                ╔══════════════════════════════════════════════╗
                ║      ✅ DEPLOYMENT SUCCESSFUL! ✅           ║
                ╠══════════════════════════════════════════════╣
                ║  Production: http://''' + env.EC2_IP + '''   ║
                ║  Build:     #''' + env.BUILD_NUMBER + '''   ║
                ╚══════════════════════════════════════════════╝
            '''
        }
        failure {
            echo '''
                ╔══════════════════════════════════════════════╗
                ║         ❌ DEPLOYMENT FAILED! ❌            ║
                ╠══════════════════════════════════════════════╣
                ║  Check Jenkins console for details.         ║
                ╚══════════════════════════════════════════════╝
            '''
        }
        cleanup {
            echo '🧹 Cleaning up workspace...'
            sh 'rm -rf * || true'
        }
    }
}
