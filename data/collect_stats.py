#!/usr/bin/env python3
"""
Data Collection Script - Traverse all repositories and collect data from envgym/stat.json files
Output a simple summary table showing usage changes (delta) with color coding for status
"""

import json
import os
import sys
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any, Optional

def load_env_config(env_file: Path) -> Dict[str, str]:
    """Load configuration from .env file"""
    config = {}
    if env_file.exists():
        try:
            with open(env_file, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        config[key.strip()] = value.strip().strip('"').strip("'")
        except Exception as e:
            print(f"Warning: Could not load .env file: {e}")
    return config

def get_current_model() -> str:
    """Get current model from .env file"""
    env_file = Path("/home/cc/EnvGym/.env")
    config = load_env_config(env_file)
    return config.get("MODEL", "Azure/gpt-4.1")  # Default fallback

# ANSI color codes
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

# Pricing dictionary for different providers and models
PRICING = {
    "Azure": {
        "gpt-4.1": {
            "input": 2.00,  # $2.00 / 1M tokens
            "cached_input": 0.50,  # $0.50 / 1M tokens
            "output": 8.00  # $8.00 / 1M tokens
        }
    },
    "OpenAI": {
        "gpt-4.1": {
            "input": 2.00,  # $2.00 / 1M tokens
            "cached_input": 0.50,  # $0.50 / 1M tokens
            "output": 8.00  # $8.00 / 1M tokens
        }
    }
}

def load_stat_file(file_path: Path) -> Optional[Dict[str, Any]]:
    """Load a single stat.json file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return data
    except (json.JSONDecodeError, FileNotFoundError, PermissionError) as e:
        return None

def truncate_name(name: str, max_length: int = 20) -> str:
    """Truncate repository name if too long"""
    if len(name) <= max_length:
        return name
    return name[:max_length-3] + "..."

def check_status_file(status_file: Path) -> Optional[str]:
    """Check status file content"""
    try:
        with open(status_file, 'r', encoding='utf-8') as f:
            status = f.read().strip()
        # Return status only if it's not empty
        return status if status else None
    except (FileNotFoundError, PermissionError):
        return None

def collect_repo_stats(data_dir: Path) -> List[Dict[str, Any]]:
    """Collect statistics from all repositories"""
    collected_data = []
    
    # Traverse all subdirectories in the data directory
    for repo_dir in data_dir.iterdir():
        if not repo_dir.is_dir():
            continue
            
        repo_name = repo_dir.name
        stat_file = repo_dir / "envgym" / "stat.json"
        status_file = repo_dir / "envgym" / "status.txt"
        
        # Check if stat.json exists
        if stat_file.exists():
            stat_data = load_stat_file(stat_file)
            if stat_data:
                # Check status
                status = check_status_file(status_file) if status_file.exists() else None
                
                repo_info = {
                    "repo_name": repo_name,
                    "data": stat_data,
                    "status": status
                }
                collected_data.append(repo_info)
    
    return collected_data

def print_summary_table(collected_data: List[Dict[str, Any]], max_name_length: int = 20):
    """Print a simple summary table showing usage changes with color coding"""
    if not collected_data:
        print("No repositories found")
        return
    len_line = 123
    print(f"\n{'='*len_line}")
    print(' '*int(len_line/2.8) + f"ALL REPOSITORIES USAGE SUMMARY")
    print(f"{'='*len_line}")
    print(f"{'Repository':<20} {'Status':<10} {'Model':<12} {'Requests':<10} {'Input Tokens':<15} {'Output Tokens':<15} {'Total Tokens':<15} {'Duration':<12} {'Cost':<8}")
    print("-" * len_line)
    
    total_requests = 0
    total_input_tokens = 0
    total_output_tokens = 0
    total_duration = 0.0
    total_cost = 0.0
    
    success_count = 0
    failed_count = 0
    unknown_with_delta = 0  # UNKNOWN with usage_delta (shown in table as OOT)
    processing_repos = []  # UNKNOWN without usage_delta (processing)
    
    for repo_data in collected_data:
        repo_name = truncate_name(repo_data["repo_name"], max_name_length)
        data = repo_data["data"]
        status = repo_data["status"]
        
        # Determine color and status display based on status
        if status == "SUCCESS":
            color = Colors.GREEN
            status_display = "SUCCESS"
            success_count += 1
        elif status is None or status == "":
            color = Colors.YELLOW
            status_display = "UNKNOWN"
            # Check if this UNKNOWN has usage_delta
            if "usage_delta" in data and data["usage_delta"] is not None:
                unknown_with_delta += 1
            else:
                processing_repos.append(repo_name)
        else:
            color = Colors.RED
            status_display = "FAIL"
            failed_count += 1
        
        # Use usage_delta for changes during the session
        if "usage_delta" in data and data["usage_delta"] is not None:
            delta = data["usage_delta"]
            # Get model from end_stats or api_info
            model = "unknown"
            if "end_stats" in data and data["end_stats"]:
                model = data["end_stats"][0].get("model", "unknown")
            elif "api_info" in data:
                model = data["api_info"].get("model", "unknown")
            
            requests = delta.get("requests_count", 0)
            input_tokens = delta.get("input_tokens", 0)
            output_tokens = delta.get("output_tokens", 0)
            total_tokens = delta.get("total_tokens", 0)
            
            # Calculate cost based on pricing
            cost = 0.0
            current_model = get_current_model()
            provider, model_name = current_model.split("/", 1) if "/" in current_model else ("Azure", "gpt-4.1")
            
            if model_name in PRICING.get(provider, {}):
                pricing = PRICING[provider][model_name]
                input_cost = (input_tokens / 1000000) * pricing["input"]
                output_cost = (output_tokens / 1000000) * pricing["output"]
                cost = input_cost + output_cost
            
            # Calculate duration from session start and end times
            duration = "N/A"
            if status_display == "UNKNOWN":
                duration = "OOT"
            elif data.get("session_start") and data.get("session_end"):
                try:
                    start_time = datetime.fromisoformat(data["session_start"])
                    end_time = datetime.fromisoformat(data["session_end"])
                    duration_seconds = (end_time - start_time).total_seconds()
                    # Convert to HH:MM:SS format
                    hours = int(duration_seconds // 3600)
                    minutes = int((duration_seconds % 3600) // 60)
                    seconds = int(duration_seconds % 60)
                    duration = f"{hours:02d}:{minutes:02d}:{seconds:02d}"
                    total_duration += duration_seconds
                except (ValueError, TypeError):
                    duration = "N/A"
            
            print(f"{color}{repo_name:<20} {status_display:<10} {model:<12} {requests:<10,} {input_tokens:<15,} {output_tokens:<15,} {total_tokens:<15,} {duration:<12} ${cost:<7.2f}{Colors.END}")
            
            total_requests += requests
            total_input_tokens += input_tokens
            total_output_tokens += output_tokens
            total_cost += cost
    
    print("-" * len_line)
    # Convert total duration to HH:MM:SS format
    if total_duration > 0:
        hours = int(total_duration // 3600)
        minutes = int((total_duration % 3600) // 60)
        seconds = int(total_duration % 60)
        total_duration_str = f"{hours:02d}:{minutes:02d}:{seconds:02d}"
    else:
        total_duration_str = "N/A"
    print(f"{Colors.BOLD}{'TOTAL':<20} {'':<10} {'':<12} {total_requests:<10,} {total_input_tokens:<15,} {total_output_tokens:<15,} {total_input_tokens + total_output_tokens:<15,} {total_duration_str:<12} ${total_cost:<7.2f}{Colors.END}")
    print(f"{'='*len_line}")
    print(f"{Colors.GREEN}SUCCESS repositories: {success_count}{Colors.END}")
    if failed_count > 0:
        print(f"{Colors.RED}FAILED repositories: {failed_count}{Colors.END}")
    print(f"{Colors.YELLOW}UNKNOWN repositories (OOT): {unknown_with_delta}{Colors.END}")
    if processing_repos:
        print(f"{Colors.BLUE}Processing repositories: {', '.join(processing_repos)}{Colors.END}")
    print(f"{Colors.BOLD}Total repositories: {success_count + failed_count + unknown_with_delta}{Colors.END}")
    
    # Show pricing information
    current_model = get_current_model()
    provider, model_name = current_model.split("/", 1) if "/" in current_model else ("Azure", "gpt-4.1")
    
    if provider in PRICING and model_name in PRICING[provider]:
        pricing = PRICING[provider][model_name]
        print(f"{Colors.YELLOW}Pricing ({current_model}): Input ${pricing['input']:.2f}/1M tokens, Output ${pricing['output']:.2f}/1M tokens{Colors.END}")
    else:
        print(f"{Colors.YELLOW}Warning: No pricing found for {current_model}{Colors.END}")
    print(f"Collection time: {datetime.now().isoformat()}")

def save_data(collected_data: List[Dict[str, Any]], output_dir: Path, max_name_length: int = 20):
    """Save data to files"""
    output_dir.mkdir(exist_ok=True)
    
    # Save detailed data
    detailed_file = output_dir / "all_repos_detailed.json"
    with open(detailed_file, 'w', encoding='utf-8') as f:
        json.dump(collected_data, f, indent=2, ensure_ascii=False)
    
    # Generate CSV format with delta data
    csv_file = output_dir / "all_repos_delta.csv"
    with open(csv_file, 'w', encoding='utf-8') as f:
        f.write("Repository,Status,Model,Requests,Input Tokens,Output Tokens,Total Tokens,Duration,Cost\n")
        for repo_data in collected_data:
            repo_name = truncate_name(repo_data["repo_name"], max_name_length)
            data = repo_data["data"]
            status = repo_data["status"]
            
            if "usage_delta" in data and data["usage_delta"] is not None:
                delta = data["usage_delta"]
                # Get model from end_stats or api_info
                model = "unknown"
                if "end_stats" in data and data["end_stats"]:
                    model = data["end_stats"][0].get("model", "unknown")
                elif "api_info" in data:
                    model = data["api_info"].get("model", "unknown")
                
                requests = delta.get("requests_count", 0)
                input_tokens = delta.get("input_tokens", 0)
                output_tokens = delta.get("output_tokens", 0)
                total_tokens = delta.get("total_tokens", 0)
                
                # Calculate cost based on pricing
                cost = 0.0
                current_model = get_current_model()
                provider, model_name = current_model.split("/", 1) if "/" in current_model else ("Azure", "gpt-4.1")
                
                if model_name in PRICING.get(provider, {}):
                    pricing = PRICING[provider][model_name]
                    input_cost = (input_tokens / 1000000) * pricing["input"]
                    output_cost = (output_tokens / 1000000) * pricing["output"]
                    cost = input_cost + output_cost
                
                # Determine status display
                if status == "SUCCESS":
                    status_display = "SUCCESS"
                elif status is None or status == "":
                    status_display = "UNKNOWN"
                else:
                    status_display = "FAIL"
                
                # Calculate duration from session start and end times
                duration = "N/A"
                if status_display == "UNKNOWN":
                    duration = "OOT"
                elif data.get("session_start") and data.get("session_end"):
                    try:
                        start_time = datetime.fromisoformat(data["session_start"])
                        end_time = datetime.fromisoformat(data["session_end"])
                        duration_seconds = (end_time - start_time).total_seconds()
                        # Convert to HH:MM:SS format
                        hours = int(duration_seconds // 3600)
                        minutes = int((duration_seconds % 3600) // 60)
                        seconds = int(duration_seconds % 60)
                        duration = f"{hours:02d}:{minutes:02d}:{seconds:02d}"
                    except (ValueError, TypeError):
                        duration = "N/A"
                
                f.write(f"{repo_name},{status_display},{model},{requests},{input_tokens},{output_tokens},{total_tokens},{duration},{cost}\n")
    
    print(f"\nData saved to: {output_dir}")
    print(f"- Detailed: {detailed_file}")
    print(f"- Delta CSV: {csv_file}")

def main():
    """Main function"""
    # Set data directory path
    if len(sys.argv) > 1:
        data_dir = Path(sys.argv[1])
    else:
        data_dir = Path(".")  # Current directory
    
    # Set max name length (can be overridden by command line argument)
    max_name_length = 20
    if len(sys.argv) > 2:
        try:
            max_name_length = int(sys.argv[2])
        except ValueError:
            print(f"Warning: Invalid max name length '{sys.argv[2]}', using default {max_name_length}")
    
    if not data_dir.exists():
        print(f"Error: Data directory does not exist: {data_dir}")
        sys.exit(1)
    
    print(f"Collecting usage changes from all repositories in: {data_dir}")
    print(f"Max repository name length: {max_name_length}")
    
    # Collect data
    collected_data = collect_repo_stats(data_dir)
    
    if not collected_data:
        print("No repositories found")
        sys.exit(0)
    
    # Print summary table
    print_summary_table(collected_data, max_name_length)
    
    # Save data
    output_dir = Path("collected_stats")
    save_data(collected_data, output_dir, max_name_length)

if __name__ == "__main__":
    main() 