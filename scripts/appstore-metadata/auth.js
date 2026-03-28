/**
 * App Store Connect API 认证模块
 *
 * 使用方法：
 * 1. 在 App Store Connect -> 用户和访问 -> API 密钥 创建 API 密钥
 * 2. 下载 AuthKey_XXXXXXXXXX.p8 文件
 * 3. 配置 .env 文件
 */

import fs from 'fs';
import jwt from 'jsonwebtoken';

const ALGORITHM = 'ES256';
const ISSUER = 'https://appstoreconnect.apple.com';
const AUDIENCE = 'appstoreconnect-v1';

/**
 * 生成 JWT Token
 * @param {Object} config - 认证配置
 * @param {string} config.keyId - API 密钥 ID (Issuer ID)
 * @param {string} config.privateKey - 私钥内容或路径
 * @param {string} config.issuerId - 发行者 ID
 * @returns {string} JWT Token
 */
export function generateToken(config) {
  const now = Math.floor(Date.now() / 1000);

  const header = {
    alg: ALGORITHM,
    kid: config.keyId
  };

  const payload = {
    iss: config.issuerId,
    iat: now,
    exp: now + 120, // 2 分钟有效期
    aud: AUDIENCE
  };

  const signOptions = {
    algorithm: ALGORITHM,
    expiresIn: '2m',
    header
  };

  return jwt.sign(payload, config.privateKey, signOptions);
}

/**
 * 从文件加载私钥
 * @param {string} keyPath - 私钥文件路径
 * @returns {string} 私钥内容
 */
export function loadPrivateKey(keyPath) {
  const content = fs.readFileSync(keyPath, 'utf8');
  return content.trim();
}

/**
 * 加载 .env 配置
 * @param {string} envPath - .env 文件路径
 * @returns {Object} 配置对象
 */
export function loadEnvConfig(envPath) {
  if (!fs.existsSync(envPath)) {
    throw new Error(`.env file not found: ${envPath}`);
  }

  const content = fs.readFileSync(envPath, 'utf8');
  const config = {};

  content.split('\n').forEach(line => {
    const trimmed = line.trim();
    if (trimmed && !trimmed.startsWith('#')) {
      const [key, ...valueParts] = trimmed.split('=');
      if (key && valueParts.length > 0) {
        config[key.trim()] = valueParts.join('=').trim();
      }
    }
  });

  return config;
}

export default { generateToken, loadPrivateKey, loadEnvConfig };
