pipeline {
    agent any

    parameters {
        string(name: 'DEMO_DURATION_MIN', defaultValue: '5', description: 'Demo duration (5–60 minutes)')
    }

    environment {
        ENV      = "dev"
        CLIENT   = "demo"
        SERVICE  = "app"
        REGION   = "ap-south-1"
    }

    stages {

        // ===============================
        // ✅ INSTALL ALL REQUIRED TOOLS
        // ===============================
        stage('Setup Tools') {
            steps {
                sh '''
                set -e

                echo "==== Installing base packages ===="
                sudo apt-get update -y
                sudo apt-get install -y unzip curl git wget

                # -------------------------
                # ✅ AWS CLI
                # -------------------------
                echo "==== Checking AWS CLI ===="
                if command -v aws >/dev/null 2>&1; then
                  echo "AWS CLI already exists ✅"
                else
                  echo "Installing AWS CLI v2..."
                  curl -s https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
                  unzip -o awscliv2.zip
                  sudo ./aws/install --update
                  rm -rf aws awscliv2.zip
                fi

                # -------------------------
                # ✅ TERRAFORM (FIXED)
                # -------------------------
                echo "==== Installing Terraform ===="
                wget -q https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
                unzip -o terraform_1.6.6_linux_amd64.zip

                # ✅ IMPORTANT FIX (your failure reason)
                sudo rm -rf /usr/local/bin/terraform || true

                sudo mv -f terraform /usr/local/bin/
                sudo chmod +x /usr/local/bin/terraform

                rm -f terraform_1.6.6_linux_amd64.zip

                terraform version || exit 1

                # -------------------------
                # ✅ KUBECTL
                # -------------------------
                echo "==== Installing kubectl ===="
                if ! command -v kubectl >/dev/null 2>&1; then
                  curl -LO "https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl"
                  chmod +x kubectl
                  sudo mv kubectl /usr/local/bin/
                fi

                kubectl version --client

                # -------------------------
                # ✅ HELM
                # -------------------------
                echo "==== Installing Helm ===="
                if ! command -v helm >/dev/null 2>&1; then
                  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
                fi

                helm version

                echo "==== ✅ All tools ready ===="
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

                terraform init

                terraform apply -auto-approve \
                  -var="env=dev" \
                  -var="client=demo" \
                  -var="service=app" \
                  -var="build_id=${BUILD_NUMBER}"
                '''
            }
        }

        // ===============================
        // ✅ CONFIGURE KUBECTL
        // ===============================
        stage('Configure kubectl') {
            steps {
                sh '''
                set -e

                CLUSTER_NAME="dev-eks-poc-demo-app-b${BUILD_NUMBER}"

                aws eks update-kubeconfig \
                  --region ap-south-1 \
                  --name $CLUSTER_NAME

                kubectl get nodes
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

                    echo "App running for ${duration} minutes ✅"
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
                echo "==== Post Validation ===="
                kubectl get all
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
            set +e   # ✅ IMPORTANT: don't fail pipeline if destroy fails

            if command -v terraform >/dev/null 2>&1; then
              cd terraform

              terraform destroy -auto-approve \
                -var="env=dev" \
                -var="client=demo" \
                -var="service=app" \
                -var="build_id=${BUILD_NUMBER}"
            else
              echo "Terraform not found, skipping destroy"
            fi
            '''
        }
    }
}