#!/usr/bin/env bash
project="nitrogenase-docker"
name="nitrogenase-metastaar"
tag="1.0.9"
full="${name}:${tag}"
echo "Using Google project ${project}, Docker project ${name}, full tag ${full}"
echo "Building"
sudo docker build . -t gcr.io/${project}/${full}
echo "Submitting"
docker push gcr.io/${project}/${full}
echo "Done"
