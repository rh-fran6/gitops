#!/bin/bash

set -eo pipefail

export TRUST_POLICY_FILE="TrustPolicy.json"
export POLICY_FILE="s3Policy.json"
export SCRATCH_DIR="./"
export CLUSTER_NAME="dd-rosa"
export ESO_SA_NAME="aws-secret-manager-sa"
export ESO_NAMESPACE="external-secrets-operator"
export CLUSTERSECRETSTORE="akv-cluster-secret-read"


ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

POLICY_NAME="${CLUSTER_NAME}-iam-secret-policy"
ROLE_NAME="${CLUSTER_NAME}-iam-secret-role"

# Function to print error message and exit
handle_error() {
    echo "An error occurred. Exiting..."
    exit 1
}

# Trap errors and handle them using the handle_error function
trap handle_error ERR

# Grab policy ARN
echo "Retrieving IAM policy ARN..."
POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='${POLICY_NAME}'].Arn" --output text) || true

if [[ -z "$POLICY_ARN" ]]; then
    echo "Policy $POLICY_NAME not found. "
fi

# Deleting policy files from directory
echo "Deleting json files from local directory..."
rm -rf *.json

# Detach policy from role
echo "Detaching IAM policy from role..."
aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY_ARN" || true

# Delete IAM role
echo "Deleting IAM role..."
aws iam delete-role --role-name "$ROLE_NAME" || true

# Delete IAM policy
echo "Deleting IAM policy..."
aws iam delete-policy --policy-arn "$POLICY_ARN" || true


# Deleting secret
echo "Deleting Service Account..."
oc delete serviceaccount $ESO_SA_NAME -n $ESO_NAMESPACE || true

# Deleting ClusterSecretStore
echo "Deleting ClusterSecretStore..."
oc delete clustersecretstore $CLUSTERSECRETSTORE || true


clear

# Output success message
echo "Cleanup completed successfully."