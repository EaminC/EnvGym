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

class HardwareAdjustmentTool:
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
        """Load existing plan from envgym/plan.txt"""
        plan_path = "envgym/plan.txt"
        if not os.path.exists(plan_path):
            raise FileNotFoundError(f"Could not find {plan_path} file. Please ensure the file exists.")
        
        return self.read_file_content(plan_path)
    
    def load_hardware_info(self) -> str:
        """Load hardware information from envgym/hardware.txt"""
        hardware_path = "envgym/hardware.txt"
        if not os.path.exists(hardware_path):
            raise FileNotFoundError(f"Could not find {hardware_path} file. Please ensure the file exists.")
        
        return self.read_file_content(hardware_path)
    
    def adjust_plan_based_on_hardware(self, plan_content: str, hardware_info: str) -> str:
        """Adjust plan based on hardware information using AI"""
        
        prompt = f"""This is our current plan:
{plan_content}

This is our hardware information:
{hardware_info}

Please review the plan and see if there are any parts that need to be adjusted based on the hardware information. Consider factors like:
- CPU architecture compatibility (x86_64, ARM, etc.)
- Memory requirements and available RAM
- Storage space requirements
- Operating system compatibility
- Available development tools and versions
- Paths and directories correctness


Please adjust the current plan based on the hardware information.Please only answer the completeadjusted plan.
"""
        
        # Prepare system message based on language setting
        if self.system_language.lower() in ['chinese', 'zh', '中文']:
            system_msg = "你是一个专业的环境配置助手，能够根据硬件信息调整环境搭建计划，确保配置的兼容性和可行性。"
        else:
            system_msg = "You are a professional environment configuration assistant who can adjust environment setup plans based on hardware information to ensure compatibility and feasibility."
        
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
    
    def save_adjusted_plan(self, adjusted_plan: str):
        """Save adjusted plan back to envgym/plan.txt"""
        plan_path = "envgym/plan.txt"
        
        with open(plan_path, 'w', encoding='utf-8') as f:
            f.write(adjusted_plan)
    
    def run(self):
        """Execute hardware adjustment tool"""
        try:
            print("Loading existing plan...")
            plan_content = self.load_plan()
            print("Plan loaded successfully")
            
            print("Loading hardware information...")
            hardware_info = self.load_hardware_info()
            print("Hardware information loaded successfully")
            
            if self.verbose:
                print("\nCurrent plan content:")
                print("-" * 40)
                print(plan_content[:500] + "..." if len(plan_content) > 500 else plan_content)
                print("-" * 40)
                print("\nHardware information:")
                print("-" * 40)
                print(hardware_info)
                print("-" * 40)
            
            print("Requesting AI to adjust plan based on hardware...")
            adjusted_plan = self.adjust_plan_based_on_hardware(plan_content, hardware_info)
            
            print("Saving hardware-adjusted plan...")
            self.save_adjusted_plan(adjusted_plan)
            print("Plan successfully updated with hardware adjustments")
            
            print("Hardware-based plan adjustment completed successfully!")
            
        except FileNotFoundError as e:
            print(f"File not found: {str(e)}")
        except Exception as e:
            print(f"Error during execution: {str(e)}")
            if self.verbose:
                import traceback
                traceback.print_exc()


def main(verbose: bool = False):
    """Main entry point for hardware adjustment tool"""
    try:
        tool = HardwareAdjustmentTool(verbose=verbose)
        tool.run()
    except Exception as e:
        print(f"Hardware adjustment tool execution failed: {e}")
        if verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Adjust environment plan based on hardware information")
    parser.add_argument("-v", "--verbose", action="store_true", 
                       help="Enable verbose output mode")
    
    args = parser.parse_args()
    main(verbose=args.verbose) 