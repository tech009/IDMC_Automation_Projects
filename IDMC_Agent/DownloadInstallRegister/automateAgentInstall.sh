#!/bin/bash

# Function to print usage
usage() {
  echo "Usage: $0 -u <IDMC_URL> -n <Username> -p <Password> -f <Platform> [-d <Installation Directory>]"
  exit 1
}

# Function to check and install package if missing
check_and_install() {
  local cmd=$1
  local pkg=$2

  if ! command -v "$cmd" &> /dev/null; then
    echo "$cmd not found. Installing $pkg..."
    if command -v apt-get &> /dev/null; then
      sudo apt-get update && sudo apt-get install -y "$pkg"
    elif command -v yum &> /dev/null; then
      sudo yum install -y "$pkg"
    else
      echo "Package manager not found. Please install $pkg manually."
      exit 1
    fi

    # Verify installation
    if ! command -v "$cmd" &> /dev/null; then
      echo "Failed to install $pkg. Please install it manually."
      exit 1
    fi
  else
    echo "$cmd is already installed."
  fi
}

# Check for jq and curl, install if missing
check_and_install "jq" "jq"
check_and_install "curl" "curl"

# Parse input arguments
while getopts ":u:n:p:f:d:" opt; do
  case $opt in
    u) IDMC_URL="$OPTARG" ;;
    n) USERNAME="$OPTARG" ;;
    p) PASSWORD="$OPTARG" ;;
    f) PLATFORM="$OPTARG" ;;
    d) INSTALL_DIR="$OPTARG" ;;
    *) usage ;;
  esac
done

# Check mandatory parameters
if [[ -z "$IDMC_URL" || -z "$USERNAME" || -z "$PASSWORD" || -z "$PLATFORM" ]]; then
  usage
fi

# Set default installation directory if not provided
if [[ -z "$INSTALL_DIR" ]]; then
  INSTALL_DIR="$HOME/infa_agent_install"
fi

echo "IDMC URL: $IDMC_URL"
echo "Username: $USERNAME"
echo "Platform: $PLATFORM"
echo "Installation Directory: $INSTALL_DIR"

# Create installation directory if not exists
mkdir -p "$INSTALL_DIR"

#Setting up IATEMPDIR
IATEMPDIR=$INSTALL_DIR/temp
mkdir -p "$IATEMPDIR"
echo "IATEMPDIR set to $IATEMPDIR"
export IATEMPDIR="$IATEMPDIR"

# 1. Login API POST call to get icsessionID and serverUrl
LOGIN_RESPONSE=$(curl -s -X POST "$IDMC_URL/ma/api/v2/user/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\", \"password\":\"$PASSWORD\"}")

# Extract icsessionID and serverUrl using jq
ICSESSIONID=$(echo "$LOGIN_RESPONSE" | jq -r '.icSessionId')
SERVER_URL=$(echo "$LOGIN_RESPONSE" | jq -r '.serverUrl')

if [[ "$ICSESSIONID" == "null" || -z "$ICSESSIONID" || "$SERVER_URL" == "null" || -z "$SERVER_URL" ]]; then
  echo "Login failed or unable to extract icsessionID/serverUrl."
  exit 1
fi

echo "Login successful. icsessionID: $ICSESSIONID"
echo "Server URL: $SERVER_URL"

# 2. Get installer info for platform
INSTALLER_INFO=$(curl -s -X GET "$SERVER_URL/api/v2/agent/installerInfo/$PLATFORM" \
  -H "icsessionid: $ICSESSIONID")

# Extract download URL and install token
DOWNLOAD_URL=$(echo "$INSTALLER_INFO" | jq -r '.downloadUrl')
INSTALL_TOKEN=$(echo "$INSTALLER_INFO" | jq -r '.installToken')

if [[ "$DOWNLOAD_URL" == "null" || -z "$DOWNLOAD_URL" || "$INSTALL_TOKEN" == "null" || -z "$INSTALL_TOKEN" ]]; then
  echo "Failed to get download URL or install token."
  exit 1
fi

echo "Download URL: $DOWNLOAD_URL"
echo "Install Token: $INSTALL_TOKEN"

# 3. Download agent installer
AGENT_BIN="$INSTALL_DIR/agent64_install_ng_ext.bin"
echo "Downloading agent installer to $AGENT_BIN ..."
curl -s -L "$DOWNLOAD_URL" -o "$AGENT_BIN"
chmod +x "$AGENT_BIN"

# 4. Execute installer silently with installation directory
echo "Running installer..."
"$AGENT_BIN" -i silent -DUSER_INSTALL_DIR="$INSTALL_DIR"
if [[ $? -ne 0 ]]; then
  echo "Installation failed."
  exit 1
fi

# 5. Navigate to agentcore directory
AGENTCORE_DIR="$INSTALL_DIR/apps/agentcore"
cd "$AGENTCORE_DIR" || { echo "Agent core directory not found."; exit 1; }
echo "Agent Instalation Complete!"

# 6. Start infaagent
echo "Starting infaagent..."
./infaagent startup

# 7. Wait 1 minute
echo "Waiting 30 seconds for agent startup..."
sleep 30

# 8. Check agent status
STATUS=$(./consoleAgentManager.sh getStatus)
echo "Agent status: $STATUS"

# 9. If NOT_CONFIGURED, configure token
if [[ "$STATUS" == "NOT_CONFIGURED" ]]; then
  echo "Configuring agent with token..."
  ./consoleAgentManager.sh configureToken "$USERNAME" "$INSTALL_TOKEN"
  
  # 10. Wait 2 minutes
  echo "Waiting 2 minutes for configuration..."
  sleep 120
fi

# 11. Check if agent is configured
IS_CONFIGURED=$(./consoleAgentManager.sh isConfigured)
echo "Is agent configured? $IS_CONFIGURED"

if [[ "$IS_CONFIGURED" == "true" ]]; then
  echo "Deployment and Setup Successful."
else
  echo "Agent not configured yet."
fi
