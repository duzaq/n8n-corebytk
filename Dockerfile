version: '3.8'

volumes:
  db_storage:
  n8n_storage:
  qdrant_storage:
  redis_storage:
  

x-shared: &shared
  restart: always
  environment:
    - DB_TYPE=postgresdb
    - DB_POSTGRESDB_HOST=postgres
    - DB_POSTGRESDB_PORT=5432
    - DB_POSTGRESDB_DATABASE=dbn8n
    - DB_POSTGRESDB_USER=admin
    - DB_POSTGRESDB_PASSWORD=10mega2013
    - EXECUTIONS_MODE=queue
    - QUEUE_BULL_REDIS_HOST=redis
    - QUEUE_HEALTH_CHECK_ACTIVE=true
    - N8N_BASIC_AUTH_ACTIVE=true
    - N8N_BASIC_AUTH_USER=admin
    - N8N_BASIC_AUTH_PASSWORD=10mega2013
    - N8N_ENCRYPTION_KEY=F+n8T0pctpwp5gLqwjUGmsRZn2yrLNGz
  links:
    - postgres
    - redis
  volumes:
    - n8n_storage:/home/node/
  depends_on:
    redis:
      condition: service_healthy
    postgres:
      condition: service_healthy

services:
  postgres:
    image: postgres:11
    restart: always
    environment:
      - POSTGRES_USER=admin
      - POSTGRES_PASSWORD=10mega2013
      - POSTGRES_DB=dbn8n
      - POSTGRES_NON_ROOT_USER=admin
      - POSTGRES_NON_ROOT_PASSWORD=10mega2013
    volumes:
      - db_storage:/var/lib/postgresql/data
      - ./init-data.sh:/docker-entrypoint-initdb.d/init-data.sh
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -h localhost -U admin -d dbn8n"]
      interval: 5s
      timeout: 5s
      retries: 10

  redis:
    image: redis:6-alpine
    restart: always
    volumes:
      - redis_storage:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 10

  n8n:
    <<: *shared
    image: n8nio/n8n
    ports:
      - "5678:5678"
    entrypoint:
      - n8n
      - start
      - --tunnel

  n8n-worker:
    <<: *shared
    image: n8nio/n8n
    deploy: 
      replicas: 1 # Número de réplicas desejadas
    entrypoint:
      - n8n
      - worker
    depends_on:
      - n8n

  qdrant:
    image: qdrant/qdrant
    container_name: qdrant-doc
    #networks: ['demo']
    restart: unless-stopped
    ports:
      - 6333:6333
    volumes:
      - qdrant_storage:/qdrant/storage
