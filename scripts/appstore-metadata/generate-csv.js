/**
 * 生成 CSV 文件，方便在 Excel 中管理多语言元数据
 */

import fs from 'fs';
import { metadata } from './metadata-config.js';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function escapeCSV(value) {
  if (!value) return '';
  // 处理包含逗号、引号、换行的情况
  const str = String(value);
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return '"' + str.replace(/"/g, '""') + '"';
  }
  return str;
}

function generateCSV() {
  const locales = Object.keys(metadata.locales);

  // CSV 头部
  const headers = ['Locale', 'Name', 'Subtitle', 'Keywords', 'Description'];

  // CSV 行
  const rows = [headers.join(',')];

  for (const locale of locales) {
    const data = metadata.locales[locale];
    const defaultData = metadata.default;

    const row = [
      locale,
      escapeCSV(data.name || defaultData.name),
      escapeCSV(data.subtitle || defaultData.subtitle),
      escapeCSV(data.keywords || defaultData.keywords),
      escapeCSV(data.description || defaultData.description)
    ];

    rows.push(row.join(','));
  }

  const csvContent = rows.join('\n');
  const outputPath = path.join(__dirname, 'metadata.csv');

  fs.writeFileSync(outputPath, csvContent, 'utf8');
  console.log(`✅ CSV generated: ${outputPath}`);
  console.log(`📊 Total locales: ${locales.length}`);
}

generateCSV();
