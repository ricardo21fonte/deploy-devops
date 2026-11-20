#!/usr/bin/env bash
set -Eeuo pipefail

BASE_URL="${BASE_URL:-http://localhost:8003}"
FAILED=0

echo "Smoke tests em $BASE_URL"

for endpoint in health ready api/status; do
    code=$(curl --silent --output /dev/null --write-out '%{http_code}' --max-time 5 "$BASE_URL/$endpoint" || true)

    if [[ "$code" == "200" ]]; then
        echo " [OK] /$endpoint -> HTTP $code"
    else
        echo "  [ERRO] /$endpoint -> HTTP $code (esperado 200)"
        FAILED=$((FAILED + 1))
    fi
done

if [[ $FAILED -gt 0 ]]; then
    echo "RESULTADO: FALHA ($FAILED verificações falharam)"
    exit 1
fi

echo "RESULTADO: SUCESSO"
exit 0