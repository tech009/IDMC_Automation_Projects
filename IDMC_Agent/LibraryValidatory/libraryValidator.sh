#!/bin/bash

# Mapping of libraries to yum package names (approximate)
declare -A lib_to_pkg=(
  ["libpthread.so.0"]="glibc"
  ["libnsl.so.1"]="libnsl"
  ["libdl.so.2"]="glibc"
  ["libstdc++.so.6"]="libstdc++"
  ["libm.so.6"]="glibc"
  ["libc.so.6"]="glibc"
  ["libgcc_s.so.1"]="libgcc"
  ["ld-linux-x86-64.so.2"]="glibc"
)

# List of libraries to check
libs=(
  "libpthread.so.0"
  "libnsl.so.1"
  "libdl.so.2"
  "libstdc++.so.6"
  "libm.so.6"
  "libc.so.6"
  "libgcc_s.so.1"
  "ld-linux-x86-64.so.2"
)

echo "Starting library validation..."

for lib in "${libs[@]}"; do
  # Check if the library exists in /lib64 or /usr/lib64
  if ldconfig -p | grep -q "$lib"; then
    echo "Library $lib is installed."
  else
    echo "Library $lib is NOT installed."
    pkg=${lib_to_pkg[$lib]}
    if [ -n "$pkg" ]; then
      echo "Attempting to install package $pkg for $lib..."
      sudo yum install -y "$pkg"
      if ldconfig -p | grep -q "$lib"; then
        echo "Successfully installed $lib via package $pkg."
      else
        echo "Failed to install $lib via package $pkg."
      fi
    else
      echo "No package mapping found for $lib. Please install it manually."
    fi
  fi
done

echo "Library validation complete."