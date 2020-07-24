#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
MODULE_DIR=$(cd ${SCRIPT_DIR}/..; pwd -P)

CLUSTER_ID="$1"
INSTANCE_NAME="$2"
INGESTION_KEY="$3"

echo "Configuring LogDNA for ${CLUSTER_ID} cluster and ${INSTANCE_NAME} LogDNA instance"

ibmcloud target
if ibmcloud ob logging config ls --cluster "${CLUSTER_ID}" | grep -q "Instance name"; then
  EXISTING_INSTANCE_NAME=$(ibmcloud ob logging config ls --cluster "${CLUSTER_ID}" | grep "Instance name" | sed -E "s/Instance name: +([^ ]+)/\1/g")
  if [[ "${EXISTING_INSTANCE_NAME}" == "${INSTANCE_NAME}" ]]; then
    echo "LogDNA configuration already exists on this cluster"
    exit 0
  else
    echo "Existing LogDNA configuration found on this cluster for a different LogDNA instance: ${EXISTING_INSTANCE_NAME}."
    echo "Removing the config before creating the new one"
    ibmcloud ob logging config delete \
      --cluster "${CLUSTER_ID}" \
      --instance "${EXISTING_INSTANCE_NAME}" \
      --force
  fi
else
  echo "No existing logging config found for ${CLUSTER_ID} cluster"
  ibmcloud ob logging config ls --cluster "${CLUSTER_ID}"
fi

set -e

echo "Creating LogDNA configuration for ${CLUSTER_ID} cluster and ${INSTANCE_NAME} LogDNA instance"
ibmcloud ob logging config create \
  --cluster "${CLUSTER_ID}" \
  --instance "${INSTANCE_NAME}" \
  --logdna-ingestion-key "${INGESTION_KEY}"
