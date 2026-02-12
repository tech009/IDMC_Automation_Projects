#!/bin/bash

# Check for exactly 5 arguments
if [ "$#" -ne 5 ]; then
  echo "Usage: $0 <IICS_BASE_URL> <IICS_USERNAME> <IICS_PASSWORD> <SECURE_AGENT_GROUP_NAME> <SECURE_AGENT_INSTALL_LOCATION>"
  exit 1
fi

IICS_BASE_URL=$1
IICS_USERNAME=$2
IICS_PASSWORD=$3
SECURE_AGENT_GROUP_NAME=$4
INSTALL_LOCATION=$5

# Step 2: Read InfaAgent.Id from infaagent.ini
INFAAGENT_INI_PATH="$INSTALL_LOCATION/apps/agentcore/conf/infaagent.ini"
if [[ ! -f "$INFAAGENT_INI_PATH" ]]; then
  echo "Error: infaagent.ini not found at $INFAAGENT_INI_PATH"
  exit 1
fi

INFAAGENT_ID=$(grep -i '^InfaAgent.Id=' "$INFAAGENT_INI_PATH" | cut -d'=' -f2 | tr -d '[:space:]')
if [[ -z "$INFAAGENT_ID" ]]; then
  echo "Error: InfaAgent.Id not found in $INFAAGENT_INI_PATH"
  exit 1
fi

# Step 3: Login to get icSessionId and serverUrl
LOGIN_RESPONSE=$(curl -s -X POST "$IICS_BASE_URL/ma/api/v2/user/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$IICS_USERNAME\",\"password\":\"$IICS_PASSWORD\"}")

icSessionId=$(echo "$LOGIN_RESPONSE" | jq -r '.icSessionId')
serverUrl=$(echo "$LOGIN_RESPONSE" | jq -r '.serverUrl')

if [[ "$icSessionId" == "null" || -z "$icSessionId" || "$serverUrl" == "null" || -z "$serverUrl" ]]; then
  echo "Error: Failed to login or extract icSessionId/serverUrl"
  exit 1
fi

# Step 5: Get runtime environment details
RUNTIME_ENV_RESPONSE=$(curl -s -X GET "$serverUrl/api/v2/runtimeEnvironment/name/$SECURE_AGENT_GROUP_NAME" \
  -H "icSessionId: $icSessionId")

id=$(echo "$RUNTIME_ENV_RESPONSE" | jq -r '.id')
name=$(echo "$RUNTIME_ENV_RESPONSE" | jq -r '.name')
agents=$(echo "$RUNTIME_ENV_RESPONSE" | jq '.agents')

if [[ "$id" == "null" || -z "$id" ]]; then
  echo "Error: Failed to get runtime environment details for $SECURE_AGENT_GROUP_NAME"
  exit 1
fi

# Step: Validate agentGroupId before final POST call

# Make GET call to get agent details
AGENT_RESPONSE=$(curl -s -X GET "$serverUrl/api/v2/agent/$INFAAGENT_ID" \
  -H "icSessionId: $icSessionId")

agentGroupId=$(echo "$AGENT_RESPONSE" | jq -r '.agentGroupId')

if [[ -z "$agentGroupId" || "$agentGroupId" == "null" ]]; then
  echo "Error: Unable to retrieve agentGroupId for agent $INFAAGENT_ID"
  exit 1
fi

# Compare agentGroupId with runtime environment id
if [[ "$agentGroupId" == "$id" ]]; then
  echo "Agent already part of same Group, terminating script now."
  curl -s -X POST "$serverUrl/api/v2/user/logout" -H "icSessionId: $icSessionId"
  echo "Logged out successfully."
  exit 0
fi

# If not same, proceed with the final POST call (the existing update POST)

# Step 6: Append new agent to agents list
orgId=${INFAAGENT_ID:0:6}
new_agent=$(jq -n --arg id "$INFAAGENT_ID" --arg orgId "$orgId" \
  '{"@type": "agent", "id": $id, "orgId": $orgId}')

# Combine existing agents with new agent
new_agents=$(echo "$agents" | jq --argjson newAgent "$new_agent" '. + [$newAgent]')

# Extract isShared from the original response (assuming it exists)
isShared=$(echo "$RUNTIME_ENV_RESPONSE" | jq '.isShared')
if [[ "$isShared" == "null" ]]; then
  # Default to false if not present
  isShared=false
fi

# Step 7: POST updated runtime environment
update_payload=$(jq -n --arg type "runtimeEnvironment" --arg name "$name" --argjson agents "$new_agents" --argjson isShared "$isShared" \
  '{ "@type": $type, name: $name, agents: $agents, isShared: $isShared }')

update_response=$(curl -s -X POST "$serverUrl/api/v2/runtimeEnvironment/$id" \
  -H "Content-Type: application/json" \
  -H "icSessionId: $icSessionId" \
  -d "$update_payload")

# After the update_response is received, check for error type
if echo "$update_response" | jq -e 'select(."@type" == "error")' > /dev/null; then
  echo "Error Re-assigning Secure Agent"
  echo "$update_response"
else
  echo "Re-Assignment Successful"
fi

# Step 8: Logout session for user.

curl -s -X POST "$serverUrl/api/v2/user/logout" \
  -H "icSessionId: $icSessionId"

echo "Logged out successfully."
