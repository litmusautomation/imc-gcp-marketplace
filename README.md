
Intelligent Manufacturing Connect is an integrated edge-to-cloud Industrial IoT platform that provides everything you need to put industrial data to work to enable smart manufacturing. The solution is purpose-built to collect, process and analyze data at the edge, then rapidly integrate the data with the Google Cloud Platform for analytics, AI and machine learning. 

This document is a guide to install the IMC in Google Cloud Platform (GCP).

# Install the IMC

To install the IMC, you must first create the GCP services on which the IMC depends. Once the GCP services are created, you will deploy the IMC from the Google Cloud Marketplace.

> **Note:** the Kubernetes cluster, GCP services, and IMC application should all live in the same GCP project.

#### 1. Create required GCP infrastructure

The IMC's services are deployed into a Kubernetes cluster. The cluster must be created before deploying the IMC from the Google Cloud Marketplace.

The IMC's services also depend on GCP services, such as CloudSQL and CloudStorage. The GCP services must be created before deploying the IMC from the Google Cloud Marketplace.

> **NOTE:** `gcloud` version `330.0.0` or higher is required for the following steps.

To create all of these resources, we offer three options:



* Use our [bootstrap script](/docs/create-infra-from-cli.md#bootstrap-script), which creates everything in a single script
* Use the command-line interface ([kubernetes cluster](/docs/create-infra-from-cli.md#create-a-kubernetes-cluster) | [GCP services](/docs/create-infra-from-cli.md#create-the-gcp-services]))
* Use the Terraform ([kubernetes cluster](/docs/create-infra-from-terraform.md))

You may also want to review [the full inventory of GCP service dependencies](/docs/infra-inventory.md).

#### 2. Deploy the IMC via Google Cloud Marketplace

After you've created a Kubernetes cluster and the GCP service dependencies, you can [deploy the IMC from the Google Cloud Marketplace](https://console.cloud.google.com/marketplace/details/litmus-public/intelligent-manufacturing-connect). Associate your IMC purchase with a valid billing account and then follow the on-screen instructions.

Once finished, review the post installation steps below.

# Uninstall the IMC

#### Via the Google Cloud console

Use the Google Cloud Platform console to uninstall the IMC.

1.  In the GCP Console, open your
    [Kubernetes applications](https://console.cloud.google.com/Kubernetes/application).
2.  From the list of applications, click **`IMC`**.
3.  On the Application Details page, click **`Delete`**.

#### Via the command-line

You may also uninstall the IMC via the command-line.

**Prepare the environment**

Set your installation name and Kubernetes namespace:

```sh
export NAMESPACE='imc'
export APP_NAME='lem'
```

**Delete the resources**

To delete the resources, use the expanded manifest file used for the installation.

> **NOTE:**
> We recommend using a `kubectl` version that is the same as the
> version of your cluster. Using the same versions of `kubectl` and the cluster
> helps avoid unforeseen issues.

Run `kubectl` on the expanded manifest file:

```sh
kubectl delete -f ${APP_NAME}_manifests.yaml --namespace ${NAMESPACE}
```

If you don't have the expanded manifest, delete the resources using types and a label:

```sh
kubectl delete application,configmap,deployment,horizontalpodautoscaler,ingress,job,secret,service,statefulset \
    --namespace ${NAMESPACE} \
    --selector app.Kubernetes.io/name=${APP_NAME}
```

**Delete the PersistentVolumeClaims**

By design, removing StatefulSets in Kubernetes does not remove `PersistentVolumeClaims` that were attached to their pods. This prevents your installations from accidentally deleting stateful data.

To remove the `PersistentVolumeClaims` with their attached persistent disks, run the following `kubectl` commands:

```sh
# specify the variables values matching your installation:
export APP_NAME='lem'
export NAMESPACE='imc'

kubectl delete persistentvolumeclaims \
  --namespace ${NAMESPACE}
  --selector app.Kubernetes.io/name=${APP_NAME}
```
