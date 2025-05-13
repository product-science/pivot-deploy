# Genesis Node K3s Deployment

This directory contains Kubernetes manifests for deploying the Genesis Node on a k3s cluster.

## Prerequisites

- A running k3s cluster with at least one worker node that has GPU support
- `kubectl` configured to access your cluster
- `stern` (optional, for improved log viewing)

## Deployment

1. **Configure kubectl** either by:
   - Copying `/etc/rancher/k3s/k3s.yaml` from control-plane to `~/.kube/config` locally, or
   - Setting up an SSH tunnel (see Appendix)

2. **Set up GitHub Container Registry authentication**:
   ```bash
   kubectl create secret docker-registry ghcr-credentials \
     --docker-server=ghcr.io \
     --docker-username=YOUR_GITHUB_USERNAME \
     --docker-password=YOUR_GITHUB_TOKEN
   ```
   Replace `YOUR_GITHUB_USERNAME` with your GitHub username and `YOUR_GITHUB_TOKEN` with a Personal Access Token that has `read:packages` permission.

3. **Deploy the Genesis Node**:
   ```bash
   kubectl apply -f .
   ```

4. **Verify deployment**:
   ```bash
   kubectl get pods
   ```
   Wait until all pods (`node-0`, `api-*`, `tmkms-*`, `inference-*`) show `Running` status.

## Managing the Deployment

### View Logs

**Using kubectl** (individual components):
```bash
kubectl logs -f node-0                 # Node logs
kubectl logs -f $(kubectl get pod -l app=api -o name)        # API logs
kubectl logs -f $(kubectl get pod -l app=tmkms -o name)      # TMKMS logs
kubectl logs -f $(kubectl get pod -l app=inference -o name)  # Inference logs
```

**Using stern** (all components):
```bash
stern 'node|api|tmkms|inference' --exclude-container=POD
```

### Restart Components

```bash
kubectl rollout restart statefulset/node       # Restart node
kubectl rollout restart deployment/api         # Restart API
kubectl rollout restart deployment/tmkms       # Restart TMKMS
kubectl rollout restart deployment/inference   # Restart inference
```

### Update Configuration

1. Edit the ConfigMap:
   ```bash
   kubectl edit configmap config
   ```

2. Restart affected components:
   ```bash
   kubectl rollout restart statefulset/node deployment/api
   ```

### Delete/Stop Everything

```bash
kubectl delete -f .
```

## Appendix: SSH Tunnel Setup

If accessing the cluster remotely, set up an SSH tunnel:

```bash
# Start tunnel
gcloud compute ssh k8s-control-plane \
    --project=YOUR_GCP_PROJECT_ID \
    --zone=YOUR_GCE_INSTANCE_ZONE \
    -- -L 6443:127.0.0.1:6443 -N -f

# Check tunnel status
pgrep -f 'ssh.*-L 6443:127.0.0.1:6443' > /dev/null && echo "Tunnel ACTIVE" || echo "Tunnel NOT ACTIVE"

# Kill tunnel
pkill -f 'ssh.*-L 6443:127.0.0.1:6443'
```

Update your kubeconfig's server field to: `https://127.0.0.1:6443`
