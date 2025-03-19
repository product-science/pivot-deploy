#!/bin/bash
# In ~/.bashrc or similar:
alias stack_rm_and_prune='
  docker stack rm $1 &&
  # wait for tasks to be fully removed
  sleep 5 &&
  docker volume rm $(docker volume ls -q -f label=com.docker.stack.namespace=$1) 2>/dev/null
'

stack_rm_and_prune dai