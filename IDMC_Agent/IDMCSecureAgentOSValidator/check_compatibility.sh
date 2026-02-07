#!/bin/bash

# ==============================================================================
# OS and Service Compatibility Checker
#
# Description:
# This script checks the current Linux operating system against a compatibility
# list defined in an external CSV file. It then reports which services are
# supported and which are not for the detected OS.
#
# It requires a file named 'compatibilitySheet.csv' in the same directory.
#
# ==============================================================================

# --- Configuration ---
CSV_FILE="compatibilitySheet.csv"

# --- File Existence Check ---
if [ ! -f "$CSV_FILE" ]; then
    echo "Error: Compatibility file '$CSV_FILE' not found in the current directory."
    echo "Please ensure the file exists and contains the compatibility data."
    exit 1
fi

# --- OS Detection ---
# Check for /etc/os-release, which is the standard for modern Linux distros.
if [ ! -f /etc/os-release ]; then
    echo "Error: Cannot determine OS version. /etc/os-release not found."
    exit 1
fi

# Source the file to get variables like NAME, VERSION_ID, PRETTY_NAME
. /etc/os-release

echo "🔎 Detecting Operating System..."
echo "   Found: $PRETTY_NAME"
echo "--------------------------------------------------"

# --- Main Logic ---
MATCH_FOUND=false

# Read the header line from the CSV to get service names
HEADER=$(head -n 1 "$CSV_FILE")
IFS=',' read -r -a header_array <<< "$HEADER"

# *** FIX APPLIED HERE ***
# Loop through the data rows from the CSV using process substitution
# to avoid creating a subshell for the loop.
while IFS=, read -r -a data_array; do
    # Trim leading/trailing whitespace from the OS name in the data
    csv_os_name=$(echo "${data_array[0]}" | xargs)
    
    # --- Matching Logic ---
    # This block tries to match the detected OS with an entry in our list.
    CURRENT_OS_MATCH=false
    case "$NAME" in
        *"Red Hat"*)
            if [[ "$csv_os_name" == "RedHat "* ]]; then
                csv_major_ver=$(echo "$csv_os_name" | grep -oE '[0-9]+')
                os_major_ver=$(echo "$VERSION_ID" | cut -d. -f1)
                if [[ "$csv_major_ver" == "$os_major_ver" ]]; then
                    CURRENT_OS_MATCH=true
                fi
            fi
            ;;
        *"Oracle"*)
            if [[ "$csv_os_name" == "Oracle Linux "* ]]; then
                csv_major_ver=$(echo "$csv_os_name" | grep -oE '[0-9]+')
                os_major_ver=$(echo "$VERSION_ID" | cut -d. -f1)
                if [[ "$csv_major_ver" == "$os_major_ver" ]]; then
                    CURRENT_OS_MATCH=true
                fi
            fi
            ;;
        *"SUSE"*)
            csv_ver_norm=$(echo "$csv_os_name" | tr -d ' ' | tr '[:lower:]' '[:upper:]')
            os_ver_norm=$(echo "$VERSION" | tr -d '-' | tr '[:lower:]' '[:upper:]')
            if [[ "$csv_ver_norm" == *"$os_ver_norm"* ]]; then
                CURRENT_OS_MATCH=true
            fi
            ;;
        *"Ubuntu"*)
            if [[ "$csv_os_name" == "Ubuntu $VERSION_ID" ]]; then
                CURRENT_OS_MATCH=true
            fi
            ;;
        *"Amazon Linux"*)
            if [[ "$csv_os_name" == "Amazon Linux $VERSION_ID" ]]; then
                CURRENT_OS_MATCH=true
            fi
            ;;
    esac

    if [ "$CURRENT_OS_MATCH" = true ]; then
        MATCH_FOUND=true
        echo "✅ Match found in compatibility list: '$csv_os_name'"
        echo ""

        supported_services=()
        unsupported_services=()

        for i in $(seq 2 $((${#header_array[@]} - 1))); do
            service_name=$(echo "${header_array[$i]}" | xargs)
            status=$(echo "${data_array[$i]}" | xargs)

            if [[ "$status" == "S" || "$status" == "S1" ]]; then
                supported_services+=("$service_name")
            else
                unsupported_services+=("$service_name")
            fi
        done

        echo "🟢 Supported Services:"
        printf "   - %s\n" "${supported_services[@]}"
        
        echo ""
        echo "🔴 Unsupported / Not Applicable Services:"
        printf "   - %s\n" "${unsupported_services[@]}"

        break
    fi
done < <(tail -n +2 "$CSV_FILE") # The other part of the fix is here

# Now this check will work correctly because MATCH_FOUND is in the same shell.
if [ "$MATCH_FOUND" = false ]; then
    echo "⚠️ Your OS ($PRETTY_NAME) was not found in the compatibility list."
fi
