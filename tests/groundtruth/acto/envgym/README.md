# Acto Docker Environment Test

## 使用方法

### 一键测试
```bash
./envgym/envbench.sh
```

这个脚本会：
1. 自动检测是否在 Docker 容器内
2. 如果不在容器内，自动构建 Docker 镜像
3. 在容器内运行完整的环境测试
4. 显示测试结果

### 手动测试 (可选)
```bash
# 1. 构建 Docker 镜像
docker build -f envgym/envgym.dockerfile -t acto-env-test .

# 2. 运行环境测试
docker run -it --rm -v $(pwd):/home/cc/EnvGym/data/acto acto-env-test ./envgym/envbench.sh
```

## 测试内容

脚本会检查：
- 系统依赖 (Python 3.12+, Go 1.22+, kubectl, kind, helm, git, make)
- Python 包安装 (核心依赖和开发依赖)
- Acto 模块导入和功能
- CLI 工具可用性
- 构建系统 (make)
- 基础代码执行
- 配置和数据访问
- YAML/JSON 处理
- Kubernetes 客户端
- 环境变量设置

## 新 Dockerfile 特点

新的 `envgym.dockerfile` 相比之前的版本：
- 移除了虚拟环境，直接使用全局 Python
- 更新了工具版本 (Go 1.22.4, Helm v3.14.4, Kind v0.22.0)
- 简化了依赖安装流程
- 设置了必要的环境变量 (ACTO_HOME, PYTHONPATH, KUBECONFIG)

## 注意事项

- 脚本会自动检测可用的 shell
- 如果遇到平台警告，这是正常的，不影响功能
- 所有测试都是 hardcoded，不依赖自动化测试框架
- 测试结果会显示 PASS/FAIL/WARN 统计 