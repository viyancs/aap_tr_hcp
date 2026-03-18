#!/usr/bin/env bash
set -euo pipefail

# Required env vars
# export AAP_HOST="https://aap26.lutpiero.cloud"
# export AAP_PASSWORD="xxxxxxxxxxxxxxxx"
# export AAP_INVENTORY_ID="7"
# export AAP_JOB_TEMPLATE_ID="20"
# export VM_NAME="demo-srnh-vm"
# export VM_PUBLIC_IP="168.62.170.238"
# export VM_ADMIN_USERNAME="azureuser"
# export SSH_PORT="2200"

required_vars=(
  AAP_HOST
  AAP_PASSWORD
  AAP_INVENTORY_ID
  AAP_JOB_TEMPLATE_ID
  VM_NAME
  VM_PUBLIC_IP
  VM_ADMIN_USERNAME
  SSH_PORT
)

for v in "${required_vars[@]}"; do
  if [ -z "${!v:-}" ]; then
    echo "ERROR: $v is not set"
    exit 1
  fi
done

echo "AAP_HOST=$AAP_HOST"
echo "AAP_INVENTORY_ID=$AAP_INVENTORY_ID"
echo "AAP_JOB_TEMPLATE_ID=$AAP_JOB_TEMPLATE_ID"
echo "VM_NAME=$VM_NAME"
echo "VM_PUBLIC_IP=$VM_PUBLIC_IP"
echo "VM_ADMIN_USERNAME=$VM_ADMIN_USERNAME"
echo "SSH_PORT=$SSH_PORT"
echo "AAP_PASSWORD is set"

echo "Testing token auth..."
curl -sk \
  -H "Authorization: Bearer ${AAP_PASSWORD}" \
  "${AAP_HOST}/api/controller/v2/me"

echo "Register host to AAP inventory..."

CREATE_HOST_RESPONSE=$(
curl -sk \
  -H "Authorization: Bearer ${AAP_PASSWORD}" \
  -H "Content-Type: application/json" \
  -X POST \
  -d "{
    \"name\": \"${VM_NAME}\",
    \"enabled\": true,
    \"variables\": \"ansible_host: ${VM_PUBLIC_IP}\nansible_user: ${VM_ADMIN_USERNAME}\nansible_port: ${SSH_PORT}\"
  }" \
  "${AAP_HOST}/api/controller/v2/inventories/${AAP_INVENTORY_ID}/hosts/"
)

echo "Create host response:"
echo "${CREATE_HOST_RESPONSE}"

echo "Triggering AAP job..."

LAUNCH_JOB_RESPONSE=$(
curl -sk \
  -H "Authorization: Bearer ${AAP_PASSWORD}" \
  -H "Content-Type: application/json" \
  -X POST \
  -d "{}" \
  "${AAP_HOST}/api/controller/v2/job_templates/${AAP_JOB_TEMPLATE_ID}/launch/"
)

echo "Launch job response:"
echo "${LAUNCH_JOB_RESPONSE}"

echo "Done."