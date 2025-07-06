# Start with AWS Glue base image v5
FROM public.ecr.aws/glue/aws-glue-libs:5

# Switch to root for installations
USER root

# Set environment variables
ENV AIRFLOW_HOME=/opt/airflow
ENV MINIO_HOST=minio
ENV MINIO_PORT=9000
ENV MINIO_ROOT_USER=admin
ENV MINIO_ROOT_PASSWORD=password
ENV TRINO_HOME=/opt/trino
ENV TRINO_VERSION=435
ENV PYTHONPATH=/opt/aws-glue-libs:$PYTHONPATH
ENV SQLITE_VERSION=3500200
ENV SQLITE_VERSION_HUMAN=3.50.2

# Install system dependencies
RUN dnf clean all && \
    dnf install -y \
        python3-devel \
        python3-setuptools \
        java-11-amazon-corretto-devel \
        openssl-devel \
        zlib-devel \
        libffi-devel \
        shadow-utils \
        wget \
        unzip \
        tar \
        gzip \
        python3-pip && \
    dnf clean all

# Install MinIO client (mc)
RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc && \
    chmod +x /usr/local/bin/mc

# Install Trino Server
RUN mkdir -p ${TRINO_HOME} && \
    wget https://repo1.maven.org/maven2/io/trino/trino-server/${TRINO_VERSION}/trino-server-${TRINO_VERSION}.tar.gz -P /tmp && \
    tar -xzf /tmp/trino-server-${TRINO_VERSION}.tar.gz -C ${TRINO_HOME} --strip-components=1 && \
    rm /tmp/trino-server-${TRINO_VERSION}.tar.gz && \
    mkdir -p ${TRINO_HOME}/etc/catalog

# Install Trino CLI
RUN curl -O https://repo1.maven.org/maven2/io/trino/trino-cli/445/trino-cli-445-executable.jar && \
    mv trino-cli-445-executable.jar /usr/local/bin/trino && \
    chmod +x /usr/local/bin/trino

# Configure Trino for MinIO
COPY trino-config ${TRINO_HOME}/etc/
COPY trino-catalog ${TRINO_HOME}/etc/catalog/

# Upgrade pip and install Python packages
RUN python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel

# Fix attr/attrs confusion
RUN python3 -m pip uninstall -y attr attrs || true && \
    python3 -m pip install --no-cache-dir --upgrade "attrs>=22.2.0"

# Install Python packages with Kafka support
RUN python3 -m pip install --no-cache-dir \
    connexion==2.14.1 \
    pendulum==2.1.2 \
    werkzeug==2.3.7 \
    Flask-Session==0.4.0 \
    boto3 \
    "moto[all]" \
    apache-airflow==2.6.3 \
    apache-airflow-providers-amazon \
    apache-airflow-providers-http \
    trino

# Setup Airflow
RUN mkdir -p ${AIRFLOW_HOME} && \
    chmod 777 ${AIRFLOW_HOME} && \
    python3 -m airflow db init && \
    python3 -m airflow users create \
    --username admin \
    --password admin \
    --firstname Admin \
    --lastname User \
    --role Admin \
    --email admin@example.com

# Copy startup script
COPY start-services.sh /usr/local/bin/start-services.sh
RUN chmod +x /usr/local/bin/start-services.sh

# Copy Trino initialization script
COPY initialize-trino.sh /usr/local/bin/initialize-trino.sh
RUN chmod +x /usr/local/bin/initialize-trino.sh

# Expose ports
EXPOSE 8080 8083 9000 5000 8082

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Final attrs installation
RUN python3 -m pip install --no-cache-dir --upgrade "attrs>=22.2.0"

# Entrypoint
ENTRYPOINT ["/usr/local/bin/start-services.sh"]
