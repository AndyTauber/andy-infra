#!/usr/bin/env bash

set -eux

PROJECT=${PROJECT:-prow-open-btr}
LOCATION=${LOCATION:-us-west1-a}
CLUSTER_NAME=${CLUSTER_NAME:-prow-service}

bash <(curl -sSfL https://raw.githubusercontent.com/kubernetes/test-infra/master/workload-identity/enable-workload-identity.sh) "${PROJECT}" "${LOCATION}" "${CLUSTER_NAME}"
