#!/usr/bin/env bash
project="nitrogenase-docker"
name="nitrogenase-metastaar"
tag="1.2.12"
full="${name}:${tag}"
echo "Using Google project ${project}, Docker project ${name}, full tag ${full}"
echo "Cloud-building Docker image:"
gcloud builds submit --timeout=60m --tag gcr.io/${project}/${full}
#echo "Building"
#sudo docker build . -t gcr.io/${project}/${full}
#echo "Submitting"
#docker push gcr.io/${project}/${full}
echo "Done"
