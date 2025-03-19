#!/bin/bash

docker_stack_rm_and_prune() {
  local stack_name="$1"

  echo "Removing stack '${stack_name}' on manager..."
  docker stack rm "${stack_name}"

  # Wait for tasks to be fully removed
  sleep 5

  echo "Removing volumes on manager labeled for stack '${stack_name}'..."
  docker volume rm $(docker volume ls -q -f label=com.docker.stack.namespace="${stack_name}") 2>/dev/null

  # Loop over each node in the swarm, filter out only worker nodes
  echo "Cleaning up volumes on worker nodes..."
  for node_id in $(docker node ls --format '{{.ID}}'); do
    # Retrieve node information
    node_name=$(docker node inspect --format '{{.Description.Hostname}}' "${node_id}")
    node_role=$(docker node inspect --format '{{.Spec.Role}}' "${node_id}")

    # Only remove volumes from worker nodes
    if [ "${node_role}" = "worker" ]; then
      echo "  -> Removing volumes for stack '${stack_name}' on worker: ${node_name}"

      # Run the removal command via SSH on each worker
      # (adjust or remove `-q -f label=...` if you prefer to prune *all* volumes)
      ssh "${node_name}" "docker volume rm \$(docker volume ls -q -f label=com.docker.stack.namespace=\"${stack_name}\") 2>/dev/null"
    fi
  done
}

# Usage
docker_stack_rm_and_prune dai