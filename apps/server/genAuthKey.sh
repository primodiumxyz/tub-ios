#!/bin/bash

KEY_PATH="src/keys"
KEY_FILE="$KEY_PATH/AuthKey.p8"

# Get APPLE_AUTHKEY from .env file
if [ -f "../../.env" ]; then
    APPLE_AUTHKEY=$(grep "^APPLE_AUTHKEY=" "../../.env" | cut -d '=' -f2-)
else
    echo "Error: .env file not found in project root"
    exit 1
fi

# Create keys directory if it doesn't exist
mkdir -p "$KEY_PATH"

# Check if AUTHKEY env var exists
if [ -z "$APPLE_AUTHKEY" ]; then
    echo "Error: APPLE_AUTHKEY environment variable not set in .env"
    exit 1
fi

# Write AUTHKEY content to file, overwriting if exists
echo "$APPLE_AUTHKEY" > "$KEY_FILE"
echo "Generated AuthKey.p8 at $KEY_FILE"

# Set proper permissions
chmod 600 "$KEY_FILE"
