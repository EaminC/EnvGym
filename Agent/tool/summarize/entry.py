import json
import os
import sys
from pathlib import Path
from typing import List, Dict
from openai import OpenAI
from dotenv import load_dotenv

# Add Agent directory to path for importing prompt modules
agent_dir = os.path.join(os.path.dirname(__file__), '..', '..')
if agent_dir not in sys.path:
    sys.path.insert(0, agent_dir)

class SummarizeTool:
    def __init__(self, verbose: bool = False):
        self.verbose = verbose
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
            if self.verbose:
                print("Warning: No .env file found")
        
        # Get configuration from environment
        api_key = os.getenv("FORGE_API_KEY")
        base_url = os.getenv("FORGE_BASE_URL")
        model = os.getenv("MODEL")
        temperature_str = os.getenv("AI_TEMPERATURE")
        system_language = os.getenv("SYSTEM_LANGUAGE")
        
        # Validate required configuration
        missing_configs = []
        
        if not api_key or api_key == "your-forge-api-key-here":
            missing_configs.append("FORGE_API_KEY")
            
        if not base_url:
            missing_configs.append("FORGE_BASE_URL")
            
        if not model:
            missing_configs.append("MODEL")
            
        if not temperature_str:
            missing_configs.append("AI_TEMPERATURE")
            
        if not system_language:
            missing_configs.append("SYSTEM_LANGUAGE")
            
        if missing_configs:
            print("Error: Missing required configuration in .env file:")
            for config in missing_configs:
                print(f"  - {config}")
            print("\nPlease set all required values in the .env file.")
            print("See .env.template for examples.")
            raise ValueError(f"Missing required configuration: {', '.join(missing_configs)}")
            
        # Convert temperature to float
        try:
            temperature = float(temperature_str)
        except ValueError:
            raise ValueError(f"AI_TEMPERATURE must be a number, got: {temperature_str}")
        
        # Initialize OpenAI client
        self.client = OpenAI(
            base_url=base_url,
            api_key=api_key
        )
        
        # Configuration settings
        self.model = model
        self.temperature = temperature
        self.system_language = system_language
            
        if self.verbose:
            print(f"Configuration loaded:")
            print(f"  - Base URL: {base_url}")
            print(f"  - Model: {self.model}")
            print(f"  - Temperature: {self.temperature}")
            print(f"  - System Language: {self.system_language}")
    
    def read_file_content(self, file_path: str) -> str:
        """Read file content"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return f.read()
        except UnicodeDecodeError:
            # Try other encodings
            try:
                with open(file_path, 'r', encoding='gbk') as f:
                    return f.read()
            except:
                with open(file_path, 'rb') as f:
                    return f"Binary file, cannot read content. File size: {len(f.read())} bytes"
        except Exception as e:
            return f"Error reading file: {str(e)}"
    
    def load_plan(self) -> str:
        """Load plan from envgym/plan.txt"""
        plan_path = "envgym/plan.txt"
        if not os.path.exists(plan_path):
            return "Plan file not found"
        
        return self.read_file_content(plan_path)
    
    def load_log(self) -> str:
        """Load log from envgym/log.txt"""
        log_path = "envgym/log.txt"
        if not os.path.exists(log_path):
            return "Log file not found or no execution yet"
        
        return self.read_file_content(log_path)
    
    def load_dockerfile(self) -> str:
        """Load dockerfile from envgym/envgym.dockerfile"""
        dockerfile_path = "envgym/envgym.dockerfile"
        if not os.path.exists(dockerfile_path):
            return "Dockerfile not found"
        
        return self.read_file_content(dockerfile_path)
    
    def generate_summary(self, plan_content: str, log_content: str, dockerfile_content: str) -> str:
        """Generate progress summary and next steps using AI"""
        
        prompt = f"""This is the complete plan:
{plan_content}

This is the previous Docker execution result log:
{log_content}

This is the current dockerfile:
{dockerfile_content}

Please summarize the current progress and the next steps for modifying the dockerfile.

Format:
current progress

next step

IMPORTANT: Return ONLY the summary in the specified format, no additional text or explanations."""
        
        # Prepare system message based on language setting
        if self.system_language.lower() in ['chinese', 'zh', '中文']:
            system_msg = "你是一个专业的项目进度分析师，能够根据计划、日志和配置文件分析当前进展并提出下一步行动建议。按照指定格式返回内容。"
        else:
            system_msg = "You are a professional project progress analyst who can analyze current progress based on plans, logs, and configuration files, and provide next step recommendations. Return content in the specified format."
        
        if self.verbose:
            print("\n" + "="*80)
            print("AI Interaction Details - FULL CONVERSATION")
            print("="*80)
            print("\nSystem Message:")
            print(system_msg)
            print("\n" + "-"*80)
            print("User Prompt (COMPLETE):")
            print(prompt)
            print("\n" + "-"*80)
            print("Request Details:")
            print(f"Model: {self.model}")
            print(f"Temperature: {self.temperature}")
            print("Sending request to AI...")
            print("-"*80)
            
        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system_msg},
                {"role": "user", "content": prompt}
            ],
            temperature=self.temperature
        )
        
        response_content = response.choices[0].message.content.strip()
        
        if self.verbose:
            print("\nAI Response (COMPLETE):")
            print(response_content)
            print("\n" + "="*80)
            print("End of AI Interaction")
            print("="*80)
        
        return response_content
    
    def save_summary(self, summary_content: str):
        """Save summary to envgym/next.txt"""
        next_path = "envgym/next.txt"
        os.makedirs(os.path.dirname(next_path), exist_ok=True)
        
        with open(next_path, 'w', encoding='utf-8') as f:
            f.write(summary_content)
    
    def run(self):
        """Execute summarize tool"""
        try:
            print("Loading plan...")
            plan_content = self.load_plan()
            print("Plan loaded")
            
            print("Loading execution log...")
            log_content = self.load_log()
            print("Log loaded")
            
            print("Loading dockerfile...")
            dockerfile_content = self.load_dockerfile()
            print("Dockerfile loaded")
            
            if self.verbose:
                print("\nLoaded content summary:")
                print(f"Plan length: {len(plan_content)} characters")
                print(f"Log length: {len(log_content)} characters")
                print(f"Dockerfile length: {len(dockerfile_content)} characters")
            
            print("Generating progress summary...")
            summary = self.generate_summary(plan_content, log_content, dockerfile_content)
            
            print("Saving summary...")
            self.save_summary(summary)
            print("Summary saved to envgym/next.txt")
            
            if self.verbose:
                print("\nGenerated summary preview:")
                print("-" * 40)
                print(summary[:300] + "..." if len(summary) > 300 else summary)
                print("-" * 40)
            
            print("Progress summarization completed successfully!")
            
        except Exception as e:
            print(f"Error during execution: {str(e)}")
            if self.verbose:
                import traceback
                traceback.print_exc()


def main(verbose: bool = False):
    """Main entry point for summarize tool"""
    try:
        tool = SummarizeTool(verbose=verbose)
        tool.run()
    except Exception as e:
        print(f"Summarize tool execution failed: {e}")
        if verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Summarize current progress and next steps")
    parser.add_argument("-v", "--verbose", action="store_true", 
                       help="Enable verbose output mode")
    
    args = parser.parse_args()
    main(verbose=args.verbose) 