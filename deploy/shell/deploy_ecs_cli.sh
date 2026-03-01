#!/usr/bin/env bash
set -euo pipefail

# Required env vars
: "${AWS_REGION:?AWS_REGION is required}"
: "${ECS_CLUSTER:?ECS_CLUSTER is required}"
: "${ECS_SERVICE:?ECS_SERVICE is required}"
: "${TASK_FAMILY:?TASK_FAMILY is required}"
: "${ECR_REPO:?ECR_REPO is required}"
: "${CONTAINER_NAME:?CONTAINER_NAME is required}"
: "${APP_DIR:?APP_DIR is required}"

CPU="${CPU:-256}"
MEMORY="${MEMORY:-512}"
CONTAINER_PORT="${CONTAINER_PORT:-8000}"
EXECUTION_ROLE_ARN="${EXECUTION_ROLE_ARN:-}"
TASK_ROLE_ARN="${TASK_ROLE_ARN:-}"
IMAGE_TAG="${IMAGE_TAG:-$(date +%Y%m%d%H%M%S)}"

command -v aws >/dev/null 2>&1 || { echo "aws cli not found"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "docker not found"; exit 1; }

AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_URI="${ECR_REGISTRY}/${ECR_REPO}"
IMAGE_URI="${ECR_URI}:${IMAGE_TAG}"

echo "[1/7] Ensure ECR repository exists"
aws ecr describe-repositories \
  --repository-names "${ECR_REPO}" \
  --region "${AWS_REGION}" >/dev/null 2>&1 || \
aws ecr create-repository \
  --repository-name "${ECR_REPO}" \
  --image-scanning-configuration scanOnPush=true \
  --region "${AWS_REGION}" >/dev/null

echo "[2/7] ECR login"
aws ecr get-login-password --region "${AWS_REGION}" | \
  docker login --username AWS --password-stdin "${ECR_REGISTRY}"

echo "[3/7] Build and push image ${IMAGE_URI}"
docker build -t "${ECR_REPO}:${IMAGE_TAG}" "${APP_DIR}"
docker tag "${ECR_REPO}:${IMAGE_TAG}" "${IMAGE_URI}"
docker push "${IMAGE_URI}"

echo "[4/7] Render task definition"
TASKDEF_FILE="$(mktemp -t taskdef-XXXXXX.json)"

if [[ -z "${EXECUTION_ROLE_ARN}" ]]; then
  EXECUTION_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole"
fi

cat > "${TASKDEF_FILE}" <<JSON
{
  "family": "${TASK_FAMILY}",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "${CPU}",
  "memory": "${MEMORY}",
  "executionRoleArn": "${EXECUTION_ROLE_ARN}",
  "containerDefinitions": [
    {
      "name": "${CONTAINER_NAME}",
      "image": "${IMAGE_URI}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": ${CONTAINER_PORT},
          "protocol": "tcp"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/${ECS_SERVICE}",
          "awslogs-region": "${AWS_REGION}",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
JSON

if [[ -n "${TASK_ROLE_ARN}" ]]; then
  TASKDEF_WITH_ROLE="$(mktemp -t taskdef-role-XXXXXX.json)"
  awk -v role="\"taskRoleArn\": \"${TASK_ROLE_ARN}\"," '
    /"executionRoleArn"/ {print; print "  " role; next}
    {print}
  ' "${TASKDEF_FILE}" > "${TASKDEF_WITH_ROLE}"
  mv "${TASKDEF_WITH_ROLE}" "${TASKDEF_FILE}"
fi

echo "[5/7] Register task definition"
TASK_DEF_ARN="$(aws ecs register-task-definition \
  --region "${AWS_REGION}" \
  --cli-input-json "file://${TASKDEF_FILE}" \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)"

echo "Task definition: ${TASK_DEF_ARN}"

echo "[6/7] Update ECS service"
aws ecs update-service \
  --region "${AWS_REGION}" \
  --cluster "${ECS_CLUSTER}" \
  --service "${ECS_SERVICE}" \
  --task-definition "${TASK_DEF_ARN}" \
  --force-new-deployment >/dev/null

echo "[7/7] Wait until service is stable"
aws ecs wait services-stable \
  --region "${AWS_REGION}" \
  --cluster "${ECS_CLUSTER}" \
  --services "${ECS_SERVICE}"

echo "Deploy complete: ${IMAGE_URI}"
