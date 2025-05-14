```bash
NAMESPACE=join-worker2
kubectl create namespace $NAMESPACE
kubectl apply -f worker2-node-config.yaml -n $NAMESPACE
kubectl apply -f worker2-overrides.yaml -n $NAMESPACE
# Assuming nodeSelector in k3s/join/*-deployment/statefulset.yaml is set for k8s-worker-2
kubectl apply -f k3s/join/tmkms-pvc.yaml -n $NAMESPACE
kubectl apply -f k3s/join/inference-data-pvc.yaml -n $NAMESPACE
kubectl apply -f k3s/join/tmkms-deployment.yaml -n $NAMESPACE
kubectl apply -f k3s/join/node-statefulset.yaml -n $NAMESPACE # and so on for all manifests
kubectl apply -f k3s/join/ -n $NAMESPACE # Or apply all at once after configmaps and PVCs
```
