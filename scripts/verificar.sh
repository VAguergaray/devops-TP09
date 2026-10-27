#!/bin/bash
# ============================================
# verificar.sh — Chequea que el TP09 esté OK
# ============================================

set -uo pipefail

NS="devops-portfolio"
ERRORS=0

ok()   { echo "  [OK] $1"; }
fail() { echo "  [FAIL] $1"; ERRORS=$((ERRORS+1)); }

echo "=== Verificación Kubernetes — TP09 ==="
echo ""

echo "--- Nodos del cluster ---"
while read -r NAME STATUS _; do
  [ "$STATUS" = "Ready" ] && ok "Nodo $NAME → $STATUS" || fail "Nodo $NAME → $STATUS"
done < <(kubectl get nodes --no-headers)

echo ""
echo "--- Pods (deben estar Running) ---"
while read -r NAME READY STATUS _; do
  [ "$STATUS" = "Running" ] && ok "$NAME → $STATUS ($READY)" || fail "$NAME → $STATUS"
done < <(kubectl get pods -n "$NS" --no-headers 2>/dev/null)

echo ""
echo "--- Deployments ---"
while read -r NAME READY _ AVAILABLE _; do
  [ "$READY" = "$AVAILABLE/$AVAILABLE" ] \
    && ok "$NAME → $READY réplicas listas" \
    || fail "$NAME → $READY (esperado $AVAILABLE/$AVAILABLE)"
done < <(kubectl get deployments -n "$NS" --no-headers 2>/dev/null)

echo ""
echo "--- Services ---"
while read -r NAME TYPE _ _ PORT _; do
  ok "$NAME → $TYPE ($PORT)"
done < <(kubectl get svc -n "$NS" --no-headers 2>/dev/null)

echo ""
echo "--- PVC (debe estar Bound) ---"
while read -r NAME STATUS _ SIZE _; do
  [ "$STATUS" = "Bound" ] && ok "$NAME → $STATUS ($SIZE)" || fail "$NAME → $STATUS"
done < <(kubectl get pvc -n "$NS" --no-headers 2>/dev/null)

echo ""
echo "--- Healthcheck HTTP ---"
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}' 2>/dev/null)
URL=""
for HOST in localhost "$NODE_IP"; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$HOST:30080/" 2>/dev/null || echo "000")
  if [ "$CODE" = "200" ]; then URL="http://$HOST:30080"; break; fi
done
[ -n "$URL" ] && ok "$URL → HTTP 200" || fail "http://localhost:30080 → HTTP $CODE"

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "Cluster OK — todos los checks pasaron"
else
  echo "$ERRORS checks fallaron"
  exit 1
fi
