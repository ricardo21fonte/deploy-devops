#!/usr/bin/env bash
set -Eeuo pipefail

# =====================================================
# PASSO 1 - Ler e validar as versões
# Uso: bash scripts/deploy.sh 1.1.0 1.0.0
# =====================================================
NOVA="${1:-}"
ESTAVEL="${2:-}"
ROLLBACK_APPROVED="${ROLLBACK_APPROVED:-false}"
EXTRA="${EXTRA:-}"   # só no laboratório: "-f compose.failure.yaml"

if [[ -z "$NOVA" || -z "$ESTAVEL" ]]; then
    echo "Uso: bash scripts/deploy.sh <versao_nova> <versao_estavel>"
    exit 2
fi

echo "== Nova: $NOVA | Estável: $ESTAVEL | Rollback autorizado: $ROLLBACK_APPROVED"

# =====================================================
# PASSO 2 - Instalar a versão nova (igual ao Exercício 3)
# =====================================================
echo "== [2] A instalar a versão $NOVA..."
APP_VERSION="$NOVA" docker compose -f compose.yaml $EXTRA --env-file config/.env.prod -p fp07-prod up -d --pull always --force-recreate --wait --wait-timeout 90

# =====================================================
# PASSO 3 - Testar (igual à Parte E)
# =====================================================
echo "== [3] A testar a versão $NOVA..."
if bash scripts/smoke-test.sh; then
    echo "== SUCESSO: versão $NOVA instalada e a funcionar."
    exit 0
fi

# =====================================================
# PASSO 4 - Correu mal. Posso voltar atrás?
# =====================================================
echo "== FALHA: a versão $NOVA não passou nos testes."

if [[ "$ROLLBACK_APPROVED" != "true" ]]; then
    echo "== Rollback NÃO autorizado. A versão $NOVA ficou instalada. Alguém tem de decidir."
    exit 1
fi

# =====================================================
# PASSO 5 - Voltar à versão estável (igual ao Exercício 4)
# =====================================================
echo "== [5] Rollback para a versão $ESTAVEL..."
APP_VERSION="$ESTAVEL" docker compose -f compose.yaml --env-file config/.env.prod -p fp07-prod up -d --pull always --force-recreate --wait --wait-timeout 90

bash scripts/smoke-test.sh
echo "== Serviço recuperado na versão $ESTAVEL, MAS a release $NOVA FALHOU."
exit 1