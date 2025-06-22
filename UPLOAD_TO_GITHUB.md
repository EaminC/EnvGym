# 上传 EnvGym 到 GitHub 指南

## 前置准备

1. **确保已删除嵌套的 .git 文件夹**
   ```bash
   find . -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true
   ```

2. **检查敏感信息**
   - 确保 `.env` 文件不包含在仓库中
   - 检查代码中是否有硬编码的 API keys

## 上传步骤

### 1. 在 GitHub 上创建新仓库

访问 [GitHub](https://github.com) 并创建一个新的仓库，建议命名为 `EnvGym`

### 2. 连接到远程仓库

```bash
# 添加远程仓库（替换为你的GitHub用户名）
git remote add origin https://github.com/yourusername/EnvGym.git

# 推送到 GitHub
git branch -M main
git push -u origin main
```

### 3. 配置仓库设置

在 GitHub 仓库设置中：

- **描述**: "多语言开发环境平台 - 支持Python、TypeScript、Java、Rust、Go等"
- **Topics**: 添加标签如 `docker`, `ai`, `development-environment`, `multi-language`
- **README**: 已自动生成
- **License**: 选择适当的开源许可证

### 4. 设置 GitHub Secrets（如果需要CI/CD）

在仓库的 Settings > Secrets and variables > Actions 中添加：

- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## 协作设置

### 分支保护规则

建议在 Settings > Branches 中设置：

- 保护 `main` 分支
- 要求 pull request reviews
- 要求状态检查通过

### 问题模板

创建 `.github/ISSUE_TEMPLATE/` 目录并添加问题模板

### 贡献指南

参考项目中的 `CONTRIBUTING.md` 文件

## 本地开发设置

其他开发者克隆仓库后的设置步骤：

```bash
# 克隆仓库
git clone https://github.com/yourusername/EnvGym.git
cd EnvGym

# 复制环境变量文件
cp .env.example .env
# 编辑 .env 文件填入 API keys

# 构建和运行
chmod +x build.sh
./build.sh
```

## 注意事项

- 🔒 **永远不要提交 `.env` 文件或任何包含真实 API keys 的文件**
- 📝 定期更新 README.md 和文档
- 🏷️ 使用语义化版本标签（如 v1.0.0）
- 🐛 及时修复安全漏洞
- 📊 监控仓库的 Dependencies 和 Security alerts

## 推荐的 GitHub Apps

- **Dependabot**: 自动依赖更新
- **CodeQL**: 代码安全分析
- **Actions**: CI/CD 自动化

## 社区建设

- 创建详细的文档
- 提供示例和教程
- 回应 issues 和 pull requests
- 定期发布更新日志
