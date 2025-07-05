# 批量执行脚本使用说明

## 脚本文件

### 1. `run_agent_on_all_repos.sh` (完整版)

- 使用指定的虚拟环境路径
- 需要修改 `VENV_PATH` 变量为实际的虚拟环境路径
- 更严格的错误检查

### 2. `run_agent_simple.sh` (推荐)

- 使用 conda 环境管理
- 自动激活 `envgym` 环境
- 更简单易用

## 使用方法

### 方法 1：使用 conda 环境（推荐）

```bash
cd /Users/eamin/Desktop/data/学习资料/科研/kexin/0620/EnvGym/data
./run_agent_simple.sh
```

### 方法 2：使用指定路径的虚拟环境

1. 先修改 `run_agent_on_all_repos.sh` 中的 `VENV_PATH` 变量
2. 然后执行：

```bash
cd /Users/eamin/Desktop/data/学习资料/科研/kexin/0620/EnvGym/data
./run_agent_on_all_repos.sh
```

## 脚本功能

1. **自动遍历** `data` 目录下的所有子目录
2. **逐个进入** 每个仓库目录
3. **激活环境** 自动激活 `envgym` 虚拟环境
4. **执行程序** 运行 `Agent0613/agent.py`
5. **记录日志** 自动生成执行日志文件
6. **错误处理** 单个仓库失败不影响其他仓库执行
7. **进度显示** 显示执行进度和结果统计

## 当前将处理的仓库

脚本会自动处理以下目录：

- Metis
- rfuse
- ELECT
- anvil
- Silhouette
- Baleen
- acto
- flex
- gluetest
- probfuzz
- sixthsense
- exli
- Fairify
- SymMC
- CrossPrefetch
- P4Ctl
- RSNN
- TabPFN
- SEED-GNN
- Lottory
- Femu
- RelTR

## 日志文件

执行日志会保存在：
`execution_log_YYYYMMDD_HHMMSS.log`

日志包含：

- 每个仓库的执行状态
- 成功/失败统计
- 详细的时间戳
- 错误信息

## 注意事项

1. 确保 `envgym` 环境已经安装并可用
2. 确保 `Agent0613/agent.py` 文件存在
3. 每个仓库执行完成后会自动进入下一个
4. 如果某个仓库执行失败，脚本会继续执行其他仓库
5. 建议在执行前先备份重要数据

## 手动执行单个仓库

如果需要单独测试某个仓库：

```bash
cd /Users/eamin/Desktop/data/学习资料/科研/kexin/0620/EnvGym/data/仓库名
conda activate envgym
python /Users/eamin/Desktop/data/学习资料/科研/kexin/0620/EnvGym/Agent0613/agent.py
```
