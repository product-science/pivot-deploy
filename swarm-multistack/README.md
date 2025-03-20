# Deploy TestNet with Docker Swarm

## Overview

This directory contains two Docker Swarm stacks:

1.	**Genesis stack** (`docker-compose.genesis.yml`) — the "genesis" node of the crypto system.
2.	**Join stack** (`docker-compose.join.yml`) — used to spin up additional participant nodes in the network.

Each participant has:
* A "node" service (the chain process),
* An "api" service (the decentralized AI API),
* An "inference" service (ML inference).


We use one shared overlay network, dai-network, so everything can communicate internally via DNS names (e.g., `genesis_node`, `join1_api`, etc.) without needing external IP addresses.


## Requirements

Each server has have installed:
- [docker](https://docs.docker.com/engine/install/)
- [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)

Also `nvidia` runtime has to be selected as default:

In `/etc/docker/daemon.json`:
```
{
    ...
    "runtimes": {
        "nvidia": {
            "args": [],
            "path": "nvidia-container-runtime"
        }
    },
    "default-runtime": "nvidia"
}
```

Then restart:
```
sudo systemctl daemon-reload
sudo systemctl restart docker
```


----

## Setup Swarm

1. Ensure your Swarm is initialized

Init from master node:
```
docker swarm init
```

And join from workers:
```
docker swarm join --token <TOKEN> <MASTER_NODE_IP>:2377
```

Also master should mark all nodes as node with gpu:
```
docker node update --label-add gpu=true <NODE_ID>
```


## Manual Deploy 

### 1. Label the "genesis" node.

Find one of your node ID via `docker node ls`, then:
```
docker node update --label-add genesis=true <NODE_ID>
```

The genesis containers will be deployed there.

### 2. Create the overlay network if you haven't yet:
```
docker network create --driver overlay --attachable dai-network
```

### 3. Deploy the genesis stack
```
docker stack deploy -c docker-compose.genesis.yml genesis
```

### 4. Label each worker node & create its .env file

**Example:** to label a worker node for the first join participant:
```
docker node update --label-add join1=true <WORKER_NODE_ID_1>
```

Then create a file configs/join1.env:
```
NODE_LABEL=join1
KEY_NAME=join-1

SEED_NODE_RPC_URL=http://genesis_node:26657
SEED_NODE_P2P_URL=http://genesis_node:26656
SEED_API_URL=http://genesis_api:8080

PUBLIC_URL=http://join1_api:8080
POC_CALLBACK_URL=http://join1_api:8080
```

You can create any amount of workers this way.

### 5. Deploy participants

**Example:** to deploy a first participant:
```
set -a && source configs/join1.env && set +a && \
    docker stack deploy -c docker-compose.join.yml join1
```


Repeat for `join2`, `join3`, etc. Label more nodes as `join2=true`, create `configs/join2.env`, then deploy with:
```
docker stack deploy -c docker-compose.join.yml --env-file configs/join2.env join2
```

---

## Using deploy.sh

For convenience, you can just run the provided deploy.sh script:

```
./deploy.sh
```

It does the following automatically:
- Removes existing "genesis" / "join*" labels from all nodes.
- Picks the first manager node to label genesis=true.
- Labels each worker node sequentially as join1=true, join2=true, etc.
- Generates corresponding configs/join1.env, configs/join2.env, etc.
- Deploys the genesis stack.
- Deploys each "joinX" stack for each labeled worker.


After this completes, you'll have:
- genesis stack running on the manager node,
- join1 stack on your first worker, join2 on the second worker, and so on.

You can verify by checking:
```
docker stack services genesis
docker stack services join1
docker stack services join2
...
```


*! [WIP]: Might be potentiall issue with cleaning volumes between restart.*