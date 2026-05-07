pipeline {
    agent any

    parameters {
        string(name: 'DEMO_DURATION_MIN', defaultValue: '5', description: 'Demo duration (5–60 minutes)')
    }

    environment {
        ENV      = "dev"
        CLIENT   = "demo"
        SERVICE  = "app"
        BUILD_ID_VAR = "${env.BUILD_NUMBER}"
        TF_DIR   = "terraform"
        HELM_DIR = "helm/demo-app"
        REGION   = "ap-south-1"
    }

    stages {

        stage('Check & Install Tools') {
            steps {
                sh '''
                echo "==== Checking required tools ===="

                if command -v aws >/dev/null 2>&1; then
                  echo "AWS CLI already installed ✅"
                else
                  echo "Installing AWS CLI..."
                  sudo apt update -y
                  
				  if command -v aws >/dev/null 2>&1; then
					echo "AWS CLI already installed ✅"
				  else
					echo "Installing AWS CLI v2..."

					curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
					unzip -o awscliv2.zip
					sudo ./aws/install --update

					rm -rf aws awscliv2.zip
				  fi				  
				  
                fi

                if command -v terraform >/dev/null 2>&1; then
                  echo "Terraform already installed ✅"
                else
                  echo "Installing Terraform..."
                  wget -q https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
                  unzip -o terraform_1.6.6_linux_amd64.zip
                  sudo mv terraform /usr/local/bin/
                  rm terraform_1.6.6_linux_amd64.zip
                fi

                if command -v kubectl >/dev/null 2>&1; then
                  echo "kubectl already installed ✅"
                else
                  echo "Installing kubectl..."
                  curl -LO https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl
                  chmod +x kubectl
                  sudo mv kubectl /usr/local/bin/
                fi

                if command -v helm >/dev/null 2>&1; then
                  echo "Helm already installed ✅"
                else
                  echo "Installing Helm..."
                  curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
                fi

                echo "==== Tool Versions ===="
                aws --version
                terraform version
                kubectl version --client
                helm version
                '''
            }
        }

        stage('Terraform Apply') {
            steps {
                sh '''
                cd terraform

                terraform init

                terraform apply -auto-approve \
                -var="env=dev" \
                -var="client=demo" \
                -var="service=app" \
                -var="build_id=${BUILD_NUMBER}"
                '''
            }
        }

        stage('Configure kubectl') {
            steps {
                sh '''
                CLUSTER_NAME="dev-eks-poc-demo-app-b${BUILD_NUMBER}"

                aws eks update-kubeconfig \
                  --region ap-south-1 \
                  --name $CLUSTER_NAME

                kubectl get nodes
                '''
            }
        }

        stage('Helm Deploy') {
            steps {
                sh '''
                helm upgrade --install demo-app helm/demo-app \
                -f helm/demo-app/values-dev.yaml
                '''
            }
        }

        stage('Demo Window') {
            steps {
                script {
                    int duration = params.DEMO_DURATION_MIN.toInteger()

                    if (duration < 5 || duration > 60) {
                        error("Demo duration must be between 5 and 60 minutes")
                    }

                    echo "Application live for ${duration} minutes"
                    sleep(time: duration, unit: 'MINUTES')
                }
            }
        }

        stage('Post-Run Validation') {
            steps {
                sh '''
                echo "==== Validation ===="
                kubectl get pods -A
                kubectl get svc
                helm list
                '''
            }
        }
    }

    post {
        always {
            echo "==== Destroying Infrastructure ===="

            sh '''
            cd terraform

            terraform destroy -auto-approve \
              -var="env=dev" \
              -var="client=demo" \
              -var="service=app" \
              -var="build_id=${BUILD_NUMBER}"
            '''
        }
    }
}
