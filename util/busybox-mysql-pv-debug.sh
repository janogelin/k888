#!/bin/bash
set -e

###############################################################################
# busybox-web-pv-debug.sh
#
# Creates a new 5Gi PersistentVolume and PersistentVolumeClaim for 'web',
# using the default storage class. Deploys a BusyBox pod that mounts the PVC
# at /mnt for interactive testing.
#
# Usage:
#   bash util/busybox-mysql-pv-debug.sh
#
# Prerequisites:
#   - MicroK8s or kubectl context set to the target cluster
###############################################################################

# Variables
PV_NAME="web-pv-debug"
PVC_NAME="web-pvc-debug"
POD_NAME="busybox-web-debug"
NAMESPACE="default"
WEB_DIR="/mnt/web-data"

# 1. Create local directory for PV if it doesn't exist
if [ ! -d "$WEB_DIR" ]; then
  echo "[INFO] Creating $WEB_DIR..."
  sudo mkdir -p "$WEB_DIR"
  sudo chown 1000:1000 "$WEB_DIR"
else
  echo "[INFO] $WEB_DIR already exists."
fi

# 2. Create PersistentVolume YAML
cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: $PV_NAME
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: "$WEB_DIR"
    type: DirectoryOrCreate
EOF

echo "[INFO] PersistentVolume $PV_NAME applied."

# 3. Create PersistentVolumeClaim YAML (default storage class)
cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $PVC_NAME
  namespace: $NAMESPACE
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  volumeName: $PV_NAME
EOF

echo "[INFO] PersistentVolumeClaim $PVC_NAME applied."

# 4. Describe the PVC
microk8s kubectl describe pvc $PVC_NAME -n $NAMESPACE

# 5. Deploy BusyBox pod with PVC mounted
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
    - name: web-storage
      mountPath: /mnt
  volumes:
  - name: web-storage
    persistentVolumeClaim:
      claimName: $PVC_NAME
  restartPolicy: Never
EOF

echo "[INFO] BusyBox debug pod deployed. Waiting for pod to be ready..."

# 6. Wait for pod to be running
microk8s kubectl wait --for=condition=Ready pod/$POD_NAME --timeout=60s || {
  echo "[ERROR] Pod did not become ready in time." >&2
  exit 1
}

echo "[INFO] Attaching to BusyBox pod. Type 'exit' to leave the shell."

# 7. Attach to the pod
microk8s kubectl exec -it $POD_NAME -- sh

echo "[INFO] To clean up, run:"
echo "  microk8s kubectl delete pod $POD_NAME"
echo "  microk8s kubectl delete pvc $PVC_NAME"
echo "  microk8s kubectl delete pv $PV_NAME" 
