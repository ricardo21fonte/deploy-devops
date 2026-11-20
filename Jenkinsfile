pipeline {
    // Correr no agente da Ficha 05 (o que tem Docker)
    agent { label 'ci-python-docker' }

    options {
        disableConcurrentBuilds()   // não deixar dois deploys ao mesmo tempo
        timestamps()                // horas em cada linha do log
    }

    // Opções que aparecem no "Build with Parameters"
    parameters {
        choice(name: 'NOVA', choices: ['1.1.0', '1.0.0'], description: 'Versão a instalar')
        string(name: 'ESTAVEL', defaultValue: '1.0.0', description: 'Versão estável, para o rollback')
        booleanParam(name: 'ROLLBACK_APPROVED', defaultValue: true, description: 'Autorizar rollback automático')
        booleanParam(name: 'SIMULAR_FALHA', defaultValue: false, description: 'LABORATÓRIO: usar compose.failure.yaml')
    }

    environment {
        // A app corre dentro do docker-engine, por isso o smoke test vai lá
        BASE_URL = 'http://docker-engine:8003'
    }

    stages {
        stage('Validar pré-requisitos') {
            steps {
                sh '''
                    docker version
                    docker compose version
                    test -f compose.yaml
                    test -f scripts/deploy.sh
                    test -f scripts/smoke-test.sh

                    # O .env.prod não está no Git: criar a partir do exemplo
                    sed "s#seu-utilizador#ricardo21fonte#" config/.env.prod.example > config/.env.prod
                    cat config/.env.prod
                '''
            }
        }

        stage('Deploy') {
            steps {
                script {
                    def extra = params.SIMULAR_FALHA ? '-f compose.failure.yaml' : ''

                    // Correr o deploy.sh, guardar o output em deploy.log e o código de saída
                    def codigo = sh(returnStatus: true, script: """#!/bin/bash
                        set -o pipefail
                        EXTRA='${extra}' ROLLBACK_APPROVED='${params.ROLLBACK_APPROVED}' \
                          bash scripts/deploy.sh '${params.NOVA}' '${params.ESTAVEL}' 2>&1 | tee deploy.log
                    """)

                    // Registar se houve rollback
                    def houveRollback = readFile('deploy.log').contains('Rollback para a versão')
                    currentBuild.description = "v${params.NOVA} | código ${codigo}" +
                                               (houveRollback ? " | ROLLBACK para ${params.ESTAVEL}" : "")

                    // Falhar a build se a versão nova não foi aprovada
                    if (codigo != 0) {
                        error("A versão ${params.NOVA} não foi aprovada (código ${codigo}).")
                    }
                }
            }
        }
    }

    post {
        always {
            sh 'docker compose -p fp07-prod ps || true'
            archiveArtifacts artifacts: 'deploy.log', allowEmptyArchive: true
        }
    }
}