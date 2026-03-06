#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const https = require('https');

const ACCOUNT_ID = '02c11b4b04abe771c7df7df0cdd03c14';
const API_TOKEN = 'bRpjZaJQSOQPT1iaLIX9XpS9EQ2OUaqnPK0Aeap5';
const PROJECT_NAME = 'lobster-ai-website';

function apiRequest(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.cloudflare.com',
      port: 443,
      path: `/client/v4${path}`,
      method: method,
      headers: {
        'Authorization': `Bearer ${API_TOKEN}`,
        'Content-Type': 'application/json'
      }
    };

    if (data) {
      const jsonData = JSON.stringify(data);
      options.headers['Content-Length'] = Buffer.byteLength(jsonData);
    }

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          resolve(json);
        } catch (e) {
          resolve({ success: false, raw: data });
        }
      });
    });

    req.on('error', reject);
    
    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

async function deploy() {
  console.log('=== Lobster AI Website Deployment ===\n');

  // Step 1: Check if project exists
  console.log('Step 1: Checking project...');
  const projectRes = await apiRequest('GET', `/accounts/${ACCOUNT_ID}/pages/projects/${PROJECT_NAME}`);
  
  if (!projectRes.success && projectRes.errors?.[0]?.code !== 8000007) {
    console.log('Error:', projectRes.errors);
    process.exit(1);
  }

  if (!projectRes.success) {
    // Create project
    console.log('Creating project...');
    const createRes = await apiRequest('POST', `/accounts/${ACCOUNT_ID}/pages/projects`, {
      name: PROJECT_NAME,
      production_branch: 'main'
    });
    
    if (!createRes.success) {
      console.log('Failed to create project:', createRes.errors);
      process.exit(1);
    }
    console.log('✓ Project created\n');
  } else {
    console.log('✓ Project exists\n');
  }

  // Step 2: Create deployment
  console.log('Step 2: Creating deployment...');
  const deployRes = await apiRequest('POST', `/accounts/${ACCOUNT_ID}/pages/projects/${PROJECT_NAME}/deployments`, {
    branch: 'main',
    commit_message: 'Initial deployment'
  });

  if (!deployRes.success) {
    console.log('Failed:', deployRes.errors);
    process.exit(1);
  }

  console.log('✓ Deployment created');
  console.log('  ID:', deployRes.result.id);
  console.log('  URL:', deployRes.result.url);
  console.log('\n=== Deployment Complete ===');
  console.log('Website will be available at:');
  console.log('  https://' + PROJECT_NAME + '.pages.dev');
}

deploy().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
