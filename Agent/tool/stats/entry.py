import json
import os
import sys
import requests
from pathlib import Path
from datetime import datetime, timezone
from typing import Dict, Any, Optional, List
from dotenv import load_dotenv

# Add Agent directory to path for importing prompt modules
agent_dir = os.path.join(os.path.dirname(__file__), '..', '..')
if agent_dir not in sys.path:
    sys.path.insert(0, agent_dir)

class StatsTool:
    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.stats_file = "envgym/stat.json"
        
        # Try to load environment variables from multiple possible locations
        possible_env_paths = [
            Path(__file__).parent.parent.parent / '.env',  # EnvGym/.env
            Path(__file__).parent.parent.parent.parent / '.env',  # parent of EnvGym
            Path.cwd() / '.env',  # Current working directory
        ]
        
        for env_path in possible_env_paths:
            if env_path.exists():
                load_dotenv(env_path)
                if self.verbose:
                    print(f"Loaded environment from: {env_path}")
                break
        else:
            print("Warning: No .env file found")
        
        # Get configuration from environment
        self.api_key = os.getenv("FORGE_API_KEY", "").strip('"').strip("'")
        self.base_url = os.getenv("FORGE_BASE_URL", "https://api.forge.tensorblock.co/v1").strip('"').strip("'")
        
        # Parse MODEL to get provider and model
        model_config = os.getenv("MODEL")
        if not model_config:
            print("Error: MODEL environment variable not set")
            print("Please set MODEL in your .env file (e.g., MODEL=OpenAI/gpt-4.1-mini)")
            sys.exit(1)
        
        model_config = model_config.strip('"').strip("'")
        if '/' in model_config:
            self.provider, self.model = model_config.split('/', 1)
        else:
            self.provider = "OpenAI"
            self.model = model_config
        
        if not self.api_key or self.api_key == "your-forge-api-key-here":
            print("Warning: FORGE_API_KEY not found or not set properly")
    
    def get_api_stats(self) -> Optional[Dict[str, Any]]:
        """获取API用量统计信息"""
        try:
            if not self.api_key:
                print("Error: FORGE_API_KEY not available")
                return None
            
            # 构建API请求URL
            # 确保base_url不以/结尾，避免重复的/
            base_url = self.base_url.rstrip('/')
            stats_url = f"{base_url}/stats/?provider={self.provider}&model={self.model}"
            
            headers = {
                "Authorization": f"Bearer {self.api_key}"
            }
            
            if self.verbose:
                print(f"Requesting API stats from: {stats_url}")
            
            response = requests.get(stats_url, headers=headers, timeout=30)
            
            if response.status_code == 200:
                stats_data = response.json()
                if self.verbose:
                    print("Successfully retrieved API stats")
                return stats_data
            else:
                print(f"Error getting API stats: HTTP {response.status_code}")
                print(f"Response: {response.text}")
                return None
                
        except requests.exceptions.RequestException as e:
            print(f"Network error getting API stats: {str(e)}")
            return None
        except json.JSONDecodeError as e:
            print(f"Error parsing API response: {str(e)}")
            return None
        except Exception as e:
            print(f"Unexpected error getting API stats: {str(e)}")
            return None
    
    def get_all_paginated_stats(self, session_start: str, session_end: str) -> Optional[List[Dict[str, Any]]]:
        """获取指定时间范围内的统计数据"""
        try:
            if not self.api_key:
                print("Error: FORGE_API_KEY not available")
                return None
            
            # 使用新的API接口获取指定时间范围的统计数据
            base_url = self.base_url.rstrip('/')
            
            headers = {
                "Authorization": f"Bearer {self.api_key}"
            }
            
            # 设置查询参数，与curl命令完全一致
            params = {
                "provider_name": self.provider,
                "model_name": self.model,
                "started_at": session_start,
                "ended_at": session_end,
                "limit": 2000
            }
            
            if self.verbose:
                print(f"Requesting data with params: {params}")
            
            response = requests.get(
                f"{base_url}/statistic/usage/realtime",
                headers=headers,
                params=params,
                timeout=30
            )
            
            if response.status_code == 200:
                all_data = response.json()
                if self.verbose:
                    print(f"Retrieved {len(all_data)} total records")
                return all_data
            else:
                print(f"Error getting data: HTTP {response.status_code}")
                print(f"Response: {response.text}")
                return None
                
        except requests.exceptions.RequestException as e:
            print(f"Network error getting paginated stats: {str(e)}")
            return None
        except json.JSONDecodeError as e:
            print(f"Error parsing paginated API response: {str(e)}")
            return None
        except Exception as e:
            print(f"Unexpected error getting paginated stats: {str(e)}")
            return None
    
    def load_existing_stats(self) -> Dict[str, Any]:
        """加载现有的统计文件"""
        if os.path.exists(self.stats_file):
            try:
                with open(self.stats_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except (json.JSONDecodeError, IOError) as e:
                print(f"Warning: Could not load existing stats file: {str(e)}")
        
        # 返回默认结构
        return {
            "session_start": None,
            "session_end": None,
            "start_stats": None,
            "end_stats": None,
            "usage_delta": None,
            "execution_info": {},
            "api_info": {
                "provider_name": None,
                "model": None
            }
        }
    
    def save_stats(self, stats_data: Dict[str, Any]):
        """保存统计信息到文件"""
        try:
            os.makedirs(os.path.dirname(self.stats_file), exist_ok=True)
            
            with open(self.stats_file, 'w', encoding='utf-8') as f:
                json.dump(stats_data, f, indent=2, ensure_ascii=False)
            
            if self.verbose:
                print(f"Stats saved to: {self.stats_file}")
                
        except Exception as e:
            print(f"Error saving stats: {str(e)}")
    
    def calculate_usage_delta(self, start_stats: Dict[str, Any], end_stats: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """计算使用量差值"""
        try:
            if not start_stats or not end_stats:
                return None
            
            # API返回的是列表格式，取第一个元素
            start_data = start_stats[0] if isinstance(start_stats, list) and start_stats else start_stats
            end_data = end_stats[0] if isinstance(end_stats, list) and end_stats else end_stats
            
            delta = {}
            
            # 计算各种使用量的差值
            for key in ['input_tokens', 'output_tokens', 'total_tokens', 'requests_count']:
                start_val = start_data.get(key, 0)
                end_val = end_data.get(key, 0)
                delta[key] = end_val - start_val
            
            # 计算成本差值
            start_cost = start_data.get('cost', 0)
            end_cost = end_data.get('cost', 0)
            delta['cost'] = end_cost - start_cost
            
            return delta
            
        except Exception as e:
            print(f"Error calculating usage delta: {str(e)}")
            return None
    
    def record_session_start(self):
        """记录会话开始时的统计信息"""
        print("Recording session start stats...")
        
        stats_data = self.load_existing_stats()
        current_time = datetime.now(timezone.utc).isoformat()
        
        # 设置开始统计为全0，表示从0开始
        start_stats = {
            "provider_name": self.provider,
            "model": self.model,
            "input_tokens": 0,
            "output_tokens": 0,
            "total_tokens": 0,
            "requests_count": 0,
            "cost": 0.0
        }
        
        stats_data["session_start"] = current_time
        stats_data["start_stats"] = [start_stats]
        
        # 保存API信息
        stats_data["api_info"]["provider_name"] = self.provider
        stats_data["api_info"]["model"] = self.model
        
        self.save_stats(stats_data)
        
        if self.verbose:
            print(f"Session start recorded at: {current_time}")
            print(f"API Info: {self.provider} - {self.model}")
            print(f"Starting from: 0 tokens, $0.000000")
    
    def record_session_end(self):
        """记录会话结束时的统计信息"""
        print("Recording session end stats...")
        
        stats_data = self.load_existing_stats()
        current_time = datetime.now(timezone.utc).isoformat()
        
        # 获取会话开始时间
        session_start = stats_data.get("session_start")
        if not session_start:
            print("Warning: No session start time found, using current time")
            session_start = current_time
        
        # 获取会话时间范围内的所有分页数据
        all_session_data = self.get_all_paginated_stats(session_start, current_time)
        
        stats_data["session_end"] = current_time
        
        if all_session_data:
            # 聚合会话时间范围内的所有数据
            total_input_tokens = sum(item.get("input_tokens", 0) for item in all_session_data)
            total_output_tokens = sum(item.get("output_tokens", 0) for item in all_session_data)
            total_tokens = sum(item.get("tokens", 0) for item in all_session_data)
            total_cost = sum(float(item.get("cost", 0)) for item in all_session_data)
            requests_count = len(all_session_data)
            
            # 创建聚合统计
            session_stats = {
                "provider_name": self.provider,
                "model": self.model,
                "input_tokens": total_input_tokens,
                "output_tokens": total_output_tokens,
                "total_tokens": total_tokens,
                "requests_count": requests_count,
                "cost": total_cost
            }
            
            stats_data["end_stats"] = [session_stats]
            stats_data["usage_delta"] = session_stats
            
            print(f"Session usage summary (from {session_start} to {current_time}):")
            print(f"  - Total requests: {requests_count}")
            print(f"  - Input tokens: {total_input_tokens:,}")
            print(f"  - Output tokens: {total_output_tokens:,}")
            print(f"  - Total tokens: {total_tokens:,}")
            print(f"  - Cost: ${total_cost:.6f}")
        else:
            stats_data["end_stats"] = []
            stats_data["usage_delta"] = None
            print("No usage data found for session time range")
        
        self.save_stats(stats_data)
        
        if self.verbose:
            print(f"Session end recorded at: {current_time}")
            if all_session_data:
                print(f"Session total usage: {sum(item.get('tokens', 0) for item in all_session_data):,} tokens, ${sum(float(item.get('cost', 0)) for item in all_session_data):.6f}")
    
    def run(self, action: str = "check"):
        """执行统计工具
        
        Args:
            action: 执行的操作，可以是 "start", "end", "check"
        """
        try:
            if action == "start":
                self.record_session_start()
            elif action == "end":
                self.record_session_end()
            elif action == "check":
                # 只检查当前API状态
                current_stats = self.get_api_stats()
                if current_stats:
                    print("Current API stats:")
                    if isinstance(current_stats, list) and current_stats:
                        api_data = current_stats[0]
                        print(f"Provider: {api_data.get('provider_name')}")
                        print(f"Model: {api_data.get('model')}")
                        print(f"Input tokens: {api_data.get('input_tokens', 0):,}")
                        print(f"Output tokens: {api_data.get('output_tokens', 0):,}")
                        print(f"Total tokens: {api_data.get('total_tokens', 0):,}")
                        print(f"Requests count: {api_data.get('requests_count', 0):,}")
                        print(f"Cost: ${api_data.get('cost', 0):.6f}")
                    else:
                        print(json.dumps(current_stats, indent=2, ensure_ascii=False))
                else:
                    print("Could not retrieve API stats")
            else:
                print(f"Unknown action: {action}. Use 'start', 'end', or 'check'")
                
        except Exception as e:
            print(f"Error during stats execution: {str(e)}")

def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description="API Stats Tool")
    parser.add_argument("action", choices=["start", "end", "check"], 
                       help="Action to perform")
    parser.add_argument("--verbose", "-v", action="store_true",
                       help="Enable verbose output")
    
    args = parser.parse_args()
    
    tool = StatsTool(verbose=args.verbose)
    tool.run(args.action)

if __name__ == "__main__":
    main() 