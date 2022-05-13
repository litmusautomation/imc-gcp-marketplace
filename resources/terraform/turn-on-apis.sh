#!/bin/bash

[ -n "$GCP_PROJECT_ID" ] || read -p "Enter GCP project name: " GCP_PROJECT_ID

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
    storagetransfer.googleapis.com \
    cloudiot.googleapis.com