# Wait for a pod to complete (Succeeded or Failed)
# Usage: set POD_NAME and POD_NAMESPACE env vars before sourcing this file
# Example:
#   export POD_NAME=my-pod
#   export POD_NAMESPACE=default
#   source ./wait-for-pod-complete.sh

if [ -z "$POD_NAME" ]; then
  echo "[ERROR] POD_NAME environment variable not set." >&2
  return 1
fi
if [ -z "$POD_NAMESPACE" ]; then
  echo "[ERROR] POD_NAMESPACE environment variable not set." >&2
  return 1
fi

ATTEMPTS=0
MAX_ATTEMPTS=20
SLEEP_SECONDS=5
echo "[INFO] Waiting for pod $POD_NAME in namespace $POD_NAMESPACE to complete..."
while true; do
  STATUS=$(microk8s kubectl get pod "$POD_NAME" -n "$POD_NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
  if [ "$STATUS" = "Succeeded" ]; then
    echo "[SUCCESS] Pod $POD_NAME completed successfully."
    break
  elif [ "$STATUS" = "Failed" ]; then
    echo "[ERROR] Pod $POD_NAME failed. Check logs." >&2
    return 2
  elif [ "$STATUS" = "NotFound" ]; then
    echo "[INFO] Pod $POD_NAME not found yet. Waiting..."
  else
    echo "[INFO] Pod $POD_NAME status: $STATUS. Waiting..."
  fi
  ATTEMPTS=$((ATTEMPTS+1))
  if [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; then
    echo "[ERROR] Timeout waiting for pod $POD_NAME in namespace $POD_NAMESPACE." >&2
    return 3
  fi
  sleep $SLEEP_SECONDS
done 