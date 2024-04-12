#! /bin/bash

aro-login

echo "Starting..."

helm upgrade --install gitops-install 00-gitops-install

echo "Waiting for 3 minutes"

echo ""
echo ""

# sleep 90

helm upgade --install cluster-bootstrap 01-argobootstrap

echo "Ending..."

