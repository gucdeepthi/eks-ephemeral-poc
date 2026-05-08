pipeline {
    agent any

    parameters {
        string(name: 'DEMO_DURATION_MIN', defaultValue: '5', description: '5–60 minutes')
    }

    environment {
        ENV = "dev"
        CLIENT = "demo"
        SERVICE = "app"
        REGION = "ap-south-1"
    }

    stages {

        stage('Start') {
            steps {
                echo "==================== ✅ PIPELINE STARTED ===================="
            }
        }

        // ============================================================
        // ✅ SETUP TOOLS
        // ============================================================
        stage('Setup Tools') {
            steps {
                echo "==================== ✅ SETUP TOOLS START ===================="

                sh '''
                set -e
                sudo apt-get update -y
                sudo apt-get install -y unzip curl git wget

                if ! command -v aws >/dev/null 2>&1; then
                  curl -s https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
                  unzip -o awscliv2.zip
                  sudo ./aws/install --update
                fi

                aws --version
                terraform version || true
                '''

                echo "==================== ✅ SETUP TOOLS SUCCESS =================="
            }
        }

        // ============================================================
        // ✅ ✅ NEW STAGE: PRE-CLEAN (DESTROY OLD INFRA)
        // ============================================================
        stage('Terraform Destroy (Pre-Cleanup)') {
            steps {
                echo "==================== 🔄 PRE-CLEAN START ======================"

                sh '''
                set +e
                cd terraform

                terraform init

                echo "***** Destroy any existing infra *****"
                terraform destroy -auto-approve \
                  -var="env=${ENV}" \
                  -var="client=${CLIENT}" \
                  -var="service=${SERVICE}" \
                  -var="build_id=${BUILD_NUMBER}"

                echo "***** Pre-clean completed (ignore errors if nothing exists) *****"
                exit 0
                '''

                echo "==================== ✅ PRE-CLEAN COMPLETE ==================="
            }
        }

        // ============================================================
        // ✅ TERRAFORM APPLY
        // ============================================================
        stage('Terraform Apply') {
            steps {
                echo "==================== ✅ TERRAFORM APPLY START ================"

                script {
                    def tfStatus = sh(
                        script: '''
                        set +e
                        cd terraform

                        terraform init

                        terraform apply -auto-approve \
                          -var="env=${ENV}" \
                          -var="client=${CLIENT}" \
                          -var="service=${SERVICE}" \
                          -var="build_id=${BUILD_NUMBER}"

                        EXIT_CODE=$?
                        echo "***** Terraform Exit Code: $EXIT_CODE *****"

                        exit $EXIT_CODE
                        ''',
                        returnStatus: true
                    )

                    if (tfStatus != 0) {
                        echo "==================== ❌ TERRAFORM APPLY FAILED ================"
                        error("Stopping pipeline due to Terraform failure")
                    } else {
                        echo "==================== ✅ TERRAFORM APPLY SUCCESS =============="
                    }
                }
            }
        }

        // ============================================================
        // ✅ WAIT FOR EKS READY
        // ============================================================
        stage('Wait for EKS Ready') {
            steps {
                echo "==================== ✅ WAIT FOR EKS START ==================="

                script {
                    def status = sh(
                        script: '''
                        set +e

                        sleep 90

                        CLUSTER_NAME="dev-eks-poc-${CLIENT}-${SERVICE}-b${BUILD_NUMBER}"

                        aws eks update-kubeconfig \
                          --region ${REGION} \
                          --name $CLUSTER_NAME

                        for i in {1..30}; do
                          READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c Ready)

                          if [ "$READY" -gt 0 ]; then
                            echo "✅ Nodes READY"
                            kubectl get nodes
                            exit 0
                          fi

                          echo "Waiting... attempt $i"
                          sleep 15
                        done

                        echo "⚠️ Nodes NOT ready"
                        exit 1
                        ''',
                        returnStatus: true
                    )

                    if (status != 0) {
                        echo "==================== ⚠️ WAIT WARNING ================="
                    } else {
                        echo "==================== ✅ WAIT SUCCESS ================="
                    }
                }
            }
        }

        // ============================================================
        // ✅ HELM DEPLOY
        // ============================================================
        stage('Helm Deploy') {
            steps {
                echo "==================== ✅ HELM DEPLOY START ===================="

                sh '''
                set +e

                helm upgrade --install demo-app helm/demo-app \
                  -f helm/demo-app/values-dev.yaml

                kubectl get pods -o wide || true
                kubectl get svc || true
                helm list || true
                '''

                echo "==================== ✅ HELM DEPLOY DONE ====================="
            }
        }

        // ============================================================
        // ✅ DEMO WINDOW
        // ============================================================
        stage('Demo Window') {
            steps {
                script {
                    int duration = params.DEMO_DURATION_MIN.toInteger()
                    sleep time: duration, unit: 'MINUTES'
                }
            }
        }

        // ============================================================
        // ✅ VALIDATION
        // ============================================================
        stage('Validation') {
            steps {
                sh '''
                kubectl get pods -A -o wide
                kubectl get svc
                kubectl get nodes
                helm list
                '''
            }
        }
    }

    // ============================================================
    // ✅ CLEANUP (POST)
    // ============================================================
    post {
        always {
            echo "==================== ✅ FINAL CLEANUP ========================"

            sh '''
            set +e
            cd terraform

            terraform destroy -auto-approve \
              -var="env=${ENV}" \
              -var="client=${CLIENT}" \
              -var="service=${SERVICE}" \
              -var="build_id=${BUILD_NUMBER}"

            exit 0
            '''

            echo "==================== ✅ CLEANUP COMPLETED ===================="
        }
    }
}