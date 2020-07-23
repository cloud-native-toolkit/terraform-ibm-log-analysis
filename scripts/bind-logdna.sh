#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
MODULE_DIR=$(cd ${SCRIPT_DIR}/..; pwd -P)

CLUSTER_ID="$1"
INSTANCE_ID="$2"
INGESTION_KEY="$3"

set -e

ibmcloud ob logging config create \
  --cluster "${CLUSTER_ID}" \
  --instance "${INSTANCE_ID}" \
  --logdna-ingestion-key "${INGESTION_KEY}"
