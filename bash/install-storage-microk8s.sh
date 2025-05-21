#!/bin/bash
set -e

###############################################################################
# install-storage-microk8s.sh
#
# This script enables storage in MicroK8s, creates local directories for MySQL
# and web, sets permissions, creates a PersistentVolume for MySQL, applies it,
# and runs a test pod to verify the volume works.
#
# Usage:
#   bash install-storage-microk8s.sh
#
# Prerequisites:
#   - MicroK8s installed and running
#   - User has permissions to run microk8s commands (may require sudo)
#   - Sudo permissions to create and chown local directories
###############################################################################

# Function to print error and exit
error_exit() {
  echo "[ERROR] $1" >&2
  exit 1
}

# 1. Enable storage in MicroK8s
# This is required for dynamic and static provisioning.
echo "[INFO] Enabling storage in MicroK8s..."
microk8s enable storage || error_exit "Failed to enable storage."

# 2. Create local directories for MySQL and web
MYSQL_DIR="/mnt/mysql-data"
WEB_DIR="/mnt/web-data"
echo "[INFO] Checking local directories for MySQL and web..."
if [ -d "$MYSQL_DIR" ]; then
  echo "[INFO] $MYSQL_DIR already exists."
else
  echo "[INFO] Creating $MYSQL_DIR..."
  sudo mkdir -p "$MYSQL_DIR" || error_exit "Failed to create $MYSQL_DIR."
fi
if [ -d "$WEB_DIR" ]; then
  echo "[INFO] $WEB_DIR already exists."
else
  echo "[INFO] Creating $WEB_DIR..."
  sudo mkdir -p "$WEB_DIR" || error_exit "Failed to create $WEB_DIR."
fi

# Set permissions for MySQL (uid/gid 1001 is default for Bitnami MySQL)
echo "[INFO] Setting permissions for $MYSQL_DIR (1001:1001)..."
sudo chown -R 1001:1001 "$MYSQL_DIR" || error_exit "Failed to chown $MYSQL_DIR."
# Set permissions for web (use 1000:1000 as a common web user, adjust as needed)
echo "[INFO] Setting permissions for $WEB_DIR (1000:1000)..."
sudo chown -R 1000:1000 "$WEB_DIR" || error_exit "Failed to chown $WEB_DIR."

echo "[INFO] Directories created and permissions set."

# 3. Create PersistentVolume YAML for MySQL
PV_YAML="/tmp/mysql-pv.yaml"
echo "[INFO] Creating PersistentVolume YAML at $PV_YAML..."
cat <<EOF > "$PV_YAML"
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: "$MYSQL_DIR"
    type: DirectoryOrCreate
EOF

echo "[INFO] PersistentVolume YAML created."

# 4. Apply the PersistentVolume
microk8s kubectl apply -f "$PV_YAML" || error_exit "Failed to apply PersistentVolume."
echo "[INFO] PersistentVolume applied."

# 5. Create a test pod that uses the PV and checks write/delete
TEST_POD_YAML="/tmp/mysql-pv-test-pod.yaml"
echo "[INFO] Creating test pod YAML at $TEST_POD_YAML..."
cat <<EOF > "$TEST_POD_YAML"
apiVersion: v1
kind: Pod
metadata:
  name: mysql-pv-test
spec:
  restartPolicy: Never
  containers:
  - name: busybox
    image: busybox
    command: ["sh", "-c", "echo 'testdata' > /mnt/testfile && cat /mnt/testfile && rm /mnt/testfile && echo 'done'"]
    volumeMounts:
    - name: mysql-storage
      mountPath: /mnt
  volumes:
  - name: mysql-storage
    persistentVolumeClaim:
      claimName: mysql-pvc-test
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc-test
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  resources:
    requests:
      storage: 1Gi
EOF

echo "[INFO] Test pod YAML created."

# 6. Apply the PVC and test pod
microk8s kubectl apply -f "$TEST_POD_YAML" || error_exit "Failed to apply test pod and PVC."

# Wait for test pod to complete
export POD_NAME="mysql-pv-test"
export POD_NAMESPACE="default"
source "$(dirname "$0")/wait-for-pod-complete.sh"

# Show pod logs
microk8s kubectl logs mysql-pv-test || true

# 7. Cleanup test pod and PVC
microk8s kubectl delete pod mysql-pv-test || true
microk8s kubectl delete pvc mysql-pvc-test || true

# Optionally, delete the PV (uncomment if desired)
# microk8s kubectl delete pv mysql-pv || true

# Remove temp files
echo "[INFO] Cleaning up temp files..."
rm -f "$PV_YAML" "$TEST_POD_YAML"

echo "[INFO] Storage setup and test complete." 