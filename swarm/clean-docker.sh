#!/usr/bin/env bash
set -euo pipefail

SSH_OPTS="-o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5"

docker_stack_rm_and_prune() {
  local stack_name="$1"

  echo "==> Removing stack '$stack_name' on manager..."

  local stack_count
  stack_count=$(docker stack ls --format "{{.Name}}" | grep -c "^${stack_name}\$" || true)
  if [[ "$stack_count" -eq 0 ]]; then
    echo "    -> Stack '$stack_name' not found. Continuing cleanup anyway..."
  else
    docker stack rm "${stack_name}"
  fi

  echo "==> Waiting for tasks to be removed (if any) for '$stack_name'..."
  while docker stack ps "${stack_name}" --format '{{.ID}}' 2>/dev/null | grep -q '.'; do
    echo "    -> Tasks are still shutting down. Checking again in 2 seconds."
    sleep 2
  done
  echo "    -> All tasks stopped or stack did not exist."

  echo "==> Removing volumes for stack '$stack_name' on manager..."
  remove_labeled_volumes "$stack_name" "manager"

  echo "==> Removing volumes for stack '$stack_name' on worker nodes..."
  while IFS= read -r node_id; do
    local node_name node_role node_state
    node_name=$(docker node inspect --format '{{.Description.Hostname}}' "${node_id}")
    node_role=$(docker node inspect --format '{{.Spec.Role}}' "${node_id}")
    node_state=$(docker node inspect --format '{{.Status.State}}' "${node_id}")

    if [[ "${node_role}" == "worker" && "${node_state}" == "ready" ]]; then
      echo "    -> Checking worker: ${node_name}"
      if timeout 5 ssh $SSH_OPTS "${node_name}" true 2>/dev/null; then
        ssh $SSH_OPTS "${node_name}" "$(declare -f remove_labeled_volumes); remove_labeled_volumes \"${stack_name}\" \"${node_name}\""
      else
        echo "       ** WARNING: '${node_name}' is unreachable via SSH. Skipping."
      fi
    else
      echo "    -> Skipping node '${node_name}' [role=${node_role}, state=${node_state}]"
    fi
  done < <(docker node ls --format '{{.ID}}')

  echo "==> Finished cleaning up stack '${stack_name}' from manager and workers."
}

remove_labeled_volumes() {
  local stack_name="$1"
  local location="$2"  # e.g. "manager" or node hostname

  echo "    -> Attempting to remove labeled volumes on '${location}'..."
  for attempt in 1 2 3; do
    # Gather ny volumes labeled for this stack
    local leftover_vols
    leftover_vols=$(docker volume ls -q -f label=com.docker.stack.namespace="${stack_name}")
    if [[ -n "${leftover_vols}" ]]; then
      echo "       Attempt ${attempt}: removing volumes..."
      docker volume rm ${leftover_vols} 2>/dev/null || true
      sleep 2
    else
      echo "       No volumes labeled for stack '${stack_name}' on '${location}'."
      break
    fi
  done
}

docker_stack_rm_and_prune dai
