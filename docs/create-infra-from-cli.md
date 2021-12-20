# Use the command-line to create the IMC's dependencies

The IMC is dependent on a GKE cluster and GCP services. They may be created from the command-line using the `gcloud` command (alternatively, you may use the [Terraform](/docs/create-infra-from-terraform.md)).

To see a full list of the resources that are required, see the [Infrastructure Inventory](/docs/infra-inventory.md) doc.

#### Authenticate with Google

Once your `gcloud` prerequisites are installed, log into Google before running any `ansible` commands:

```sh
gcloud auth login
gcloud auth application-default login
```

#### Bootstrap Script

We provide a bootstrap script that can be ran in place of the following commands if desired. To run it run the following command:
```sh
./resources/bootstrap-infra.sh
```

You will be prompted to supply various information needed to configure your infrastructure. We advise you review the script before running it so you are familiar with what it will do. It can be found [here](../resources/bootstrap-infra.sh).


## Create a Kubernetes cluster

Create a new Google Kubernetes Engine (GKE) cluster from the command line:

If you intend to use a non-default VPC then you will need to specify the `--network` and `--subnetwork` flags with the following command. For more information see [the offical `gcloud` documentation](https://cloud.google.com/sdk/gcloud/reference/beta/container/clusters/create).

```sh
export CLUSTER='imc'
export GCP_PROJECT_ID='imc-project'
export ZONE='us-central1-a'
export CLUSTER_VERSION='1.21.5-gke.1302'
export MACHINE_TYPE='e2-custom-4-12288'
export IMAGE_TYPE='UBUNTU_CONTAINERD'
export DISK_TYPE='pd-standard'
export DISK_SIZE=100
export NUM_NODES=2
export DEFAULT_MAX_PODS_PER_NODE=110
export GKE_IP_WHITELIST='8.8.8.8/32,8.8.4.4/32'
export SCOPES="https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append"

gcloud beta container \
    --project "${GCP_PROJECT_ID}" \
    clusters create "${CLUSTER}" \
    --zone "${ZONE}" \
    --cluster-version="${CLUSTER_VERSION}" \
    --release-channel "regular" \
    --machine-type "${MACHINE_TYPE}" \
    --image-type "${IMAGE_TYPE}" \
    --disk-type "${DISK_TYPE}" \
    --disk-size "${DISK_SIZE}" \
    --scopes "${SCOPES}" \
    --num-nodes "${NUM_NODES}" \
    --logging=SYSTEM,WORKLOAD \
    --monitoring=SYSTEM \
    --enable-ip-alias \
    --no-enable-intra-node-visibility \
    --default-max-pods-per-node "${DEFAULT_MAX_PODS_PER_NODE}" \
    --no-enable-master-authorized-networks \
    --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver \
    --enable-autoupgrade \
    --enable-autorepair \
    --max-surge-upgrade 1 \
    --max-unavailable-upgrade 0 \
    --enable-shielded-nodes \
    --node-locations "${ZONE}"
```

## Create the GCP services

The following section walks you through how to create the IMC's required GCP services from the command-line.

### Enable the required GCP APIs

```sh
gcloud services enable --project=${GCP_PROJECT_ID} \
    cloudresourcemanager.googleapis.com \
    compute.googleapis.com \
    container.googleapis.com \
    iam.googleapis.com \
    logging.googleapis.com \
    monitoring.googleapis.com \
    pubsub.googleapis.com \
    servicenetworking.googleapis.com \
    sqladmin.googleapis.com \
    storage-component.googleapis.com \
    storagetransfer.googleapis.com
```

### Create the Cloud Storage buckets

```sh
gsutil mb -p ${GCP_PROJECT_ID} "gs://imc-data-${GCP_PROJECT_ID}"
gsutil cors set resources/gs-bucket-cors.json "gs://imc-data-${GCP_PROJECT_ID}"

gsutil mb -p ${GCP_PROJECT_ID} "gs://imc-vault-${GCP_PROJECT_ID}"
gsutil versioning set on "gs://imc-vault-${GCP_PROJECT_ID}"
```

### Create Pub/Sub topics

```sh
gcloud pubsub topics create input-messages \
    --labels=env=imc,service=pubsub \
    --project=${GCP_PROJECT_ID}
```

### Create Cloud KMS

```sh
gcloud kms keyrings create imc-vault-kr --location global --project ${GCP_PROJECT_ID}
gcloud kms keys create imc-vault-unseal --location global --keyring imc-vault-kr --purpose encryption --project ${GCP_PROJECT_ID}
```

### Create Cloud public IP addresses

```sh
export GCP_REGION='us-central1'
gcloud compute addresses create imc-ingress-ip --region ${GCP_REGION} --project ${GCP_PROJECT_ID}
gcloud compute addresses create imc-remote-ip --region ${GCP_REGION} --project ${GCP_PROJECT_ID}
```

### Setup DNS

IMC requires domain name for ingress. This is a requiremnt for GCP OAuth consent screen

Get public IP address and set up DNS provider accordingly

```
gcloud compute addresses describe imc-ingress-ip --region ${GCP_REGION} --project ${GCP_PROJECT_ID}
```


### Setup GCP OAuth consent screen

TBD

### Setup GCP OAuth client

TBD

### Create Service account for IMC

```sh
export IMC_SA_NAME='imc-app'
gcloud iam service-accounts create ${IMC_SA_NAME} --display-name "IMC application service account" --project ${GCP_PROJECT_ID}
gsutil iam ch serviceAccount:${IMC_SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com:objectAdmin gs://imc-vault-${GCP_PROJECT_ID}
gcloud kms keys add-iam-policy-binding imc-vault-unseal --location global --keyring imc-vault-kr --member serviceAccount:${IMC_SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com \
    --role roles/cloudkms.cryptoKeyEncrypterDecrypter --project ${GCP_PROJECT_ID}
gsutil iam ch serviceAccount:${IMC_SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com:roles/storage.admin gs://imc-data-${GCP_PROJECT_ID}    
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${IMC_SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" --role='roles/cloudiot.admin'
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${IMC_SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" --role='roles/cloudsql.client'
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${IMC_SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" --role='roles/pubsub.serviceAgent'
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${IMC_SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" --role='roles/pubsub.admin'
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${IMC_SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" --role='roles/secretmanager.secretAccessor'
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${IMC_SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" --role='roles/iam.serviceAccountAdmin'
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${IMC_SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" --role='roles/iam.serviceAccountKeyAdmin'
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${IMC_SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" --role='roles/iam.serviceAccountTokenCreator'
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${IMC_SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" --role='roles/viewer'
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${IMC_SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" --role='roles/pubsub.publisher'
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${IMC_SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" --role='roles/pubsub.subscriber'
```

## Pre-setup Kubernets cluster

### Generate credentials

```sh
gcloud container clusters get-credentials ${CLUSTER} --zone ${ZONE} --project ${GCP_PROJECT_ID}
```

### Create kubernets namespace

```sh
export NAMESPACE=imc
kubectl create namespace ${NAMESPACE}
```

### Create a secret with service account key

```sh
gcloud iam service-accounts keys create --project ${GCP_PROJECT_ID} --iam-account ${IMC_SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com imc_sa_key.json
kubectl -n ${NAMESPACE} create secret generic imc-sa-key --from-file=imc_sa_key.json
rm -f imc_sa_key.json
```

### Create a secret with vault configuration

```sh
cat <<EOF >>config.hcl
ui = true
listener "tcp" {
  tls_disable = 1
  address = "[::]:8200"
  cluster_address = "[::]:8201"
}
storage "gcs" {
  bucket = "imc-vault-${GCP_PROJECT_ID}"
}
seal "gcpckms" {
  project     = "${GCP_PROJECT_ID}"
  region      = "global"
  key_ring    = "imc-vault-kr"
  crypto_key  = "imc-vault-unseal"
}
EOF

kubectl create secret -n $NAMESPACE generic vault-storage-config --from-file=config.hcl
rm -f config.hcl
```

### Generate a secret with self-signed ssl certificate for ingress

```sh
export DOMAIN_NAME=imc.domain.com
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ingress_private_key.pem  -out ingress-cert.pem -subj "/CN=${DOMAIN_NAME}"
kubectl create -n ${NAMESPACE} secret tls imc-tls --key ingress_private_key.pem --cert ingress-cert.pem
rm -f ingress_private_key.pem ingress-cert.pem
```

### Print values for deployment IMC via Google Cloud Marketplace

```sh
INGRESS_LB_IP=$(gcloud compute addresses describe imc-ingress-ip --region ${GCP_REGION} --project ${GCP_PROJECT_ID} --format="value(address)")
REMOTE_LB_IP=$(gcloud compute addresses describe imc-remote-ip --region ${GCP_REGION} --project ${GCP_PROJECT_ID} --format="value(address)")
echo "name=lem"
echo "namespace=${NAMESPACE}"
echo "ingress.host=${DOMAIN_NAME}"
echo "nginx-ingress-controller.service.loadBalancerIP=${INGRESS_LB_IP}"
echo "global.lbRemoteIp=${REMOTE_LB_IP}"
```
