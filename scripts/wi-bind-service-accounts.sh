#!/usr/bin/env bash

set -eux

PROJECT=${PROJECT:-prow-open-btr}
LOCATION=${LOCATION:-us-west1-a}
CLUSTER_NAME=${CLUSTER_NAME:-prow-service}
PROW_NAMESPACE=${PROW_NAMESPACE:-prow}
GCP_SERVICE_ACCOUNT=${GCP_SERVICE_ACCOUNT:-control-plane}

function svc_acct_email() {
    if [ $# != 2 ] || [ -z "$1" ] || [ -z "$2" ]; then
        echo "svc_acct_email(project, name) requires 2 arguments" >&2
        return 1
    fi
    local project="$1"
    local name="$2"
    echo "${name}@${project}.iam.gserviceaccount.com"
}

email=$(svc_acct_email "${PROJECT}" "${GCP_SERVICE_ACCOUNT}")

if ! gcloud iam service-accounts --project "${PROJECT}" describe "${email}" >/dev/null 2>&1; then
    gcloud iam service-accounts create \
      --project "${PROJECT}" \
      "${GCP_SERVICE_ACCOUNT}" \
      --display-name="Prow control plane"
fi

if ! kubectl get serviceaccount/marnaud-sa -n "$PROW_NAMESPACE" --no-headers -o custom-columns=name:.metadata.name; then
    kubectl create serviceaccount --namespace "$PROW_NAMESPACE" marnaud-sa
    kubectl patch serviceaccount --namespace "$PROW_NAMESPACE" marnaud-sa -p '{"metadata": {"annotations": {"iam.gke.io/gcp-service-account": "control-plane@prow-open-btr.iam.gserviceaccount.com"}}}'
fi

echo "Ensure ${GCP_SERVICE_ACCOUNT} service account is GKE cluster admin"
gcloud projects add-iam-policy-binding $"{PROJECT}" --member "serviceAccount:${email}" --role "roles/container.clusterAdmin"

#bash <(curl -sSfL https://raw.githubusercontent.com/kubernetes/test-infra/master/workload-identity/bind-service-accounts.sh) "${PROJECT}" "${LOCATION}" "${CLUSTER_NAME}" "${PROW_NAMESPACE}" "marnaud-sa" "${email}"

echo "Workload Identity for crier"
bash <(curl -sSfL https://raw.githubusercontent.com/kubernetes/test-infra/master/workload-identity/bind-service-accounts.sh) "${PROJECT}" "${LOCATION}" "${CLUSTER_NAME}" "${PROW_NAMESPACE}" "crier" "${email}"

echo "Workload Identity for deck"
bash <(curl -sSfL https://raw.githubusercontent.com/kubernetes/test-infra/master/workload-identity/bind-service-accounts.sh) "${PROJECT}" "${LOCATION}" "${CLUSTER_NAME}" "${PROW_NAMESPACE}" "deck" "${email}"

echo "Workload Identity for hook"
bash <(curl -sSfL https://raw.githubusercontent.com/kubernetes/test-infra/master/workload-identity/bind-service-accounts.sh) "${PROJECT}" "${LOCATION}" "${CLUSTER_NAME}" "${PROW_NAMESPACE}" "hook" "${email}"

echo "Workload Idendity for prow-controlller-manager"
bash <(curl -sSfL https://raw.githubusercontent.com/kubernetes/test-infra/master/workload-identity/bind-service-accounts.sh) "${PROJECT}" "${LOCATION}" "${CLUSTER_NAME}" "${PROW_NAMESPACE}" "prow-controller-manager" "${email}"

echo "Workload Identity for sinker"
bash <(curl -sSfL https://raw.githubusercontent.com/kubernetes/test-infra/master/workload-identity/bind-service-accounts.sh) "${PROJECT}" "${LOCATION}" "${CLUSTER_NAME}" "${PROW_NAMESPACE}" "sinker" "${email}"
