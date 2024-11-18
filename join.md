# Join Network as participant 

## Get Containers

Docker images are available in PS private GCP container registry.  
If you have PS account or PS has provided you with access, you need to authenticate in `gcloud` and configure docker to access them.

1. Run `gcloud auth login` and login with your account credentials
2. Run `gcloud auth configure-docker`


## Download Files

Let's create a directory decentralized-ai and download configuration files there:

```bash
mkdir decentralized-ai
cd decentralized-ai

curl https://raw.githubusercontent.com/product-science/pivot-deploy/refs/heads/main/join/config.env -o config.env
curl https://raw.githubusercontent.com/product-science/pivot-deploy/refs/heads/main/join/launch_chain.sh -o launch_chain.sh
curl https://raw.githubusercontent.com/product-science/pivot-deploy/refs/heads/main/join/docker-compose-cloud-join.yml -o docker-compose-cloud-join.yml
curl https://raw.githubusercontent.com/product-science/pivot-deploy/refs/heads/main/join/node-config.json -o node-config.json
```


## Configure your Node

Edit `config.env` file and set your node name, public URL and other parameters.
- `KEY_NAME` - name of your node. It should be unique
- `PORT` - port where your node will be available (default is 8080)
- `PUBLIC_URL` - public URL where your node will be available (e.g.: `http://<your-static-ip>:<port>`)

In `node-config.json` you can set the information about the inference nodes. Each node is described by the following fields:
```
"id": "node1",
"url": `http://<inference-node-static-ip>:<port>`,
"max_concurrent": 500,
"models": [
    "model_name1",
]
```

If network node and inference node are running on the same machine, you don't need to change anything.

## Run your Node

Run `launch_chain.sh` script to start your node.

```bash
./launch_chain.sh cloud
```
