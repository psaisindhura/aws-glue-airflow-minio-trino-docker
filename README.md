# 🧪 Local Data Engineering Stack: Airflow + Trino + Hive Metastore + MinIO + PostgreSQL

This repository provides a complete local development environment using Docker Compose that includes:

- **Apache Airflow** for orchestration
- **Trino** for distributed SQL querying
- **Hive Metastore** for metadata management
- **MinIO** for S3-compatible object storage
- **PostgreSQL** for Hive Metastore backend

---

## 🔧 Services Included

| Service         | Description                                      | Port     |
|----------------|--------------------------------------------------|----------|
| Airflow         | DAG Orchestration UI                            | `8080`   |
| Trino           | Distributed SQL query engine UI                 | `8083`   |
| Hive Metastore  | Metadata catalog for Trino                      | `9083`   |
| MinIO           | S3-compatible storage (API & UI)                | `9000`, `9001` |
| PostgreSQL      | Metastore database backend                      | `5432`   |

---

## 📁 Directory Structure

```
.
├── airflow/
│   ├── dags/              # Your Airflow DAGs go here
│   └── logs/              # Airflow logs
├── trino-config/          # Trino config.properties, jvm.config, log.properties
├── trino-catalog/         # Catalog definitions (e.g. minio.properties)
├── minio_data/            # MinIO bucket data volume
├── docker-compose.yml     # Main Docker setup
└── Dockerfile             # Custom image for Airflow + Trino
```

---

## ▶️ How to Run

### 1. ✅ Prerequisites

- Docker & Docker Compose installed
- Recommended: 8GB+ RAM

---

### 2. 🚀 Start the Environment

Run the following from the root of your repo:

```bash
docker-compose up --build
```

It will:

- Build a custom image with Airflow and Trino installed
- Start all services with dependencies in correct order
- Create an S3 bucket in MinIO for Hive/Trino access

---

### 3. 🔍 Access the Services

- **Airflow UI**: http://localhost:8080  
  Username: `admin` | Password: `admin`  
- **Trino UI**: http://localhost:8083  
- **MinIO Console**: http://localhost:9001  
  User: `admin` | Password: `password`  
- **PostgreSQL**: localhost:5432  
  User: `hive` | Password: `hivepassword` | DB: `hive`

---

### 4. 🧪 Trino Query Example

To connect to Trino CLI inside the running `app` container:

```bash
docker exec -it spark_localstack_airflow_trino trino   --server http://localhost:8083 --catalog minio --schema default
```

Then run:

```sql
SHOW SCHEMAS;
SHOW TABLES;
```

Or create a table:

```sql
CREATE TABLE minio.default.sample_data (
    id INT,
    name VARCHAR
)
WITH (
    format = 'PARQUET',
    external_location = 's3a://hivemetastore/sample_data/'
);
```

---

### 5. 📦 Airflow DAGs

Place your DAGs in:

```bash
airflow/dags/
```

Airflow will automatically detect them.

---

## 🛠 Docker Compose Overview

### Key Environment Variables

```env
AWS_ACCESS_KEY_ID=admin
AWS_SECRET_ACCESS_KEY=password
S3_BUCKET=hivemetastore
S3_PREFIX=spark
```

### Bucket Creation Script

The `s3_setup` service uses `mc` to:

- Create a bucket named `hivemetastore`
- Set it public (for read testing)

---

## 🐞 Troubleshooting

### ❌ "Hive metastore connection failed"

Check if `hive-metastore` is using correct database driver and that PostgreSQL is healthy.

Use logs to debug:

```bash
docker-compose logs hive-metastore
```

### ❌ "Trino failed to list schemas"

Make sure:

- Trino catalog config in `trino-catalog/minio.properties` points to correct metastore:
  
  ```
  connector.name=hive
  hive.metastore.uri=thrift://hive-metastore:9083
  hive.s3.aws-access-key=admin
  hive.s3.aws-secret-key=password
  hive.s3.endpoint=http://minio:9000
  hive.s3.path-style-access=true
  hive.s3.ssl.enabled=false
  ```

---

## 📌 Notes

- You can easily extend this setup to include Iceberg or Glue Catalog
- Compatible with Superset, dbt, and other data tools via Trino

---

## 📚 References

- [Trino](https://trino.io)
- [Apache Airflow](https://airflow.apache.org)
- [MinIO](https://min.io)
- [Hive Metastore](https://cwiki.apache.org/confluence/display/Hive/Hive+Metastore)
- [Project Source](https://github.com/naushadh/hive-metastore) for Hive Docker

---

## 🧹 Clean Up

To stop and clean up everything:

```bash
docker-compose down -v
```

---

## 👩‍💻 Maintainer

Built by Sai Sindhura Pappala.  
Feel free to fork and contribute.
