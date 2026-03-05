#!/bin/bash
set -e

ACCOUNT_ID="02c11b4b04abe771c7df7df0cdd03c14"
API_TOKEN="bRpjZaJQSOQPT1iaLIX9XpS9EQ2OUaqnPK0Aeap5"
PROJECT_NAME="lobster-ai-website"

echo "=== Direct Upload Deploy ==="

# Step 1: Create deployment and get upload URL
echo "Step 1: Creating deployment..."
DEPLOY_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/pages/projects/${PROJECT_NAME}/deployments" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"branch":"main","commit_message":"Direct upload deploy"}')

echo "Response: $DEPLOY_RESPONSE"

# Parse deployment ID and upload URL
DEPLOYMENT_ID=$(echo "$DEPLOY_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result']['id'])" 2>/dev/null)
UPLOAD_URL=$(echo "$DEPLOY_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result']['upload_url'])" 2>/dev/null)

if [ -z "$DEPLOYMENT_ID" ] || [ -z "$UPLOAD_URL" ]; then
  echo "Failed to create deployment"
  echo "$DEPLOY_RESPONSE"
  exit 1
fi

echo "✓ Deployment created: $DEPLOYMENT_ID"
echo "✓ Upload URL obtained"

# Step 2: Prepare upload bundle
echo ""
echo "Step 2: Preparing upload bundle..."
cd /root/.openclaw/workspace/lobster-ai-website/public

# Create manifest file
MANIFEST='{}'
for file in $(find . -type f | sed 's|^\./||'); do
  HASH=$(sha256sum "$file" | cut -d' ' -f1 | xxd -r -p | base64 -w0 2>/dev/null || openssl dgst -sha256 -binary "$file" | base64 -w0)
  MANIFEST=$(echo "$MANIFEST" | python3 -c "import sys,json; d=json.load(sys.stdin); d['$file']={'hash':'$HASH'}; json.dump(d,sys.stdout)")
done

echo '{"manifest":{}}' > /tmp/manifest.json

echo "✓ Manifest prepared"

# Step 3: Upload files
echo ""
echo "Step 3: Uploading files..."

# Create multipart form data
BOUNDARY="----FormBoundary$(openssl rand -hex 8)"

# Build the multipart body
(
  echo "--${BOUNDARY}"
  echo 'Content-Disposition: form-data; name="manifest"'
  echo 'Content-Type: application/json'
  echo ''
  cat /tmp/manifest.json
  echo ""
  
  # Add files
  for file in $(find . -type f | sed 's|^\./||'); do
    filename=$(basename "$file")
    echo "--${BOUNDARY}"
    echo "Content-Disposition: form-data; name=\"$file\"; filename=\"$filename\""
    echo "Content-Type: application/octet-stream"
    echo ''
    cat "$file"
    echo ""
  done
  
  echo "--${BOUNDARY}--"
) > /tmp/upload_body.txt

# Upload
UPLOAD_RESPONSE=$(curl -s -X POST "$UPLOAD_URL" \
  -H "Content-Type: multipart/form-data; boundary=${BOUNDARY}" \
  --data-binary @/tmp/upload_body.txt)

echo "Upload response: $UPLOAD_RESPONSE"

if echo "$UPLOAD_RESPONSE" | grep -q "success"; then
  echo "✓ Upload successful"
  echo ""
  echo "=== Deployment Complete ==="
  echo "URL: https://${PROJECT_NAME}.pages.dev"
  echo ""
  echo "Next steps:"
  echo "1. Wait 1-2 minutes for deployment to complete"
  echo "2. Visit https://${PROJECT_NAME}.pages.dev"
  echo "3. Add custom domain lobsterai.tech in Cloudflare Dashboard"
else
  echo "✗ Upload failed"
  echo "$UPLOAD_RESPONSE"
  exit 1
fi
