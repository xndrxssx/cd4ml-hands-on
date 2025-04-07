pipeline {
    agent any
    parameters {
        choice(name: 'problem_name', choices: ['houses', 'groceries', 'iris'], description: 'Choose the problem name')
        string(name: 'ml_pipeline_params_name', defaultValue: 'default', description: 'Specify the ml_pipeline_params file')
        string(name: 'feature_set_name', defaultValue: 'default', description: 'Specify the feature_set name/file')
        string(name: 'algorithm_name', defaultValue: 'default', description: 'Specify the algorithm (overrides problem_params)')
        string(name: 'algorithm_params_name', defaultValue: 'default', description: 'Specify the algorithm params')
    }
    triggers {
        pollSCM('* * * * *') // Check for changes every minute
    }
    options {
        timestamps()
    }
    environment { 
        MLFLOW_TRACKING_URL = 'http://mlflow:5000'
        MLFLOW_S3_ENDPOINT_URL = 'http://minio:9000'
        AWS_ACCESS_KEY_ID = "${env.ACCESS_KEY}"
        AWS_SECRET_ACCESS_KEY = "${env.SECRET_KEY}"
    }

    stages {
        stage('Install dependencies') {
            steps {
                sh '''
                    python3 -m venv venv
                    ls -la venv/bin
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                '''
            }
        }

        stage('Run tests') {
            steps {
                sh '''
                    . venv/bin/activate
                    bash run_tests.sh
                '''
            }
        }

        stage('Run ML pipeline') {
            steps {
                sh '''
                    . venv/bin/activate
                    python run_python_script.py pipeline ${problem_name} ${ml_pipeline_params_name} ${feature_set_name} ${algorithm_name} ${algorithm_params_name}
                '''
            }
        }



        stage('Production - Register Model and Acceptance Test') {
            when {
                allOf {
                    equals expected: 'default', actual: "${params.ml_pipeline_params_name}"
                    equals expected: 'default', actual: "${params.feature_set_name}"
                    equals expected: 'default', actual: "${params.algorithm_name}"
                    equals expected: 'default', actual: "${params.algorithm_params_name}"
                }
            }
            steps {
                sh '''
                    . venv/bin/activate
                    python run_python_script.py acceptance
                '''
            }
            post {
                success {
                    sh '''
                        . venv/bin/activate
                        python run_python_script.py register_model ${MLFLOW_TRACKING_URL} yes
                    '''
                }
                failure {
                    sh '''
                        . venv/bin/activate
                        python run_python_script.py register_model ${MLFLOW_TRACKING_URL} no
                    '''
                }
            }
        }

        stage('Experiment - Register Model and Acceptance Test') {
            when {
                anyOf {
                    not { equals expected: 'default', actual: "${params.ml_pipeline_params_name}" }
                    not { equals expected: 'default', actual: "${params.feature_set_name}" }
                    not { equals expected: 'default', actual: "${params.algorithm_name}" }
                    not { equals expected: 'default', actual: "${params.algorithm_params_name}" }
                }
            }
            steps {
                sh '''
                    . venv/bin/activate || true
                    python run_python_script.py acceptance || true
                    python run_python_script.py register_model ${MLFLOW_TRACKING_URL} no
                '''
            }
        }
    }
}
