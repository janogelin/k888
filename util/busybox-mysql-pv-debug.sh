#!/bin/bash
set -e

###############################################################################
# busybox-mysql-pv-debug.sh
#
# Deploys a BusyBox pod that mounts the existing MySQL PersistentVolume (mysql-pv)
# for interactive debugging. The pod will run with an interactive shell (sh).
#
# Usage:
#   bash util/busybox-mysql-pv-debug.sh
#
# Prerequisites:
#   - MicroK8s or kubectl context set to the target cluster
#   - mysql-pv PersistentVolume exists
###############################################################################

# Variables
PVC_NAME="mysql-pvc-debug"
POD_NAME="busybox-mysql-debug"
NAMESPACE="default"
STORAGE_CLASS="microk8s-hostpath"

# 1. Create a PersistentVolumeClaim if it doesn't exist
cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $PVC_NAME
  namespace: $NAMESPACE
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: $STORAGE_CLASS
  resources:
    requests:
      storage: 1Gi
EOF

echo "[INFO] PVC $PVC_NAME applied."

# 2. Deploy BusyBox pod with PVC mounted
cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
  namespace: $NAMESPACE
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sh"]
    args: ["-c", "sleep 36000"]
    stdin: true
    tty: true
    volumeMounts:
    - name: mysql-storage
      mountPath: /mnt
  volumes:
  - name: mysql-storage
    persistentVolumeClaim:
      claimName: $PVC_NAME
  restartPolicy: Never
EOF

echo "[INFO] BusyBox debug pod deployed. Waiting for pod to be ready..."

# 3. Wait for pod to be running
microk8s kubectl wait --for=condition=Ready pod/$POD_NAME --timeout=60s || {
  echo "[ERROR] Pod did not become ready in time." >&2
  exit 1
}

echo "[INFO] Attaching to BusyBox pod. Type 'exit' to leave the shell."

# 4. Attach to the pod
microk8s kubectl exec -it $POD_NAME -- sh

echo "[INFO] To clean up, run:"
echo "  microk8s kubectl delete pod $POD_NAME"
echo "  microk8s kubectl delete pvc $PVC_NAME (optional)" 
