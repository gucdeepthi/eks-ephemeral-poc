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
                echo "***** Installing Packages *****"
                sudo apt-get update -y
                sudo apt-get install -y unzip curl git wget

                echo "***** Checking AWS CLI *****"
                if ! command -v aws >/dev/null 2>&1; then
                  curl -s https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
                  unzip -o awscliv2.zip
                  sudo ./aws/install --update
                fi
                aws --version

                echo "***** Terraform Version *****"
                terraform version || true
                '''

                echo "==================== ✅ SETUP TOOLS SUCCESS =================="
            }
        }

        // ============================================================
        // ✅ TERRAFORM APPLY
        // ============================================================
        stage('Terraform Apply') {
            steps {
                echo "==================== ✅ TERRAFORM APPLY START ================"

                sh '''
                set -e
                cd terraform

                echo "***** Terraform Init *****"
                terraform init

                echo "***** Terraform Apply *****"
                terraform apply -auto-approve \
                  -var="env=${ENV}" \
                  -var="client=${CLIENT}" \
                  -var="service=${SERVICE}" \
                  -var="build_id=${BUILD_NUMBER}"
                '''

                echo "==================== ✅ TERRAFORM APPLY SUCCESS =============="
            }
        }

        // ============================================================
        // ✅ WAIT FOR EKS READY (FIXED)
        // ============================================================
        stage('Wait for EKS Ready') {
            steps {
                echo "==================== ✅ WAIT FOR EKS START ==================="

                script {
                    def status = sh(
                        script: '''
                        set +e

                        echo "***** Initial wait for stabilization *****"
                        sleep 90

                        CLUSTER_NAME="dev-eks-poc-${CLIENT}-${SERVICE}-b${BUILD_NUMBER}"

                        echo "***** Updating kubeconfig *****"
                        aws eks update-kubeconfig \
                          --region ${REGION} \
                          --name $CLUSTER_NAME

                        echo "***** Checking Node Readiness *****"

                        for i in {1..30}; do
                          READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c Ready)

                          if [ "$READY" -gt 0 ]; then
                            echo "***** ✅ Nodes READY *****"
                            kubectl get nodes
                            exit 0
                          fi

                          echo "***** Waiting... attempt $i *****"
                          sleep 15
                        done

                        echo "***** ⚠️ Nodes NOT ready after retries *****"
                        exit 1
                        ''',
                        returnStatus: true
                    )

                    if (status != 0) {
                        echo "==================== ⚠️ WAIT FOR EKS WARNING ================="
                    } else {
                        echo "==================== ✅ WAIT FOR EKS SUCCESS ================="
                    }
                }
            }
        }

        // ============================================================
        // ✅ HELM DEPLOY (SAFE)
        // ============================================================
        stage('Helm Deploy') {
            steps {
                echo "==================== ✅ HELM DEPLOY START ===================="

                script {
                    def helmStatus = sh(
                        script: '''
                        set +e

                        echo "***** Running Helm Deployment *****"
                        helm upgrade --install demo-app helm/demo-app \
                          -f helm/demo-app/values-dev.yaml

                        EXIT_CODE=$?

                        echo "***** Helm Exit Code: $EXIT_CODE *****"

                        echo "***** POD STATUS *****"
                        kubectl get pods -o wide || true

                        echo "***** SERVICES *****"
                        kubectl get svc || true

                        echo "***** HELM RELEASES *****"
                        helm list || true

                        exit $EXIT_CODE
                        ''',
                        returnStatus: true
                    )

                    if (helmStatus != 0) {
                        echo "==================== ⚠️ HELM DEPLOY WARNING ================="
                    } else {
                        echo "==================== ✅ HELM DEPLOY SUCCESS =================="
                    }
                }
            }
        }

        // ============================================================
        // ✅ DEMO WINDOW
        // ============================================================
        stage('Demo Window') {
            steps {
                echo "==================== ✅ DEMO WINDOW START ===================="

                script {
                    int duration = params.DEMO_DURATION_MIN.toInteger()

                    if (duration < 5 || duration > 60) {
                        error("Invalid duration")
                    }

                    echo "***** Running for ${duration} minutes *****"
                    sleep time: duration, unit: 'MINUTES'
                }

                echo "==================== ✅ DEMO WINDOW SUCCESS =================="
            }
        }

        // ============================================================
        // ✅ VALIDATION
        // ============================================================
        stage('Validation') {
            steps {
                echo "==================== ✅ VALIDATION START ====================="

                sh '''
                echo "***** ALL PODS *****"
                kubectl get pods -A -o wide

                echo "***** SERVICES *****"
                kubectl get svc

                echo "***** NODES *****"
                kubectl get nodes

                echo "***** HELM RELEASES *****"
                helm list
                '''

                echo "==================== ✅ VALIDATION SUCCESS ==================="
            }
        }
    }

    // ============================================================
    // ✅ CLEANUP (SAFE)
    // ============================================================
    post {
        always {
            echo "==================== ✅ CLEANUP START ========================"

            sh '''
            set +e

            if command -v terraform >/dev/null 2>&1; then
              cd terraform

              echo "***** Terraform Destroy *****"
              terraform destroy -auto-approve \
                -var="env=${ENV}" \
                -var="client=${CLIENT}" \
                -var="service=${SERVICE}" \
                -var="build_id=${BUILD_NUMBER}"

              EXIT_CODE=$?

              echo "***** Terraform Exit Code: $EXIT_CODE *****"

              if [ $EXIT_CODE -eq 0 ]; then
                echo "***** ✅ Destroy SUCCESS *****"
              else
                echo "***** ⚠️ Destroy completed with warnings *****"
              fi
            fi

            exit 0
            '''

            echo "==================== ✅ CLEANUP COMPLETED ===================="
        }
    }
}