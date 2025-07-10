#!/usr/bin/env python3
"""
EnvGym实验结果收集工具
用法: python3 collect_envgym_results.py [list|clean]
"""

import os
import shutil
import datetime
import sys
from pathlib import Path

# 配置
DATA_DIR = "/home/cc/EnvGym/data"
BACKUP_DIR = "/home/cc/EnvGym/tests/backup"

def get_timestamp():
    """获取时间戳"""
    return datetime.datetime.now().strftime("%Y%m%d_%H%M%S")

def collect_results():
    """收集实验结果"""
    data_path = Path(DATA_DIR)
    backup_path = Path(BACKUP_DIR)
    backup_path.mkdir(parents=True, exist_ok=True)
    
    print(f"🔍 扫描目录: {data_path}")
    print(f"📁 备份目录: {backup_path}")
    print("-" * 50)
    
    collected = 0
    total = 0
    
    for repo_dir in data_path.iterdir():
        if not repo_dir.is_dir() or repo_dir.name.startswith('.'):
            continue
            
        total += 1
        repo_name = repo_dir.name
        envgym_dir = repo_dir / "envgym"
        
        print(f"检查 {repo_name}: ", end="")
        
        if not envgym_dir.exists():
            print("❌ 无envgym目录")
            continue
            
        # 创建备份目录
        repo_backup_dir = backup_path / repo_name
        repo_backup_dir.mkdir(exist_ok=True)
        
        # 带时间戳的目录名
        timestamp_dir = repo_backup_dir / f"envgym-{get_timestamp()}"
        
        try:
            shutil.copytree(envgym_dir, timestamp_dir)
            file_count = sum(1 for _ in timestamp_dir.rglob('*') if _.is_file())
            size_mb = sum(f.stat().st_size for f in timestamp_dir.rglob('*') if f.is_file()) / (1024*1024)
            print(f"✅ {file_count}文件 {size_mb:.1f}MB")
            collected += 1
        except Exception as e:
            print(f"❌ 失败: {e}")
    
    print("-" * 50)
    print(f"完成! 检查了{total}个repo，收集了{collected}个结果")

def list_results():
    """列出收集的结果"""
    backup_path = Path(BACKUP_DIR)
    if not backup_path.exists():
        print("❌ 备份目录不存在")
        return
        
    print(f"📊 已收集的实验结果:")
    print("-" * 50)
    
    total_repos = 0
    total_files = 0
    total_size = 0
    
    for repo_dir in sorted(backup_path.iterdir()):
        if not repo_dir.is_dir() or repo_dir.name.startswith('.'):
            continue
            
        envgym_dirs = [d for d in repo_dir.iterdir() if d.is_dir() and d.name.startswith('envgym-')]
        if not envgym_dirs:
            continue
            
        total_repos += 1
        print(f"📁 {repo_dir.name}:")
        
        for envgym_dir in sorted(envgym_dirs, reverse=True):
            files = sum(1 for _ in envgym_dir.rglob('*') if _.is_file())
            size = sum(f.stat().st_size for f in envgym_dir.rglob('*') if f.is_file()) / (1024*1024)
            timestamp = envgym_dir.name.replace('envgym-', '')
            print(f"  └── {timestamp} ({files}文件, {size:.1f}MB)")
            total_files += files
            total_size += size
    
    print("-" * 50)
    print(f"总计: {total_repos}个repo, {total_files}个文件, {total_size:.1f}MB")

def clean_old():
    """清理旧备份，每个repo保留最新3个"""
    backup_path = Path(BACKUP_DIR)
    if not backup_path.exists():
        print("❌ 备份目录不存在")
        return
        
    print("🧹 清理旧备份 (每个repo保留最新3个)...")
    print("-" * 50)
    
    cleaned = 0
    for repo_dir in backup_path.iterdir():
        if not repo_dir.is_dir():
            continue
            
        envgym_dirs = [d for d in repo_dir.iterdir() if d.is_dir() and d.name.startswith('envgym-')]
        if len(envgym_dirs) <= 3:
            continue
            
        # 按时间排序，删除旧的
        envgym_dirs.sort(key=lambda x: x.name, reverse=True)
        old_dirs = envgym_dirs[3:]
        
        print(f"📁 {repo_dir.name}: 删除{len(old_dirs)}个旧备份")
        for old_dir in old_dirs:
            try:
                shutil.rmtree(old_dir)
                print(f"  🗑️ {old_dir.name}")
                cleaned += 1
            except Exception as e:
                print(f"  ❌ 删除失败: {e}")
    
    print("-" * 50)
    print(f"清理完成! 删除了{cleaned}个旧备份")

def main():
    """主函数"""
    if len(sys.argv) > 1:
        cmd = sys.argv[1].lower()
        if cmd == "list" or cmd == "ls":
            list_results()
        elif cmd == "clean":
            clean_old()
        elif cmd == "help" or cmd == "-h":
            print("用法:")
            print("  python3 collect_envgym_results.py        # 收集新结果")
            print("  python3 collect_envgym_results.py list   # 列出已收集结果")
            print("  python3 collect_envgym_results.py clean  # 清理旧备份")
        else:
            print("❌ 未知命令。使用 'help' 查看帮助")
    else:
        collect_results()

if __name__ == "__main__":
    main() 