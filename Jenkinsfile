pipeline {

    agent any

    stages {

        stage('Clone Repository') {
            steps {
                checkout scm
            }
        }

        stage('Deploy Website') {
            steps {
                sh '''
                echo "Cleaning old website..."
                sudo rm -rf /var/www/html/*

                echo "Copying website files..."
                sudo cp -r css images js *.html /var/www/html/

                echo "Restarting Nginx..."
                sudo systemctl restart nginx

                echo "Deployment Successful"
                '''
            }
        }

    }

}
