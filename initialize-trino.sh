#!/bin/bash

# Wait for MinIO to be ready
while ! nc -z minio 9001; do
  echo "Waiting for MinIO..."
  sleep 2
done

# Configure MinIO client
mc alias set minio http://minio:9001 admin password || true
mc mb minio/test-bucket || true
mc policy set public minio/test-bucket || true

# Prepare Trino directories
mkdir -p ${TRINO_HOME}/etc/catalog
mkdir -p ${TRINO_HOME}/var/log

# Set proper permissions
chmod -R 775 ${TRINO_HOME}/etc
chmod -R 775 ${TRINO_HOME}/var

echo "Trino initialization complete"