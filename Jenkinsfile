pipeline {
  agent any

  parameters {
    string(name: 'DEMO_DURATION_MIN', defaultValue: '10')
  }

  environment {
    BUILD_ID_VAR = "${env.BUILD_NUMBER}"
  }

  stages {

    stage('Terraform Apply') {
      steps {
        sh """
        cd terraform
        terraform init
        terraform apply -auto-approve \
        -var="env=dev" \
        -var="client=demo" \
        -var="service=app" \
        -var="build_id=${BUILD_ID_VAR}"
        """
      }
    }

    stage('Configure kubectl') {
      steps {
        sh """
        bash scripts/update-kubeconfig.sh dev-eks-poc-demo-app-b${BUILD_ID_VAR}
        """
      }
    }

    stage('Helm Deploy') {
      steps {
        sh """
        helm upgrade --install demo-app helm/demo-app \
        -f helm/demo-app/values-dev.yaml
        """
      }
    }

    stage('Demo Window') {
      steps {
        script {
          def d = params.DEMO_DURATION_MIN.toInteger()
          sleep time: d, unit: 'MINUTES'
        }
      }
    }

    stage('Validation') {
      steps {
        sh "bash scripts/validate.sh"
      }
    }

    stage('Terraform Destroy') {
      steps {
        sh """
        cd terraform
        terraform destroy -auto-approve \
        -var="env=dev" \
        -var="client=demo" \
        -var="service=app" \
        -var="build_id=${BUILD_ID_VAR}"
        """
      }
    }
  }
}