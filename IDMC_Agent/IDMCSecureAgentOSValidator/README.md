# 🖥️ OS Service Compatibility Checker

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Language](https://img.shields.io/badge/Language-Bash-blue.svg)
![Maintained](https://img.shields.io/badge/Maintained%3F-yes-green.svg)

A simple and portable shell script to check if the current Linux operating system is compatible with a predefined list of services. The script reads its configuration from an external CSV file, making it easy to update and maintain.

---

## 🚀 Key Features

*   ✅ **Automated Validation**: Eliminates manual checks, reducing human error and saving time.
*   📊 **Clear & Immediate Feedback**: Provides a straightforward report listing supported and unsupported services.
*   📝 **Easy to Maintain**: The compatibility matrix is stored in a simple `compatibilitySheet.csv` file. Update support statuses without touching the script's code.
*    portability **Portable**: Written in Bash using common Linux commands, ensuring it runs on a wide variety of systems without special dependencies.

## 📋 Prerequisites

> **Important:** Before running, please ensure your system meets the following requirements.

1.  **A Linux-based Operating System**: The script is designed for Linux and relies on standard GNU/Linux commands.
2.  **`/etc/os-release` File**: The script uses this file to automatically detect the OS name and version. This is standard on most modern Linux distributions.
3.  **Standard Shell Environment**: A Bash shell and common command-line utilities (`head`, `tail`, `grep`, `cut`, `tr`, `xargs`).
4.  **The `compatibilitySheet.csv` File**: This file **must** be present in the same directory as the script.

## ⚙️ Setup

1.  **Clone the repository or download the files:**
    ```bash
    git clone <your-repository-url>
    cd <your-repository-directory>
    ```
    Alternatively, manually download `check_compatibility.sh` and `compatibilitySheet.csv` into the same directory.

2.  **Make the script executable:**
    This is a crucial step to allow the script to be run.
    ```bash
    chmod +x check_compatibility.sh
    ```

## ▶️ Usage

Simply execute the script from your terminal. It requires no command-line arguments.

```bash
./check_compatibility.sh