#!/bin/bash

set -eo pipefail

export GITOPS_NAMESPACE="openshift-gitops-operator"
export GITOPS_CHANNEL="gitops-1.10"

rosa-login

echo "Starting..."

echo ""

echo "Creating Namespace $GITOPS_NAMESPACE..."
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: $GITOPS_NAMESPACE
  annotations:
    openshift.io/display-name: "OpenShift GitOps Operator"
  labels:
    openshift.io/cluster-monitoring: 'true'
EOF

echo "Creating Operator Group named $GITOPS_NAMESPACE in $GITOPS_NAMESPACE namespace..."
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: $GITOPS_NAMESPACE
  namespace: $GITOPS_NAMESPACE
spec:
  upgradeStrategy: Default
EOF

echo "Creating subscription named $GITOPS_NAMESPACE in $GITOPS_NAMESPACE namespace..."
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: $GITOPS_NAMESPACE
  namespace: $GITOPS_NAMESPACE
spec:
  channel: $GITOPS_CHANNEL 
  installPlanApproval: Automatic
  name: openshift-gitops-operator 
  source: redhat-operators 
  sourceNamespace: openshift-marketplace 
EOF


echo "Waiting for Gitops to finish installation..."

echo ""
echo ""

sleep 90

echo "GitOps installation done..."

echo ""

echo "Starting cluster bootstrap..."

echo ""

helm upgrade --install cluster-bootstrap 01-bootstrap -n default

echo ""

echo "Ending..."

