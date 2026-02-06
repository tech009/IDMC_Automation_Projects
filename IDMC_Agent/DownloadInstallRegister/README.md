# Automating Agent Installation for IDMC - Linux Systems

---

## Overview

This repository contains a shell script to automate the installation and configuration of the Informatica Intelligent Data Management Cloud (IDMC) agent. The script handles authentication, downloads the necessary installer, performs a silent installation, and verifies the agent's configuration status.

---

## Script Purpose

The script automates the entire process of:

- Authenticating with the IDMC platform.
- Retrieving the agent installer and installation tokens via REST API.
- Performing a silent installation of the agent.
- Starting the agent and verifying its configuration status.

---

## Benefits

- **Time-saving:** Automates repetitive installation steps.
- **Consistency:** Ensures uniform installation and configuration across environments.
- **Error Reduction:** Minimizes manual errors during installation.
- **Scalability:** Easily adaptable for multiple environments.
- **Verification:** Automatically confirms successful agent configuration.

---

## Prerequisites

Before running the script, ensure the following:

1. **System Requirements:**
   - Supported Linux environment with permissions to install software.
   - Network access to the IDMC platform and download URLs.

2. **Software Dependencies:**
   - `curl` for REST API calls.
   - `jq` for JSON parsing.
   - `dos2unix` (optional) if transferring scripts from Windows.

3. **User Inputs:**
   - **IDMC URL:** Base/Login URL of the IDMC platform.
   - **Username & Password:** Credentials for authentication.
   - **Platform:** Target platform identifier (linux64 only)
   - **Installation Directory (optional):** Directory for agent installation (defaults to user directory).

4. **Permissions:**
   - Execute permission on the script (`chmod +x automateAgentInstall.sh`).
   - Sudo/root privileges if needed for installing dependencies or software.

---

## Usage

1. **Prepare the Environment:**

   - Ensure `curl` and `jq` are installed. The script checks and installs them if missing.
   - Transfer the script to your Linux environment. Use `dos2unix` if the script was created on Windows.

2. **Run the Script:**

   ```bash
   ./install_agent.sh -u <IDMC_URL> -n <Username> -p <Password> -f "linux64" [-d <Installation Directory>]

