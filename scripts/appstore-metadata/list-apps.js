/**
 * 列出 App Store Connect 中的所有 Apps
 */

import fetch from 'node-fetch';
import { generateToken, loadPrivateKey, loadEnvConfig } from './auth.js';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// 加载配置
const envConfig = loadEnvConfig(path.join(__dirname, '.env'));

const API_CONFIG = {
  keyId: envConfig.APPSTORE_KEY_ID,
  issuerId: envConfig.APPSTORE_ISSUER_ID,
  privateKey: loadPrivateKey(path.join(__dirname, envConfig.APPSTORE_KEY_PATH))
};

const BASE_URL = 'https://api.appstoreconnect.apple.com/v1';

function getHeaders() {
  const token = generateToken(API_CONFIG);
  return {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  };
}

async function apiRequest(endpoint) {
  const url = `${BASE_URL}${endpoint}`;
  const headers = getHeaders();

  const response = await fetch(url, { headers });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`API Error (${response.status}): ${error}`);
  }

  return response.json();
}

async function listApps() {
  try {
    console.log('📱 Fetching apps from App Store Connect...\n');

    const result = await apiRequest('/apps?limit=200');

    const apps = result.data || [];

    if (apps.length === 0) {
      console.log('No apps found.');
      return;
    }

    console.log(`Found ${apps.length} app(s):\n`);
    console.log('ID'.padEnd(15) + 'Name'.padEnd(40) + 'Bundle ID'.padEnd(30) + 'Status');
    console.log('─'.repeat(90));

    for (const app of apps) {
      const id = app.id;
      const name = app.attributes.name;
      const bundleId = app.attributes.bundleId;
      const status = app.attributes.appStoreState;

      console.log(
        id.padEnd(15) +
        name.substring(0, 38).padEnd(40) +
        bundleId.substring(0, 28).padEnd(30) +
        status
      );
    }

    console.log('\n💡 Usage: node update-metadata.js <appId>');
    console.log(`   Example: node update-metadata.js ${apps[0].id}`);

  } catch (error) {
    console.error(`❌ Error: ${error.message}`);
    process.exit(1);
  }
}

listApps();
