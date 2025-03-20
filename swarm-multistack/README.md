# README.md

## Overview

This directory contains two Docker Swarm stacks:

1.	**Genesis stack** (`docker-compose.genesis.yml`) — the "genesis" node of the crypto system.
2.	**Join stack** (`docker-compose.join.yml`) — used to spin up additional participant nodes in the network.

Each participant has:
* A "node" service (the chain process),
* An "api" service (the decentralized AI API),
* An "inference" service (ML inference).


We use one shared overlay network, dai-network, so everything can communicate internally via DNS names (e.g., `genesis_node`, `join1_api`, etc.) without needing external IP addresses.


----

## Setup Swarm

1. Ensure your Swarm is initialized

Init from master node:
```
docker swarm init
```

And join from others:
```
docker swarm join --token <TOKEN> <MASTER_NODE_IP>:2377
```


## Manual Deploy 

### 1. Label the “genesis” node.

Find one of your node ID via `docker node ls`, then:
```
docker node update --label-add genesis=true <NODE_ID>
```

The genesis containers will be deployed there.

###
