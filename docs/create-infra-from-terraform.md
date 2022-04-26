# Use the command-line to create the IMC's dependencies

## 1 Pre-Requisites and environment preparation

For deployment of the IMC, the prerequisites described in the subchapters below need to be fulfilled.
Please prepare the required GCP variables.

```sh
export PROJECTID="customer-imcproject-h123" # ProjectID we will use for the creation
export GCP_ORGID="123456789012"              # Id of your organisation
export GCP_FOLDERID="123456789012"         # or alternatively ID of an GCP org folder 
export BILLING_ACCOUNT_ID="123-123-123"      # to be used by the IMC project
export LOCATION="us"                           # We recomend to use EU or US
export IMC_DOMAIN_NAME="domain.com"
```

### 1.1 Access to a command line interface with *Google Cloud SDK (gcloud)* installed.

We recommend using [Google Cloud Shell](https://cloud.google.com/shell/docs/using-cloud-shell).
 
***Note for CloudShell:*** Please check and upgrade if needed your local packages by running:
```sh
# IMC Deployment Step 1.1

sudo apt-get update
sudo apt-get upgrade
```

If you prefer to install **Google Cloud SDK (gcloud)** on your local machine please follow the [Cloud SDK installation documentation](https://cloud.google.com/sdk/docs/install).

#### 1.2 Working connectivity and authentication between gcloud (terminal) and GCP, set organisational variables 
Please verify that the connectivity between the gcloud command and the Cloud is working by executing this command in your shell:

```sh
# IMC Deployment Step 1.2

gcloud init
```
If requested, please login and authorize your terminal to connect to your GCP organisation.

### 1.3 Boostraping **GCP project** (new & dedicated for IMC)
You can create new project from the command line by using commands below. The script will set up default region variables based on selected loaction, 
it will create the project and link it to given billing account

```sh
# IMC Deployment Step 4.1.3

# proposed regions with highest relevant service coverage on given continent
if [ $LOCATION = "europe" ]; then
  export REGION="europe-west1"
  export ZONE="europe-west1-d"
elif [ $LOCATION = "us" ]; then
  export REGION="us-central1"
  export ZONE="us-central1-f"
elif [ $LOCATION = "asia" ]; then
  export REGION="asia-east1"
  export ZONE="asia-east1-c"
fi

if [ -z ${GCP_FOLDERID+x} ]; then 
  gcloud projects create ${PROJECTID} --organization ${GCP_ORGID} ; 
else 
  gcloud projects create ${PROJECTID} --folder ${GCP_FOLDERID} 
fi

# switch to the project
gcloud config set project ${PROJECTID}
 
# link billing account to project
gcloud beta billing projects link ${PROJECTID} --billing-account ${BILLING_ACCOUNT_ID}

gcloud services enable compute.googleapis.com 

gcloud compute project-info add-metadata \
    --metadata google-compute-default-region="${REGION}",google-compute-default-zone="${ZONE}"

```

### 1.4 **ServiceAccount**
  
We recommend creating a service accounts in the IMC project:
* **imc-terraform** - used for execution of the infrastructure as a code (IaaC) scripts

**Note:** You can create the account using the command line below.

```sh
# IMC Deployment Step 1.4

export SA_TERRAFORM="imc-tf"
gcloud iam service-accounts create $SA_TERRAFORM --display-name "IMC Terraform deployment account" --project ${PROJECTID}
gcloud projects add-iam-policy-binding ${PROJECTID} --member="serviceAccount:${SA_TERRAFORM}@${PROJECTID}.iam.gserviceaccount.com" --role="roles/compute.securityAdmin"
gcloud projects add-iam-policy-binding ${PROJECTID} --member="serviceAccount:${SA_TERRAFORM}@${PROJECTID}.iam.gserviceaccount.com" --role="roles/container.admin"
gcloud projects add-iam-policy-binding ${PROJECTID} --member="serviceAccount:${SA_TERRAFORM}@${PROJECTID}.iam.gserviceaccount.com" --role="roles/iam.serviceAccountAdmin"
gcloud projects add-iam-policy-binding ${PROJECTID} --member="serviceAccount:${SA_TERRAFORM}@${PROJECTID}.iam.gserviceaccount.com" --role="roles/iam.serviceAccountUser"
gcloud projects add-iam-policy-binding ${PROJECTID} --member="serviceAccount:${SA_TERRAFORM}@${PROJECTID}.iam.gserviceaccount.com" --role="roles/pubsub.admin"
gcloud projects add-iam-policy-binding ${PROJECTID} --member="serviceAccount:${SA_TERRAFORM}@${PROJECTID}.iam.gserviceaccount.com" --role="roles/resourcemanager.projectIamAdmin"
gcloud projects add-iam-policy-binding ${PROJECTID} --member="serviceAccount:${SA_TERRAFORM}@${PROJECTID}.iam.gserviceaccount.com" --role="roles/secretmanager.admin"
gcloud projects add-iam-policy-binding ${PROJECTID} --member="serviceAccount:${SA_TERRAFORM}@${PROJECTID}.iam.gserviceaccount.com" --role="roles/secretmanager.secretVersionManager"
gcloud projects add-iam-policy-binding ${PROJECTID} --member="serviceAccount:${SA_TERRAFORM}@${PROJECTID}.iam.gserviceaccount.com" --role="roles/storage.admin"

**Note:** In case you would like to use impersonated service accounts instead of key authentication, please follow the "[Impersonating Service Accounts instructions](https://cloud.google.com/iam/docs/impersonating-service-accounts#iam-service-accounts-grant-role-parent-gcloud)"


### 1.5 **Terraform** CLI tools

We will use Terraform (1.0.9+) for the provisioning of the solution infrastructure. Terraform can be installed in your local project folder with code below, or in case you prefer installation for all users - you can follow [manual installation instructions](https://www.terraform.io/downloads.html) or [installation using packet management apt](https://www.terraform.io/docs/cli/install/apt.html).

```sh
# IMC Deployment Step 1.5

mkdir -p ~/projects/$PROJECTID/bin
cd ~/projects/$PROJECTID/bin

export TERRAFORM_VERSION="1.1.3"
wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

export PATH="~/projects/$PROJECTID/bin:$PATH"
cd ~/projects/$PROJECTID

#verify the version
terraform -v
```

### 1.6 **Kubernetes** CLI tools (optional)
If you are running these commands usign CloudShell, you can skip this step.
The deployment of the Kubernetes CLI tools is optional, since the deployment script doesn't use it. However, they may be useful for troubleshooting purposes.
```sh
# IMC Deployment Step 1.6
 
cd ~/projects/$PROJECTID/bin
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl

#verify the version
kubectl version --client

```

### 1.7 **Enable the impersonation core services**
To be able to generate service tokens for the impersonated service accounts, the IAM credentials and the resource manager services must be enabled on the project. You can enable those services by running the below command

```shell
# IMC Deployment Step 1.7

gcloud services enable iamcredentials.googleapis.com cloudresourcemanager.googleapis.com
```

### 1.8 **Enterprise environments with restricted permissions of project owner**
The steps below are usually done by the Terraform scripts during execution - and for standard environments you don't need to care about. 
These hints are intended for enterprise organisations with restrictive permissions especially when the Terraform service account will not have rights to enable Service APIs or create network resources.

In case the ***roles/serviceusage.serviceUsageAdmin*** role cannot be assigned to Terraform service account (SA_TERRAFORM), the required APIs will need to be enabled for the IMC project prior to the deployment.
You can use the command below to enable the required APIs by account with higher privileges.

```sh
# IMC Deployment Step 1.8
# enable services defined in terraform/modules/api-services/variables.tf

gcloud services enable cloudapis.googleapis.com \
cloudbuild.googleapis.com \
container.googleapis.com \
containerregistry.googleapis.com \
sqladmin.googleapis.com \
pubsub.googleapis.com \
logging.googleapis.com \
compute.googleapis.com \
iam.googleapis.com \
iamcredentials.googleapis.com \
cloudiot.googleapis.com \
dns.googleapis.com \
servicenetworking.googleapis.com \
deploymentmanager.googleapis.com \
oslogin.googleapis.com

gcloud services enable sql-component.googleapis.com \
storage-component.googleapis.com \
storage.googleapis.com \
storage-api.googleapis.com \
cloudtrace.googleapis.com \
secretmanager.googleapis.com \
sts.googleapis.com \
servicemanagement.googleapis.com \
monitoring.googleapis.com \
run.googleapis.com \
cloudresourcemanager.googleapis.com

 
```
 
### 1.9 Setup OAuth Consent screen

TBD

### 1.10 Setup OAuth client

TBD

### 1.11 IMC deployment

Next we will save the information into a shell environment configuration file (setup.sh), we will use during the deployment. You can create this by running the command below:
```sh
cd ~/projects/$PROJECTID
  
cat <<EOF >~/projects/$PROJECTID/setup.sh
#!/bin/sh
# Created on $(date) by ${USER}

export REGION="${REGION}"
export LOCATION="${LOCATION}" 
export PROJECTID="${PROJECTID}"
export SA_TERRAFORM="${SA_TERRAFORM}"

gcloud config set project \$PROJECTID

export PROJECTNAME="`gcloud projects describe \${PROJECTID} --format="value(name)"`"
export PROJECTNUMBER=`gcloud projects describe \${PROJECTID} --format="value(projectNumber)"`

export SA_TERRAFORM_NAME="${SA_TERRAFORM}@${PROJECTID}.iam.gserviceaccount.com"

export KUBE_CONFIG_PATH=~/.kube/config
export PATH="~/projects/$PROJECTID/bin:$PATH"
cd ~/projects/$PROJECTID

EOF
 
chmod +x setup.sh
# load the exported variables into current session
. ./setup.sh

```

Once the above script is executed, you can now create a default application credentials using the account that has the ability to impersonate the SA_TERRAFORM service account. It can be done by running the following command

```shell
gcloud auth application-default login
```

```sh
# IMC Deployment Step 1.1.12

cat <<EOF >~/projects/$PROJECTID/input.tfvars
# Created on $(date) by ${USER}

imc_project_id = "${PROJECTID}"
imc_region = "${REGION}"
imc_zone = "${ZONE}"
create_imde_pubsub_topic = false
imc_domain_name = "${IMC_DOMAIN_NAME}"

EOF
```

### IMC Deployment Step 1.1.12

```sh

cd ~/projects/$PROJECTID
git clone https://github.com/litmusautomation/imc-gcp-marketplace.git

cd ~/projects/$PROJECTID/
```

# IMC Deployment Step 1.1.13

```
cd  ~/projects/$PROJECTID/imc-gcp-marketplace/resources/terraform

terraform init
```

#### 1.1.14. Terraform plan: It creates an execution plan that:
* Reads the current state of any already-existing remote objects to make sure that the Terraform state is
  up-to-date.
* Compares the current configuration to the prior state and noting any differences.

The plan command alone will not actually carry out the proposed changes, and so you can use this command to check whether the proposed changes match what you expected before you apply the changes.
```sh
# IMC Deployment Step 1.1.15

terraform plan -var-file=~/projects/$PROJECTID/imc-gcp-marketplace/input.tfvars  -out=tfplan
```

#### 1.1.15. Terraform apply: The apply command executes the actions proposed in a Terraform plan.
```sh
# IMC Deployment Step 1.1.15

terraform apply -auto-approve tfplan
```
The initial execution of terraform scripts will take about 10min.
