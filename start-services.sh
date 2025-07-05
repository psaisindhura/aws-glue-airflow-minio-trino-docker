#!/bin/bash

# Initialize Trino
/usr/local/bin/initialize-trino.sh


# Start Trino server (with proper logging)
${TRINO_HOME}/bin/launcher run > ${TRINO_HOME}/var/log/server.log 2>&1 &

# Wait for Trino to be fully ready
#while ! ${TRINO_HOME}/bin/trino --execute "SELECT 1" >/dev/null 2>&1; do
#  echo "Waiting for Trino to initialize..."
#  sleep 5
#done

# Start LocalStack in the background
#localstack start -d

# Start Kafka
#$KAFKA_HOME/bin/zookeeper-server-start.sh -daemon $KAFKA_HOME/config/zookeeper.properties
#$KAFKA_HOME/bin/kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties

# Initialize AWS resources
sleep 10
/opt/scripts/initialize-aws.sh

# Configure MinIO
mc alias set minio http://${MINIO_HOST}:${MINIO_PORT} ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD}
mc mb minio/test-bucket || true


# Start Airflow
airflow webserver -D &
airflow scheduler -D &

# Keep container running
tail -f /dev/null