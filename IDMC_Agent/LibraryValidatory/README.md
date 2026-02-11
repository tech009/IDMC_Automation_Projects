# Library Validator Script

## Overview

`libraryValidator` is a shell script that checks whether a predefined set of shared libraries are installed on a Linux system. If any required libraries are missing, the script attempts to install them automatically using the `yum` package manager.

## Pre-requisites

- A Linux system with the `yum` package manager (commonly CentOS, RHEL, Fedora).
- `sudo` privileges to install packages.
- Basic familiarity with running shell scripts.

## Libraries Checked

The script validates the presence of the following libraries:

- libpthread.so.0
- libnsl.so.1
- libdl.so.2
- libstdc++.so.6
- libm.so.6
- libc.so.6
- libgcc_s.so.1
- ld-linux-x86-64.so.2

## Setup

1. Save the `libraryValidator` script to your desired directory.

2. Make the script executable by running:

   ```bash
   chmod +x libraryValidator
   ````

3. Run the script with root privileges to allow it to install missing libraries:

    ````bash
    sudo ./libraryValidator
    ````

The script will:
-   Check each library in the predefined list.
-   Report whether each library is installed.
-   Attempt to install missing libraries using yum.
-   Inform you of success or failure for each installation.


##  Notes
-   The script uses a built-in mapping from libraries to their corresponding yum packages.
-   If a library is missing and no package mapping exists, you will be prompted to install it manually.
-   Ensure your system has internet access to download packages.
-   The script relies on ldconfig to detect installed libraries.