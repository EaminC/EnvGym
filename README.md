# EnvGym - 多语言开发环境平台

EnvGym是一个支持多种编程语言和开发工具的集成开发环境平台，旨在提供一致性的开发体验。
![image](https://github.com/user-attachments/assets/6664c32c-5e32-4712-b5f9-71b37e457be3)

## 特性

- 🐍 **Python支持**: 包含agent-squad、机器学习工具等
- 📱 **TypeScript/JavaScript**: 完整的前端开发环境
- ☕ **Java支持**: 企业级开发环境
- 🦀 **Rust支持**: 系统编程和高性能应用
- 🐹 **Go支持**: 云原生和微服务开发
- 🐳 **Docker化**: 一键部署和环境隔离
- 🤖 **AI集成**: 集成多种AI模型和工具

## 快速开始

### 使用Docker（推荐）

1. 克隆仓库：
```bash
git clone https://github.com/yourusername/EnvGym.git
cd EnvGym
```

2. 配置环境变量：
```bash
cp .env.example .env
# 编辑.env文件，填入你的API keys
```

3. 构建并运行环境：
```bash
docker build -t envgym -f envgym.dockerfile .
docker run -it --rm -v $(pwd):/workspace envgym
```

### 本地安装

#### Python环境
```bash
cd python
pip install -e .
```

#### TypeScript环境
```bash
cd typescript
npm install
npm run build
```

## 项目结构

```
EnvGym/
├── Agent0613/              # AI代理系统
├── python/                 # Python包和工具
├── typescript/             # TypeScript/JavaScript代码
├── examples/               # 示例和演示
├── docs/                   # 文档
├── data/                   # 数据和模型
├── test_agent_squad/       # 测试代码
└── tool_tests/            # 工具测试
```

## 配置

### API Keys

在`.env`文件中配置以下API keys：

- `OPENAI_API_KEY`: OpenAI API密钥
- `ANTHROPIC_API_KEY`: Anthropic API密钥
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`: AWS凭证

### 开发工具

项目包含以下开发工具：

- **Aider**: AI辅助编码
- **Codex**: 代码生成和分析
- **Agent Squad**: 多代理系统
- **各种兼容性工具**: 支持多语言包管理

## 示例

### Python Agent示例
```bash
cd examples/python
python main.py
```

### TypeScript开发
```bash
cd typescript
npm run test
```

### AI代理演示
```bash
cd Agent0613
python agent.py
```

## 贡献

欢迎贡献！请参阅[CONTRIBUTING.md](CONTRIBUTING.md)了解详细信息。

## 许可证

本项目采用MIT许可证 - 详见[LICENSE](LICENSE)文件。

## 支持

如有问题，请提交issue或联系维护者。
