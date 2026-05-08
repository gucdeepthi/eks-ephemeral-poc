pipeline {
    agent any

    parameters {
        string(name: 'DEMO_DURATION_MIN', defaultValue: '5', description: 'Demo duration (5–60 minutes)')
    }

    environment {
        ENV = "dev"
        CLIENT = "demo"
        SERVICE = "app"
        REGION = "ap-south-1"
    }

    stages {

        // ===============================
        // ✅ SETUP TOOLS
        // ===============================
        stage('Setup Tools') {
            steps {
                sh '''
                set -e
                sudo apt-get update -y
                sudo apt-get install -y unzip curl git wget

                # AWS CLI
                if ! command -v aws >/dev/null 2>&1; then
                  curl -s https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
                  unzip -o awscliv2.zip
                  sudo ./aws/install --update
                  rm -rf aws awscliv2.zip
                fi

                # Terraform
                TMP_DIR=$(mktemp -d)
                cd $TMP_DIR
                wget -q https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
                unzip terraform_1.6.6_linux_amd64.zip
                sudo mv terraform /usr/local/bin/
                sudo chmod +x /usr/local/bin/terraform
                cd -
                rm -rf $TMP_DIR

                terraform version

                # kubectl
                if ! command -v kubectl >/dev/null 2>&1; then
                  curl -LO "https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl"
                  chmod +x kubectl
                  sudo mv kubectl /usr/local/bin/
                fi

                # helm
                if ! command -v helm >/dev/null 2>&1; then
                  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
                fi
                '''
            }
        }

        // ===============================
        // ✅ TERRAFORM APPLY
        // ===============================
        stage('Terraform Apply') {
            steps {
                sh '''
                set -e
                cd terraform

                rm -rf .terraform
                rm -f .terraform.lock.hcl

                terraform init
                terraform apply -auto-approve \
                  -var="env=${ENV}" \
                  -var="client=${CLIENT}" \
                  -var="service=${SERVICE}" \
                  -var="build_id=${BUILD_NUMBER}"
                '''
            }
        }

        // ✅ NEW STAGE (CRITICAL FIX)
        stage('Wait for EKS Ready') {
            steps {
                sh '''
                echo "Waiting for EKS cluster to stabilize..."

                sleep 60

                echo "Updating kubeconfig..."
                CLUSTER_NAME="dev-eks-poc-${CLIENT}-${SERVICE}-b${BUILD_NUMBER}"

                aws eks update-kubeconfig \
                  --region ${REGION} \
                  --name $CLUSTER_NAME

                echo "Waiting for nodes..."

                for i in {1..20}; do
                  READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready")

                  if [ "$READY_NODES" -gt 0 ]; then
                    echo "✅ Nodes are ready"
                    kubectl get nodes
                    exit 0
                  fi

                  echo "Waiting... attempt $i"
                  sleep 15
                done

                echo "❌ Nodes not ready"
                kubectl get nodes || true
                exit 1
                '''
            }
        }

        // ===============================
        // ✅ HELM DEPLOY
        // ===============================
        stage('Helm Deploy') {
            steps {
                sh '''
                set -e

                helm upgrade --install demo-app helm/demo-app \
                  -f helm/demo-app/values-dev.yaml

                kubectl get pods
                '''
            }
        }

        // ===============================
        // ✅ DEMO WINDOW
        // ===============================
        stage('Demo Window') {
            steps {
                script {
                    int duration = params.DEMO_DURATION_MIN.toInteger()

                    if (duration < 5 || duration > 60) {
                        error("Demo duration must be between 5 and 60 minutes")
                    }

                    echo "Application running for ${duration} minutes ✅"
                    sleep time: duration, unit: 'MINUTES'
                }
            }
        }

        // ===============================
        // ✅ VALIDATION
        // ===============================
        stage('Validation') {
            steps {
                sh '''
                kubectl get pods -A
                kubectl get svc
                helm list
                '''
            }
        }
    }

    // ===============================
    // ✅ CLEANUP (SAFE DESTROY)
    // ===============================
    post {
        always {
            echo "==== Destroying Infrastructure ===="

            sh '''
            set +e

            if command -v terraform >/dev/null 2>&1; then
              cd terraform

              terraform destroy -auto-approve \
                -var="env=${ENV}" \
                -var="client=${CLIENT}" \
                -var="service=${SERVICE}" \
                -var="build_id=${BUILD_NUMBER}"

              EXIT_CODE=$?

              echo "Terraform exit code: $EXIT_CODE"

              exit 0
            else
              echo "Terraform not found, skipping destroy"
              exit 0
            fi
            '''
        }
    }
}