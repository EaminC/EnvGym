#!/bin/bash
# EnvGym 构建脚本

set -e

echo "🚀 开始构建 EnvGym 环境..."

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

# 检查docker-compose是否安装
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose 未安装，请先安装 Docker Compose"
    exit 1
fi

# 检查.env文件
if [ ! -f .env ]; then
    echo "⚠️  .env 文件不存在，复制示例文件..."
    cp .env.example .env
    echo "📝 请编辑 .env 文件并填入你的API keys"
    echo "   然后重新运行此脚本"
    exit 1
fi

echo "🐳 构建 Docker 镜像..."
docker build -t envgym:latest -f envgym.dockerfile .

echo "📦 启动开发环境..."
docker-compose up -d

echo "✅ EnvGym 环境构建完成！"
echo ""
echo "🔗 可用服务："
echo "   - 开发环境: docker exec -it envgym-dev bash"
echo "   - Python应用: http://localhost:8000"
echo "   - Node.js应用: http://localhost:3000"
echo "   - 文档服务: http://localhost:4321"
echo ""
echo "🛠️  管理命令："
echo "   - 查看日志: docker-compose logs"
echo "   - 停止服务: docker-compose down"
echo "   - 重启服务: docker-compose restart"
