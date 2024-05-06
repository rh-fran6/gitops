#!/bin/bash

set -eo pipefail


export TRUST_POLICY_FILE="TrustPolicy.json"
export POLICY_FILE="s3Policy.json"
export SCRATCH_DIR="./"
export CLUSTER_NAME="dd-rosa"
export ESO_SA_NAME="aws-secret-manager-sa"
export ESO_NAMESPACE="external-secrets-operator"
export CLUSTERSECRETSTORE="akv-cluster-secret-read"

# Function to extract AWS account ID
get_account_id() {
    aws sts get-caller-identity --query Account --output text
}

get_aws_region() {
    aws configure get region
}

# Function to extract OIDC Provider endpoint
get_oidc_provider_endpoint() {
    rosa describe cluster -c "$(oc get clusterversion -o jsonpath='{.items[].spec.clusterID}{"\n"}')" -o yaml | awk '/oidc_endpoint_url/ {print $2}' | cut -d '/' -f 3,4
}

# Function to create IAM role
create_iam_role() {
    local a="$1"
    aws iam create-role --role-name "$a-iam-secret-role" --assume-role-policy-document file://$TRUST_POLICY_FILE --query "Role.Arn" --output text
}

# Function to create IAM policy
create_iam_policy() {
    local a=$1
    aws iam create-policy --policy-name "$a-iam-secret-policy" --policy-document file://$POLICY_FILE --query 'Policy.Arn' --output text
}

# Function to attach IAM policy to role
attach_policy_to_role() {
    local a=$1
    local b=$2
    aws iam attach-role-policy --role-name $a --policy-arn $b
}

# Extract Account ID
AWS_ACCOUNT_ID=$(get_account_id || true)
echo AWS Account ID: $AWS_ACCOUNT_ID

# Extract AWSRegion
AWS_REGION=$(get_aws_region || true)
echo AWS Region: $AWS_REGION

# Extract OIDC Provider endpoint
OIDC_PROVIDER_ENDPOINT=$(get_oidc_provider_endpoint || true)
echo "OIDC Provider Endpoint: $OIDC_PROVIDER_ENDPOINT"

# Create IAM policy
echo "Creating policy file $POLICY_FILE in local directory..."
cat <<EOF > "${SCRATCH_DIR}/$POLICY_FILE"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue"
            ] ,
            "Resource": "*"
        }
    ]
}
EOF

# Create IAM role
echo "Creating trust policy $TRUST_POLICY_FILE file in local directory..."
cat <<EOF > "${SCRATCH_DIR}/$TRUST_POLICY_FILE"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER_ENDPOINT}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${OIDC_PROVIDER_ENDPOINT}:sub": [
                        "system:serviceaccount:${ESO_NAMESPACE}:${ESO_SA_NAME}"
                    ]
                }
            }
        }
    ]
}
EOF

export ROLE_NAME=$CLUSTER_NAME-iam-secret-role


# Extract OIDC Provider endpoint
OIDC_PROVIDER_ENDPOINT=$(get_oidc_provider_endpoint || true)
echo "OIDC Provider Endpoint: $OIDC_PROVIDER_ENDPOINT"

# Create IAM Role 
echo "Creating IAM ROLE ${CLUSTER_NAME}-iam-role ..."
ROLE_ARN=$(create_iam_role "$CLUSTER_NAME" || true)
echo "Role ARN: $ROLE_ARN"

# Create IAM Policy
echo "Creating Trust Policy ${CLUSTER_NAME}-iam-policy ..."
POLICY_ARN=$(create_iam_policy "$CLUSTER_NAME" || true)
echo "Policy ARN: $POLICY_ARN"

# Attach IAM Role to Policy
echo "Attaching ${CLUSTER_NAME}-iam-role to $POLICY_ARN..."
attach_policy_to_role "$ROLE_NAME" "$POLICY_ARN" || true

echo Successfully attached!

echo "Creating Service Account ..."


# aws secretsmanager create-secret \
#   --description "PostGress Demo Username" \
#   --name secret/psqluname \
#   --secret-string "xxxxxxxxx"

# aws secretsmanager create-secret \
#   --description "PostGress Demo Password" \
#   --name secret/psqlpassword \
#   --secret-string "xxxxxxxxxxxxxxxxx"