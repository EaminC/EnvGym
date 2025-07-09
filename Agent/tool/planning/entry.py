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

class PlanningTool:
    def __init__(self):
        # Try to load environment variables from multiple possible locations
        possible_env_paths = [
            Path(__file__).parent.parent.parent / '.env',  # EnvGym/.env
            Path(__file__).parent.parent.parent.parent / '.env',  # parent of EnvGym
            Path.cwd() / '.env',  # Current working directory
        ]
        
        for env_path in possible_env_paths:
            if env_path.exists():
                load_dotenv(env_path)
                print(f"Loaded environment from: {env_path}")
                break
        else:
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
    
    def load_documents(self) -> List[str]:
        """Load file list from documents.json"""
        documents_path = "envgym/documents.json"
        if not os.path.exists(documents_path):
            raise FileNotFoundError(f"Could not find {documents_path} file")
        
        with open(documents_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    
    def get_existing_plan(self) -> str:
        """Get existing plan content"""
        plan_path = "envgym/plan.txt"
        if os.path.exists(plan_path):
            with open(plan_path, 'r', encoding='utf-8') as f:
                return f.read()
        return ""
    
    def save_plan(self, plan_content: str):
        """Save plan to file"""
        plan_path = "envgym/plan.txt"
        os.makedirs(os.path.dirname(plan_path), exist_ok=True)
        
        with open(plan_path, 'w', encoding='utf-8') as f:
            f.write(plan_content)
    
    def generate_initial_plan(self, file_path: str, file_content: str) -> str:
        """Generate initial plan for the first file"""
        from prompt.planning_initial import plan_instruction
        
        prompt = f"""I have a file: {file_path}

File content:
{file_content}

I want to configure the environment. Please write an environment setup plan.

{plan_instruction}
"""
        
        # Prepare system message based on language setting
        if self.system_language.lower() in ['chinese', 'zh', '中文']:
            system_msg = "你是一个专业的环境配置助手，能够根据文件内容分析并制定详细的环境搭建计划。"
        else:
            system_msg = "You are a professional environment configuration assistant who can analyze file content and create detailed environment setup plans."
            
        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system_msg},
                {"role": "user", "content": prompt}
            ],
            temperature=self.temperature
        )
        
        return response.choices[0].message.content
    
    def update_plan(self, file_path: str, file_content: str, existing_plan: str) -> str:
        """Update plan for subsequent files"""
        from prompt.planning import plan_instruction
        
        prompt = f"""This is the existing configuration plan:
{existing_plan}

Now there is a new file: {file_path}

File content:
{file_content}

I want to configure the environment. Please modify or add to the plan content based on the previous plan and the new content.

{plan_instruction}
"""
        
        # Prepare system message based on language setting
        if self.system_language.lower() in ['chinese', 'zh', '中文']:
            system_msg = "你是一个专业的环境配置助手，能够根据新的文件内容更新现有的环境搭建计划。"
        else:
            system_msg = "You are a professional environment configuration assistant who can update existing environment setup plans based on new file content."
            
        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system_msg},
                {"role": "user", "content": prompt}
            ],
            temperature=self.temperature
        )
        
        return response.choices[0].message.content
    
    def run(self):
        """Execute planning tool"""
        try:
            # Load document list
            documents = self.load_documents()
            print(f"Found {len(documents)} files to process")
            
            if not documents:
                print("No files found to process")
                return
            
            # Check if README.md exists and prioritize it
            readme_files = [f for f in documents if os.path.basename(f).lower() == 'readme.md']
            if readme_files:
                readme_file = readme_files[0]  # Take the first README.md found
                # Remove README.md from original position and put it at the beginning
                documents.remove(readme_file)
                documents.insert(0, readme_file)
                print(f"Found README.md, prioritizing it for analysis: {readme_file}")
            
            # Process first file (now prioritized README.md if exists)
            first_file = documents[0]
            print(f"Processing first file: {first_file}")
            
            if not os.path.exists(first_file):
                print(f"Warning: File {first_file} does not exist")
                return
            
            file_content = self.read_file_content(first_file)
            plan = self.generate_initial_plan(first_file, file_content)
            self.save_plan(plan)
            print(f"Generated initial plan and saved to envgym/plan.txt")
            
            # Process subsequent files
            for i, file_path in enumerate(documents[1:], 2):
                print(f"Processing file {i}: {file_path}")
                
                if not os.path.exists(file_path):
                    print(f"Warning: File {file_path} does not exist, skipping")
                    continue
                
                file_content = self.read_file_content(file_path)
                existing_plan = self.get_existing_plan()
                updated_plan = self.update_plan(file_path, file_content, existing_plan)
                self.save_plan(updated_plan)
                print(f"Updated plan based on file {file_path}")
            
            print("All files processed successfully!")
            
        except Exception as e:
            print(f"Error during execution: {str(e)}")

def main():
    """Main function"""
    tool = PlanningTool()
    tool.run()

if __name__ == "__main__":
    main() 