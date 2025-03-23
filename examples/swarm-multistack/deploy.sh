#!/usr/bin/env bash
#
# This script:
#  1) Removes any existing "genesis" or "join*" labels from all Swarm nodes.
#  2) Finds the first manager node to label as "genesis".
#  3) Labels each worker node as "join1", "join2", etc.
#  4) Generates a corresponding join{i}.env file for each worker node.
#  5) Deploys the "genesis" stack.
#  6) Deploys each join{i} stack using the generated .env files.

set -e

# Location where we'll store generated env files
CONFIGS_DIR="configs"
mkdir -p "$CONFIGS_DIR"

echo "=== 1) Removing existing 'genesis' and 'join*' labels from all nodes ==="
ALL_NODES=$(docker node ls --format '{{.ID}}')

for NODE_ID in $ALL_NODES; do
  # Get all labels for this node
  LABELS=$(docker node inspect "$NODE_ID" --format '{{ range $k, $v := .Spec.Labels }}{{ $k }} {{ end }}')

  for LBL in $LABELS; do
    # If label is "genesis" or starts with "join", remove it
    if [[ "$LBL" == "genesis" ]] || [[ "$LBL" =~ ^join ]]; then
      echo "Removing label '$LBL' from node $NODE_ID"
      docker node update --label-rm "$LBL" "$NODE_ID" >/dev/null
    fi
  done
done

echo ""
echo "=== 2) Labeling the first manager node as 'genesis' ==="
MANAGER_NODE=$(docker node ls --filter role=manager --format '{{.ID}}' | head -n1)
if [ -z "$MANAGER_NODE" ]; then
  echo "ERROR: No Swarm manager found. Make sure you're in a Docker Swarm."
  exit 1
fi
docker node update --label-add genesis=true "$MANAGER_NODE"

echo ""
echo "=== 3) Labeling each worker node as 'join1', 'join2', etc. ==="
WORKER_NODES=$(docker node ls --filter role=worker --format '{{.ID}}')
JOIN_INDEX=1

for NODE_ID in $WORKER_NODES; do
  LABEL="join${JOIN_INDEX}"
  echo "Labeling node $NODE_ID with '$LABEL=true'"
  docker node update --label-add "${LABEL}=true" "$NODE_ID"

  # Generate an .env file for this join participant
  ENV_FILE="$CONFIGS_DIR/$LABEL.env"

  cat <<EOF > "$ENV_FILE"
NODE_LABEL=${LABEL}
KEY_NAME=${LABEL}

SEED_NODE_RPC_URL=http://genesis_node:26657
SEED_NODE_P2P_URL=tcp://genesis_node:26656
SEED_API_URL=http://genesis_api:8080

PUBLIC_URL=http://${LABEL}_api:8080
POC_CALLBACK_URL=http://${LABEL}_api:8080
EOF

  echo "Created $ENV_FILE"

  JOIN_INDEX=$((JOIN_INDEX+1))
done

echo ""
echo "=== 4) Deploying the 'genesis' stack ==="
docker stack deploy -c docker-compose.genesis.yml genesis

echo "Waiting for genesis stack to be ready..."
sleep 15
echo "Checking if genesis stack is ready..."
while ! docker stack ps genesis --format "{{.CurrentState}}" | grep -q "Running"; do
  echo "Genesis stack is not ready yet, waiting..."
  sleep 5
done
echo "Genesis stack is running!"

echo ""
echo "=== 5) Deploying each 'join{i}' stack ==="
for ENV_FILE in "$CONFIGS_DIR"/join*.env; do
  STACK_NAME="$(basename "$ENV_FILE" .env)"  # e.g. join1, join2, ...
  echo "Deploying stack '$STACK_NAME' with env file '$ENV_FILE'"
  set -a && source "$ENV_FILE" && set +a && \
    docker stack deploy -c docker-compose.join.yml "$STACK_NAME"
done

echo ""
echo "All done!
- 'genesis' stack deployed on node labeled 'genesis'
- 'join{i}' stacks deployed on nodes labeled 'join{i}'
"