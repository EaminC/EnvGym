import json
import os
import sys
import requests
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, Optional
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
        self.base_url = os.getenv("FORGE_BASE_URL", "https://api.forge.tensorblock.co").strip('"').strip("'")
        
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
            stats_url = f"{base_url}/stats/?provider=OpenAI&model=gpt-4.1"
            
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
        current_time = datetime.now().isoformat()
        
        # 获取当前API统计
        current_stats = self.get_api_stats()
        
        stats_data["session_start"] = current_time
        stats_data["start_stats"] = current_stats
        
        # 保存API信息
        if current_stats and isinstance(current_stats, list) and current_stats:
            api_data = current_stats[0]
            stats_data["api_info"]["provider_name"] = api_data.get("provider_name")
            stats_data["api_info"]["model"] = api_data.get("model")
        
        self.save_stats(stats_data)
        
        if self.verbose and current_stats:
            print(f"Session start recorded at: {current_time}")
            if isinstance(current_stats, list) and current_stats:
                api_data = current_stats[0]
                print(f"API Info: {api_data.get('provider_name')} - {api_data.get('model')}")
                print(f"Current usage: {api_data.get('total_tokens', 0)} tokens, ${api_data.get('cost', 0):.6f}")
    
    def record_session_end(self):
        """记录会话结束时的统计信息"""
        print("Recording session end stats...")
        
        stats_data = self.load_existing_stats()
        current_time = datetime.now().isoformat()
        
        # 获取当前API统计
        current_stats = self.get_api_stats()
        
        stats_data["session_end"] = current_time
        stats_data["end_stats"] = current_stats
        
        # 计算使用量差值
        if stats_data["start_stats"] and current_stats:
            usage_delta = self.calculate_usage_delta(
                stats_data["start_stats"], 
                current_stats
            )
            stats_data["usage_delta"] = usage_delta
            
            if usage_delta:
                print(f"Session usage summary:")
                print(f"  - Input tokens: {usage_delta.get('input_tokens', 0)}")
                print(f"  - Output tokens: {usage_delta.get('output_tokens', 0)}")
                print(f"  - Total tokens: {usage_delta.get('total_tokens', 0)}")
                print(f"  - Requests count: {usage_delta.get('requests_count', 0)}")
                print(f"  - Cost: ${usage_delta.get('cost', 0):.6f}")
        
        self.save_stats(stats_data)
        
        if self.verbose:
            print(f"Session end recorded at: {current_time}")
            if current_stats and isinstance(current_stats, list) and current_stats:
                api_data = current_stats[0]
                print(f"Final usage: {api_data.get('total_tokens', 0)} tokens, ${api_data.get('cost', 0):.6f}")
    
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