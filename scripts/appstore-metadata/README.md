# App Store Metadata Updater

App Store Connect 多语言元数据批量更新工具。

## 快速开始

### 1. 安装依赖

```bash
cd scripts/appstore-metadata
npm install
```

### 2. 配置 API 密钥

1. 登录 [App Store Connect](https://appstoreconnect.apple.com)
2. 进入 **用户和访问** → **API 密钥**
3. 点击 **+** 创建新密钥，给予 **Admin** 权限
4. 下载生成的 `.p8` 私钥文件
5. 记录 **密钥 ID** 和 **发行者 ID**

将 `.env.example` 复制为 `.env` 并填写：

```bash
cp .env.example .env
```

编辑 `.env`：
```
APPSTORE_KEY_ID=XXXXXXXXXX
APPSTORE_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APPSTORE_KEY_PATH=AuthKey_XXXXXXXXXX.p8
```

### 3. 运行更新

```bash
# 更新所有语言
node update-metadata.js <appId>

# 更新指定语言
node update-metadata.js <appId> zh-Hans ja en-US

# 示例
node update-metadata.js 1234567890
```

## 配置元数据

编辑 `metadata-config.js` 文件，修改各语言的：

- `name` - 应用名称
- `subtitle` - 副标题（30 字符）
- `keywords` - 关键词（100 字符，逗号分隔）
- `description` - 描述（4000 字符）

## 支持的语言

| 语言代码 | 语言 |
|---------|------|
| zh-Hans | 简体中文 |
| zh-Hant | 繁体中文 |
| ja | 日文 |
| ko | 韩文 |
| fr | 法文 |
| de | 德文 |
| es | 西班牙文 |
| it | 意大利文 |
| ru | 俄文 |
| pt-BR | 葡萄牙文 (巴西) |
| ar | 阿拉伯文 |
| th | 泰国语 |
| vi | 越南语 |
| ms | 马来西亚语 |
| id | 印度尼西亚语 |
| tr | 土耳其语 |
| pl | 波兰语 |
| nl | 荷兰语 |
| sv | 瑞典语 |
| uk | 乌克兰语 |
| he | 希伯来语 |
| hi | 印地语 |
| fil | 菲律宾语 |
| bn | 孟加拉语 |
| da | 丹麦语 |
| fi | 芬兰语 |
| nb | 挪威语 |
| pt-PT | 葡萄牙文 (葡萄牙) |
| el | 希腊语 |
| ca | 加泰罗尼亚语 |
| en-US, en-GB, en-CA, en-AU | 英语 (各国) |

## 注意事项

1. **速率限制**: API 有速率限制，脚本已内置 500ms 延迟
2. **字符限制**:
   - 副标题：最多 30 字符
   - 关键词：最多 100 字符（逗号分隔，无空格）
   - 描述：最多 4000 字符
3. **审核**: 修改元数据后可能需要重新审核
4. **私钥安全**: `.p8` 文件请妥善保管，不要提交到 Git

## 其他命令

```bash
# 生成 CSV 文件（可用于 Excel 管理）
npm run generate-csv

# 列出所有 Apps
npm run list-apps
```

## 故障排除

### 错误：401 Unauthorized
- 检查 `.env` 配置是否正确
- 确认 `.p8` 文件存在且路径正确
- 确认 API 密钥有 Admin 权限

### 错误：403 Forbidden
- API 密钥权限不足，需要在 App Store Connect 中提升权限

### 错误：409 Conflict
- 该语言的本地化已存在，脚本会自动切换到更新模式
