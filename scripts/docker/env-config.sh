#!/bin/sh

# This script replaces environment variables in the built React app
# It runs at container startup to inject runtime environment variables

set -e

echo "Configuring environment variables for Sky High Booker..."

# Define the path to the built JS files
JS_FILES_PATH="/usr/share/nginx/html/assets"

# Replace environment variables in JS files if they exist
if [ -d "$JS_FILES_PATH" ]; then
    for file in $JS_FILES_PATH/*.js; do
        if [ -f "$file" ]; then
            # Replace placeholder environment variables with actual values
            sed -i "s|VITE_AWS_REGION_PLACEHOLDER|${VITE_AWS_REGION:-us-east-1}|g" "$file"
            sed -i "s|VITE_AWS_USER_POOL_ID_PLACEHOLDER|${VITE_AWS_USER_POOL_ID:-}|g" "$file"
            sed -i "s|VITE_AWS_USER_POOL_CLIENT_ID_PLACEHOLDER|${VITE_AWS_USER_POOL_CLIENT_ID:-}|g" "$file"
            sed -i "s|VITE_AWS_API_GATEWAY_URL_PLACEHOLDER|${VITE_AWS_API_GATEWAY_URL:-}|g" "$file"
            sed -i "s|VITE_AWS_S3_BUCKET_PLACEHOLDER|${VITE_AWS_S3_BUCKET:-}|g" "$file"
        fi
    done
fi

echo "Environment configuration completed."