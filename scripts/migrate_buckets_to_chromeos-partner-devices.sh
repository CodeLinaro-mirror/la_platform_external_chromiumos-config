#!/bin/bash

#script migrates buckets from old to new gcp
#https://cloud.google.com/storage/docs/moving-buckets?hl=en#gsutil

# new GCP
newGcp='chromeos-partner-devices'
# temp suffix
temp_suffix='tmp'

# Weird error when bucket is empty
# CommandException: No URLs matched: gs://chromeos-xxx

migrate_bucket() {
  local bucket_name="${1}"
  gsutil mb gs://"${bucket_name}-${temp_suffix}"
  gsutil cp -r gs://"${bucket_name}"/* gs://"${bucket_name}-${temp_suffix}"
  gsutil rm -r gs://"${bucket_name}"

  gsutil mb gs://"${bucket_name}"
  gsutil cp -r gs://"${bucket_name}-${temp_suffix}"/* gs://"${bucket_name}"
  gsutil rm -r gs://"${bucket_name}-${temp_suffix}"
}

input="${1}"
gcloud config set project "${newGcp}"
while IFS= read -r line
do
  echo "migrate ${line}"
  migrate_bucket "${line}"
done < "${input}"
