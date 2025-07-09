import json
import os
import sys
import subprocess
from pathlib import Path
from typing import List, Dict
from openai import OpenAI
from dotenv import load_dotenv
import datetime

# Add Agent directory to path for importing prompt modules
agent_dir = os.path.join(os.path.dirname(__file__), '..', '..')
if agent_dir not in sys.path:
    sys.path.insert(0, agent_dir)

class TestScanningTool:
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
    
    def get_directory_tree(self) -> str:
        """Get directory tree structure using tree command or fallback to manual traversal"""
        try:
            # Try using tree command
            result = subprocess.run(['tree', '-a', '-I', 'envgym'], 
                                  capture_output=True, text=True, cwd='.')
            if result.returncode == 0:
                return result.stdout
        except (subprocess.SubprocessError, FileNotFoundError):
            pass
        
        # Fallback to manual directory traversal
        tree_lines = []
        current_dir = Path('.')
        
        def walk_directory(path: Path, prefix: str = "", is_last: bool = True):
            if path.name == 'envgym':
                return
                
            items = list(path.iterdir())
            items = [item for item in items if item.name != 'envgym']
            items.sort(key=lambda x: (x.is_file(), x.name.lower()))
            
            for i, item in enumerate(items):
                is_last_item = i == len(items) - 1
                current_prefix = "└── " if is_last_item else "├── "
                tree_lines.append(f"{prefix}{current_prefix}{item.name}")
                
                if item.is_dir():
                    extension = "    " if is_last_item else "│   "
                    walk_directory(item, prefix + extension, is_last_item)
        
        tree_lines.append(str(current_dir.name))
        walk_directory(current_dir)
        return "\n".join(tree_lines)
    
    def scan_for_test_files(self, directory_tree: str) -> List[str]:
        """Use AI to scan for test files"""
        from prompt.test_scanning import test_scanning_instruction
        
        prompt = f"""Here is the directory tree structure of the current working directory:

{directory_tree}

{test_scanning_instruction}

Please analyze this directory structure and return ONLY a JSON array containing the relative paths of files that are clearly meant for testing the environment or functionality. The format should be exactly like this (they are just examples):

[
  "tests/test_example.py",
  "test_script.py", 
  "examples/demo.py",
  "benchmark/test_performance.py"
]

IMPORTANT: Return ONLY the JSON array, no additional text, explanations, or markdown formatting.
"""
        
        # Prepare system message based on language setting
        if self.system_language.lower() in ['chinese', 'zh', '中文']:
            system_msg = "你是一个专业的代码库扫描助手，能够识别测试文件。仅返回JSON格式的文件列表，不要其他内容。"
        else:
            system_msg = "You are a professional codebase scanning assistant who can identify test files. Return only JSON format file list, no other content."
        
        if self.verbose:
            print("\n" + "="*60)
            print("AI Interaction Details")
            print("="*60)
            print("\nSystem Message:")
            print(f"'{system_msg}'")
            print("\nUser Prompt:")
            print(f"'{prompt}'")
            print("\nSending request to AI...")
            print(f"Model: {self.model}")
            print(f"Temperature: {self.temperature}")
            
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
            print("\nAI Response:")
            print(f"'{response_content}'")
            print("\nParsing response...")
            print("="*60)
        
        # Try to parse the JSON response
        try:
            # Remove any potential markdown formatting
            if response_content.startswith('```'):
                if self.verbose:
                    print("Detected markdown formatting, cleaning...")
                lines = response_content.split('\n')
                response_content = '\n'.join(lines[1:-1])
                if self.verbose:
                    print(f"Cleaned content: '{response_content}'")
            
            test_files = json.loads(response_content)
            if isinstance(test_files, list):
                if self.verbose:
                    print(f"Successfully parsed JSON, found {len(test_files)} test files")
                    for i, test_file in enumerate(test_files, 1):
                        print(f"  {i}. {test_file}")
                return test_files
            else:
                raise ValueError("Response is not a list")
                
        except json.JSONDecodeError as e:
            print(f"JSON parsing error: {e}")
            if self.verbose:
                print(f"Original AI response: '{response_content}'")
            return []
    
    def save_test_files(self, test_files: List[str]):
        """Save test file list to envgym/test.json"""
        output_path = "envgym/test.json"
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        # Keep format consistent with documents.json - simple array
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(test_files, f, indent=2, ensure_ascii=False)
    
    def _categorize_test_files(self, test_files: List[str]) -> Dict[str, List[str]]:
        """Categorize test files by type"""
        categories = {
            "unit_tests": [],
            "integration_tests": [],
            "examples": [],
            "benchmarks": [],
            "demos": [],
            "other_tests": []
        }
        
        for file_path in test_files:
            file_lower = file_path.lower()
            
            if 'example' in file_lower or 'examples/' in file_lower:
                categories["examples"].append(file_path)
            elif 'demo' in file_lower or 'demos/' in file_lower:
                categories["demos"].append(file_path)
            elif 'benchmark' in file_lower or 'bench' in file_lower:
                categories["benchmarks"].append(file_path)
            elif 'integration' in file_lower:
                categories["integration_tests"].append(file_path)
            elif 'test' in file_lower or 'spec' in file_lower:
                categories["unit_tests"].append(file_path)
            else:
                categories["other_tests"].append(file_path)
        
        # Remove empty categories
        return {k: v for k, v in categories.items() if v}
    
    def run(self):
        """Execute test scanning tool"""
        try:
            print("Scanning current directory structure for test files...")
            if self.verbose:
                print(f"Verbose mode enabled")
                print(f"Current working directory: {os.getcwd()}")
            
            # Get directory tree
            directory_tree = self.get_directory_tree()
            print(f"Directory tree structure generated successfully")
            
            if self.verbose:
                print("\nDirectory tree structure:")
                print("-" * 40)
                print(directory_tree)
                print("-" * 40)
            
            # Ask AI to identify test files
            print("Requesting AI to identify test files...")
            test_files = self.scan_for_test_files(directory_tree)
            
            if not test_files:
                print("No test files found or AI response parsing error")
                return
            
            print(f"Found {len(test_files)} test files:")
            for test_file in test_files:
                print(f"  - {test_file}")
            
            # Save to envgym/test.json
            output_path = "envgym/test.json"
            self.save_test_files(test_files)
            print(f"Test file list saved to {output_path}")
            
        except Exception as e:
            print(f"Error executing test file scanning: {e}")
            if self.verbose:
                import traceback
                traceback.print_exc()


def main(verbose: bool = False):
    """Main entry point for test scanning tool"""
    try:
        tool = TestScanningTool(verbose=verbose)
        tool.run()
    except Exception as e:
        print(f"Test scanning tool execution failed: {e}")
        if verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Scan test files in codebase")
    parser.add_argument("-v", "--verbose", action="store_true", 
                       help="Enable verbose output mode")
    
    args = parser.parse_args()
    main(verbose=args.verbose) 