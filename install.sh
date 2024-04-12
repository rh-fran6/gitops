#! /bin/bash

aro-login

echo "Starting..."

helm install gitops-install 00-gitops-install

echo "Waiting for 3 minutes"

echo ""
echo ""

sleep 60

helm install cluster-bootstrap 01-argobootstrap

echo "Ending..."

