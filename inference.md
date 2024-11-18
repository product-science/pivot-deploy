# Inference

This instruction describes how to create a user account and how to make the inference request.

## Prerequisites

To interact with the network you need an `inferenced` cli tool.  
Right now it's available from the docker image: `gcr.io/decentralized-ai/inferenced-join`.

### **[COMMING SOON]** Install binary

### Get docker image

If you have PS account or PS has provided you with access, you need to authenticate in `gcloud` and configure docker to access the image.

1. Install and setup `docker` according to the [official guide](https://docs.docker.com/get-docker/)
2. Run `gcloud auth login` and login with your account credentials
3. Run `gcloud auth configure-docker` to add GCP's artifactory to the docker configuration
4. Run `docker pull gcr.io/decentralized-ai/inferenced-join` to download the image

### Create a directory for your account

1. Create a directory which will contain your keys: `mkdir .inference`
2. Create a directory for files with requests: `mkdir requests-payloads`


- All commands below are provided for the case of using `inferenced` from docker container.  
- If your `.inference` and `requests-payloads` are placed not in the current directory, you need to modify paths to local volumes.


## Create an account

Account can be created with the following command:
```bash
docker run -it --rm \
    -v ./.inference:/root/.inference \
    -v ./inference-requests:/root/inference-requests \
    gcr.io/decentralized-ai/inferenced-join \
    inferenced \
    create-client \
    <account-name> \
    --node-address <node-address>
```

The command will create a new account and save the keys to the `.inference` directory.

Please save the account address from lines:
```bash
- address: <account-address>
  name: <account-name>
  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"..."}'
  type: local
```
## Make a inference request

```bash
docker run -it --rm \
    -v ./.inference:/root/.inference \
    -v ./inference-requests:/root/inference-requests \
    gcr.io/decentralized-ai/inferenced-join \
    inferenced \
    signature \
    send-request \
    --account-address <account-address> \
    --node-address http://34.72.225.168:8080 \
    --file /root/inference-requests/request_payload.json
```
