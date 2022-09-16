#!/usr/bin/env bash
project="nitrogenase-docker"
name="nitrogenase-r-munge"
tag="0.1.0"
image="${name}:${tag}"
echo "Using Google project ${project}, Docker project ${name}, image tag ${image}"
echo "Cloud-building Docker image:"
full="gcr.io/${project}/${image}"
gcloud builds submit --timeout=60m --tag $full
arg1=$1
if [ -n "$arg1" ];then
  docker run -it $full "$arg1"
fi
echo "Done with $full $arg1"
