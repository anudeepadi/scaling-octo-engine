#!/bin/bash

# This script modifies the problematic template syntax in gRPC-Core's basic_seq.h file
# The issue is with the 'Traits::template CallSeqFactory' syntax

# Define the pods root path
PODS_ROOT="$(pwd)/Pods"

# Check if the file exists
FILE_PATH="${PODS_ROOT}/gRPC-Core/src/core/lib/promise/detail/basic_seq.h"
if [ -f "$FILE_PATH" ]; then
  echo "Found file to patch: $FILE_PATH"
  
  # Make the file writable if it's not already
  chmod u+w "$FILE_PATH"
  
  # Use sed to replace the problematic syntax
  # Replace 'Traits::template CallSeqFactory' with 'Traits::CallSeqFactory'
  sed -i '' 's/Traits::template CallSeqFactory/Traits::CallSeqFactory/g' "$FILE_PATH"
  
  echo "Patched gRPC-Core basic_seq.h file successfully"
else
  echo "Warning: Could not find $FILE_PATH to patch"
fi