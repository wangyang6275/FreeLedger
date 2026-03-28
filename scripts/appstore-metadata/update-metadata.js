/**
 * App Store Connect 元数据批量更新脚本
 *
 * 使用方法：
 * 1. npm install 安装依赖
 * 2. 配置 .env 文件（见 .env.example）
 * 3. node update-metadata.js [appId] [locales...]
 *
 * 示例：
 * - node update-metadata.js 1234567890              # 更新所有语言
 * - node update-metadata.js 1234567890 zh-Hans ja  # 只更新简体中文和日文
 */

import fetch from 'node-fetch';
import { generateToken, loadPrivateKey, loadEnvConfig } from './auth.js';
import { metadata } from './metadata-config.js';
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

/**
 * 生成 API 请求头
 */
function getHeaders() {
  const token = generateToken(API_CONFIG);
  return {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  };
}

/**
 * API 请求封装
 */
async function apiRequest(endpoint, options = {}) {
  const url = `${BASE_URL}${endpoint}`;
  const headers = getHeaders();

  const response = await fetch(url, {
    ...options,
    headers: {
      ...headers,
      ...options.headers
    }
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`API Error (${response.status}): ${error}`);
  }

  return response.json();
}

/**
 * 获取 App 信息
 */
async function getApp(appId) {
  console.log(`📱 Fetching app ${appId}...`);
  return await apiRequest(`/apps/${appId}`);
}

/**
 * 获取 App 的本地化列表
 */
async function getAppListings(appId) {
  console.log(`📋 Fetching app listings for ${appId}...`);
  const result = await apiRequest(`/apps/${appId}/appStoreListings`);
  return result.data || [];
}

/**
 * 创建新的 App Store 本地化
 */
async function createAppListing(appId, locale, data) {
  console.log(`➕ Creating listing for ${locale}...`);

  const body = {
    data: {
      type: 'appStoreListings',
      relationships: {
        app: {
          data: { type: 'apps', id: appId }
        }
      },
      attributes: {
        locale
      }
    }
  };

  // 添加可选字段
  if (data.name) body.data.attributes.name = data.name;
  if (data.subtitle) body.data.attributes.subtitle = data.subtitle;
  if (data.description) body.data.attributes.description = data.description;
  if (data.keywords) body.data.attributes.keywords = data.keywords;

  return await apiRequest('/appStoreListings', {
    method: 'POST',
    body: JSON.stringify(body)
  });
}

/**
 * 更新现有的 App Store 本地化
 */
async function updateAppListing(listingId, data) {
  console.log(`✏️ Updating listing ${listingId}...`);

  const body = {
    data: {
      type: 'appStoreListings',
      id: listingId,
      attributes: {}
    }
  };

  // 添加更新的字段
  if (data.name !== undefined) body.data.attributes.name = data.name;
  if (data.subtitle !== undefined) body.data.attributes.subtitle = data.subtitle;
  if (data.description !== undefined) body.data.attributes.description = data.description;
  if (data.keywords !== undefined) body.data.attributes.keywords = data.keywords;

  return await apiRequest(`/appStoreListings/${listingId}`, {
    method: 'PATCH',
    body: JSON.stringify(body)
  });
}

/**
 * 获取或创建本地化
 */
async function getOrCreateListing(appId, locale, listings) {
  const existing = listings.find(l => l.attributes.locale === locale);

  if (existing) {
    return { id: existing.id, action: 'update' };
  }

  const created = await createAppListing(appId, locale, metadata.locales[locale] || metadata.default);
  return { id: created.data.id, action: 'create' };
}

/**
 * 主函数
 */
async function main() {
  const args = process.argv.slice(2);

  if (args.length < 1) {
    console.log('❌ Usage: node update-metadata.js <appId> [locales...]');
    console.log('Example: node update-metadata.js 1234567890 zh-Hans ja en-US');
    process.exit(1);
  }

  const appId = args[0];
  const targetLocales = args.length > 1 ? args.slice(1) : Object.keys(metadata.locales);

  console.log('🚀 Starting App Store metadata update...');
  console.log(`📱 App ID: ${appId}`);
  console.log(`🌍 Locales: ${targetLocales.join(', ') || 'all'}`);

  try {
    // 获取 App 信息
    const appData = await getApp(appId);
    console.log(`✅ Found app: ${appData.data.attributes.name}`);

    // 获取现有本地化
    const listings = await getAppListings(appId);
    console.log(`📄 Found ${listings.length} existing listings`);

    // 更新每个语言
    for (const locale of targetLocales) {
      const localeData = metadata.locales[locale] || metadata.default;

      console.log(`\n--- ${locale} ---`);

      try {
        const result = await getOrCreateListing(appId, locale, listings);

        if (result.action === 'update') {
          await updateAppListing(result.id, localeData);
          console.log(`✅ Updated ${locale}`);
        } else {
          console.log(`✅ Created ${locale}`);
        }
      } catch (error) {
        console.error(`❌ Failed ${locale}: ${error.message}`);
      }

      // 避免速率限制
      await new Promise(resolve => setTimeout(resolve, 500));
    }

    console.log('\n🎉 Update complete!');

  } catch (error) {
    console.error(`\n❌ Error: ${error.message}`);
    process.exit(1);
  }
}

main();
