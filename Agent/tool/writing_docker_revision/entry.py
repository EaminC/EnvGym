import json
import os
import sys
import subprocess
from pathlib import Path
from typing import List, Dict
from openai import OpenAI
from dotenv import load_dotenv

# Add Agent directory to path for importing prompt modules
agent_dir = os.path.join(os.path.dirname(__file__), '..', '..')
if agent_dir not in sys.path:
    sys.path.insert(0, agent_dir)

class WritingDockerRevisionTool:
    def __init__(self, verbose: bool = False, use_json_tree: bool = True):
        self.verbose = verbose
        self.use_json_tree = use_json_tree
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
            print(f"  - Tree format: {'JSON' if self.use_json_tree else 'Text'}")
    
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
    
    def get_directory_tree(self, max_depth: int = 3, output_format: str = "text") -> str:
        """Get directory tree structure in text or JSON format"""
        if output_format == "json":
            return self._get_directory_tree_json(max_depth)
        else:
            return self._get_directory_tree_text(max_depth)
    
    def _get_directory_tree_text(self, max_depth: int = 3) -> str:
        """Get current working directory tree structure in text format"""
        try:
            # Try to use tree command first
            result = subprocess.run(['tree', '-L', str(max_depth), '-a', '-I', '__pycache__|*.pyc|.git'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                return result.stdout.strip()
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass
        
        # Fallback to manual tree generation
        try:
            return self._generate_tree_manually(Path.cwd(), max_depth)
        except Exception as e:
            return f"Error generating directory tree: {str(e)}"
    
    def _get_directory_tree_json(self, max_depth: int = 3) -> str:
        """Get directory tree structure in JSON format"""
        def build_tree(path: Path, current_depth: int = 0) -> dict:
            if current_depth >= max_depth:
                return None
                
            # Filter out hidden files and common unwanted directories
            if (path.name.startswith('.') or 
                path.name in ['__pycache__', 'node_modules', '.git', 'envgym']):
                return None
                
            result = {
                "name": path.name,
                "type": "directory" if path.is_dir() else "file",
                "path": str(path.relative_to(Path.cwd()))
            }
            
            if path.is_dir() and current_depth < max_depth - 1:
                children = []
                try:
                    items = list(path.iterdir())
                    # Sort: directories first, then files
                    items.sort(key=lambda x: (x.is_file(), x.name.lower()))
                    
                    for item in items:
                        child = build_tree(item, current_depth + 1)
                        if child is not None:
                            children.append(child)
                    
                    if children:
                        result["children"] = children
                except PermissionError:
                    result["error"] = "Permission denied"
            
            return result
        
        current_dir = Path.cwd()
        tree_data = build_tree(current_dir)
        return json.dumps(tree_data, indent=2, ensure_ascii=False)
    
    def _generate_tree_manually(self, path: Path, max_depth: int, current_depth: int = 0) -> str:
        """Manually generate directory tree when tree command is not available"""
        if current_depth >= max_depth:
            return ""
        
        items = []
        try:
            # Get all items and sort them
            all_items = list(path.iterdir())
            # Filter out hidden files and common unwanted directories
            filtered_items = [item for item in all_items 
                            if not item.name.startswith('.') 
                            and item.name not in ['__pycache__', 'node_modules', '.git']]
            
            # Sort: directories first, then files
            sorted_items = sorted(filtered_items, key=lambda x: (x.is_file(), x.name.lower()))
            
            for i, item in enumerate(sorted_items):
                is_last = i == len(sorted_items) - 1
                prefix = "└── " if is_last else "├── "
                
                if item.is_dir():
                    items.append(f"{'│   ' * current_depth}{prefix}{item.name}/")
                    # Recursively add subdirectory contents
                    if current_depth < max_depth - 1:
                        subtree = self._generate_tree_manually(item, max_depth, current_depth + 1)
                        if subtree:
                            items.append(subtree)
                else:
                    items.append(f"{'│   ' * current_depth}{prefix}{item.name}")
        except PermissionError:
            items.append(f"{'│   ' * current_depth}[Permission Denied]")
        
        return '\n'.join(items)
    
    def load_current_dockerfile(self) -> str:
        """Load current dockerfile from envgym/envgym.dockerfile"""
        dockerfile_path = "envgym/envgym.dockerfile"
        if not os.path.exists(dockerfile_path):
            return "No existing dockerfile found"
        
        return self.read_file_content(dockerfile_path)
    
    def load_failure_log(self) -> str:
        """Load failure log from envgym/log.txt"""
        log_path = "envgym/log.txt"
        if not os.path.exists(log_path):
            return "No log file found"
        
        return self.read_file_content(log_path)
    
    def load_next_steps(self) -> str:
        """Load next steps from envgym/next.txt"""
        next_path = "envgym/next.txt"
        if not os.path.exists(next_path):
            return "No next steps file found"
        
        return self.read_file_content(next_path)
    
    def revise_dockerfile(self, dockerfile_content: str, log_content: str, next_content: str, directory_tree: str, is_json_format: bool = False) -> str:
        """Revise dockerfile based on current dockerfile, failure log, next steps, and directory structure using AI"""
        
        # Import the prompt from write_docker.py
        from prompt.write_docker import write_docker_instruction
        
        # Add format information to the prompt
        if is_json_format:
            format_info = "\nNote: The directory tree is provided in JSON format with 'name', 'type', 'path', and 'children' fields."
        else:
            format_info = "\nNote: The directory tree is provided in traditional text tree format."
        
        # Format the prompt with actual content and format information
        prompt = write_docker_instruction.format(
            dockerfile_content=dockerfile_content,
            log_content=log_content,
            next_content=next_content,
            directory_tree=directory_tree
        ) + format_info
        
        # Prepare system message based on language setting
        if self.system_language.lower() in ['chinese', 'zh', '中文']:
            system_msg = "你是一个专业的Docker配置专家，能够根据失败日志和建议修改Dockerfile。只返回修改后的Dockerfile内容，不要其他任何内容。"
        else:
            system_msg = "You are a professional Docker configuration expert who can modify Dockerfiles based on failure logs and recommendations. Return only the modified Dockerfile content, no other content."
        
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
            print(f"Directory Tree Format: {'JSON' if is_json_format else 'Text'}")
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
        
        # Clean up any potential markdown formatting
        if response_content.startswith('```dockerfile'):
            lines = response_content.split('\n')
            response_content = '\n'.join(lines[1:-1])
        elif response_content.startswith('```'):
            lines = response_content.split('\n')
            response_content = '\n'.join(lines[1:-1])
        
        return response_content
    
    def save_dockerfile(self, dockerfile_content: str):
        """Save revised dockerfile to envgym/envgym.dockerfile"""
        dockerfile_path = "envgym/envgym.dockerfile"
        os.makedirs(os.path.dirname(dockerfile_path), exist_ok=True)
        
        with open(dockerfile_path, 'w', encoding='utf-8') as f:
            f.write(dockerfile_content)
    
    def run(self):
        """Execute docker revision tool"""
        try:
            print("Getting current directory structure...")
            tree_format = "json" if self.use_json_tree else "text"
            directory_tree = self.get_directory_tree(output_format=tree_format)
            print(f"Directory structure obtained ({'JSON' if self.use_json_tree else 'text'} format)")
            
            if self.verbose:
                print(f"\nCurrent Directory Tree ({'JSON' if self.use_json_tree else 'text'} format):")
                print("-" * 40)
                print(directory_tree)
                print("-" * 40)
            
            print("Loading current dockerfile...")
            dockerfile_content = self.load_current_dockerfile()
            print("Current dockerfile loaded")
            
            print("Loading failure log...")
            log_content = self.load_failure_log()
            print("Failure log loaded")
            
            print("Loading next steps...")
            next_content = self.load_next_steps()
            print("Next steps loaded")
            
            if self.verbose:
                print("\nLoaded content summary:")
                print(f"Directory tree format: {'JSON' if self.use_json_tree else 'Text'}")
                print(f"Directory tree length: {len(directory_tree)} characters")
                print(f"Dockerfile length: {len(dockerfile_content)} characters")
                print(f"Log length: {len(log_content)} characters")
                print(f"Next steps length: {len(next_content)} characters")
            
            print("Revising dockerfile based on logs, recommendations, and directory structure...")
            revised_dockerfile = self.revise_dockerfile(dockerfile_content, log_content, next_content, directory_tree, self.use_json_tree)
            
            print("Saving revised dockerfile...")
            self.save_dockerfile(revised_dockerfile)
            print("Revised dockerfile saved to envgym/envgym.dockerfile")
            
            if self.verbose:
                print("\nRevised dockerfile preview:")
                print("-" * 40)
                print(revised_dockerfile[:300] + "..." if len(revised_dockerfile) > 300 else revised_dockerfile)
                print("-" * 40)
            
            print("Docker revision completed successfully!")
            
        except Exception as e:
            print(f"Error during execution: {str(e)}")
            if self.verbose:
                import traceback
                traceback.print_exc()


def main(verbose: bool = False, use_json_tree: bool = False):
    """Main entry point for writing docker revision tool"""
    try:
        tool = WritingDockerRevisionTool(verbose=verbose, use_json_tree=use_json_tree)
        tool.run()
    except Exception as e:
        print(f"Writing docker revision tool execution failed: {e}")
        if verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Revise Dockerfile based on failure logs and recommendations")
    parser.add_argument("-v", "--verbose", action="store_true", 
                       help="Enable verbose output mode")
    parser.add_argument("-j", "--json", action="store_true", 
                       help="Use JSON format for directory tree (more LLM-friendly)")
    
    args = parser.parse_args()
    main(verbose=args.verbose, use_json_tree=args.json) 