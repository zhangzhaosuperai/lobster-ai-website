#!/bin/bash
set -e

ACCOUNT_ID="02c11b4b04abe771c7df7df0cdd03c14"
API_TOKEN="bRpjZaJQSOQPT1iaLIX9XpS9EQ2OUaqnPK0Aeap5"
PROJECT_NAME="lobster-ai-website"

echo "=== Lobster AI Website Deployment ==="
echo "Account ID: ${ACCOUNT_ID}"
echo "Project: ${PROJECT_NAME}"
echo ""

# Step 1: Check if project exists
echo "Step 1: Checking if project exists..."
PROJECT_CHECK=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/pages/projects/${PROJECT_NAME}" \
  -H "Authorization: Bearer ${API_TOKEN}")

if echo "$PROJECT_CHECK" | grep -q "\"success\":false"; then
  echo "Project not found. Creating new project..."
  
  CREATE_RESULT=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/pages/projects" \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"${PROJECT_NAME}\",\"production_branch\":\"main\"}")
  
  if echo "$CREATE_RESULT" | grep -q "\"success\":true"; then
    echo "✓ Project created successfully"
  else
    echo "✗ Failed to create project:"
    echo "$CREATE_RESULT" | python3 -m json.tool 2>/dev/null || echo "$CREATE_RESULT"
    exit 1
  fi
else
  echo "✓ Project already exists"
fi

# Step 2: Create deployment
echo ""
echo "Step 2: Creating deployment..."
DEPLOY_RESULT=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/pages/projects/${PROJECT_NAME}/deployments" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"branch":"main","commit_message":"Initial deployment"}')

if echo "$DEPLOY_RESULT" | grep -q "\"success\":true"; then
  echo "✓ Deployment created successfully"
  echo ""
  echo "Deployment details:"
  echo "$DEPLOY_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"  ID: {d['result']['id']}\"); print(f\"  URL: {d['result']['url']}\")" 2>/dev/null || echo "$DEPLOY_RESULT"
else
  echo "✗ Deployment failed:"
  echo "$DEPLOY_RESULT" | python3 -m json.tool 2>/dev/null || echo "$DEPLOY_RESULT"
  exit 1
fi

echo ""
echo "=== Deployment Summary ==="
echo "Project: ${PROJECT_NAME}"
echo "Account: ${ACCOUNT_ID}"
echo ""
echo "Your website will be available at:"
echo "  https://${PROJECT_NAME}.pages.dev"
echo ""
echo "Next steps:"
echo "1. Wait 1-2 minutes for deployment to complete"
echo "2. Visit the URL above to verify"
echo "3. Add custom domain in Cloudflare Dashboard"
echo ""
echo "Done!"
