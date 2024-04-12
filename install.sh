#! /bin/bash

echo "Starting..."

helm template 00-gitops-install

echo "Waiting for 3 minutes"

echo ""
echo ""

sleep 3

helm template 01-argobootstrap

echo "Ending..."

