import json
import os
import sys
import subprocess
import platform
import shutil
import psutil
from pathlib import Path
from typing import Dict
from openai import OpenAI
from dotenv import load_dotenv

# Add Agent directory to path for importing prompt modules
agent_dir = os.path.join(os.path.dirname(__file__), '..', '..')
if agent_dir not in sys.path:
    sys.path.insert(0, agent_dir)

class HardwareCheckingTool:
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
            
        print(f"Hardware Checking Tool initialized")

    def run_command(self, command: str) -> str:
        """Run a shell command and return output"""
        try:
            result = subprocess.run(
                command, 
                shell=True, 
                capture_output=True, 
                text=True, 
                timeout=15
            )
            if result.returncode == 0:
                return result.stdout.strip()
            else:
                return f"Command failed: {result.stderr.strip()}"
        except subprocess.TimeoutExpired:
            return "Command timed out"
        except Exception as e:
            return f"Error: {str(e)}"

    def check_cpu_info(self) -> Dict[str, str]:
        """Check essential CPU information"""
        cpu_info = {}
        
        cpu_info['logical_cores'] = str(psutil.cpu_count(logical=True))
        cpu_info['physical_cores'] = str(psutil.cpu_count(logical=False))
        cpu_info['architecture'] = platform.machine()
        
        # Get CPU model based on platform
        if platform.system() == "Darwin":  # macOS
            cpu_info['model'] = self.run_command("sysctl -n machdep.cpu.brand_string")
        elif platform.system() == "Linux":
            cpu_info['model'] = self.run_command("lscpu | grep 'Model name' | cut -d':' -f2 | xargs")
        elif platform.system() == "Windows":
            cpu_info['model'] = self.run_command("wmic cpu get name /value | findstr Name=")
        else:
            cpu_info['model'] = "Unknown"
        
        return cpu_info

    def check_gpu_info(self) -> Dict[str, str]:
        """Check GPU information"""
        gpu_info = {}
        
        if platform.system() == "Darwin":  # macOS
            gpu_info['status'] = "Integrated (Apple Silicon)" if "arm" in platform.machine().lower() else "Available"
            gpu_info['details'] = self.run_command("system_profiler SPDisplaysDataType | grep 'Chipset Model' | head -1")
        elif platform.system() == "Linux":
            gpu_info['nvidia'] = self.run_command("nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo 'Not available'")
            gpu_info['details'] = self.run_command("lspci | grep -i vga | head -1 || echo 'No GPU detected'")
        elif platform.system() == "Windows":
            gpu_info['details'] = self.run_command("wmic path win32_VideoController get name /value | findstr Name=")
        else:
            gpu_info['status'] = "Unknown"
        
        return gpu_info

    def check_memory_info(self) -> Dict[str, str]:
        """Check memory information"""
        memory = psutil.virtual_memory()
        return {
            'total_gb': f"{memory.total / (1024**3):.1f}",
            'available_gb': f"{memory.available / (1024**3):.1f}",
            'usage_percent': f"{memory.percent:.1f}%"
        }

    def check_disk_info(self) -> Dict[str, str]:
        """Check disk space for current working directory"""
        try:
            current_path = os.getcwd()
            disk_usage = psutil.disk_usage(current_path)
            return {
                'current_directory': current_path,
                'total_gb': f"{disk_usage.total / (1024**3):.1f}",
                'free_gb': f"{disk_usage.free / (1024**3):.1f}",
                'usage_percent': f"{(disk_usage.used / disk_usage.total) * 100:.1f}%"
            }
        except Exception as e:
            return {'error': f"Could not check disk space: {str(e)}"}

    def check_docker_status(self) -> Dict[str, str]:
        """Check if Docker is running"""
        docker_info = {}
        
        # Check if Docker is installed
        if shutil.which('docker'):
            docker_info['installed'] = 'Yes'
            # Check if Docker daemon is running
            docker_status = self.run_command("docker info 2>/dev/null && echo 'Running' || echo 'Not running'")
            docker_info['status'] = docker_status
            if 'Running' in docker_status:
                docker_info['version'] = self.run_command("docker --version")
        else:
            docker_info['installed'] = 'No'
            docker_info['status'] = 'Not available'
        
        return docker_info

    def collect_hardware_info(self) -> Dict[str, Dict[str, str]]:
        """Collect essential hardware information"""
        print("Collecting essential hardware information...")
        
        return {
            'cpu': self.check_cpu_info(),
            'gpu': self.check_gpu_info(),
            'memory': self.check_memory_info(),
            'storage': self.check_disk_info(),
            'docker': self.check_docker_status()
        }

    def format_hardware_info(self, hardware_info: Dict[str, Dict[str, str]]) -> str:
        """Format hardware information for AI analysis"""
        formatted_info = []
        
        for category, info in hardware_info.items():
            formatted_info.append(f"=== {category.upper()} ===")
            for key, value in info.items():
                formatted_info.append(f"{key}: {value}")
            formatted_info.append("")
        
        return "\n".join(formatted_info)

    def analyze_hardware_with_ai(self, hardware_info_text: str) -> str:
        """Use AI to analyze hardware information"""
        from prompt.hardware_checking import hardware_checking_prompt
        
        prompt = f"""Here is the essential hardware information from the system:

{hardware_info_text}

{hardware_checking_prompt}
"""
        
        system_msg = "You are a Docker specialist. Provide only a concise list of key information that affects Dockerfile writing. No explanations or additional text."
            
        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system_msg},
                {"role": "user", "content": prompt}
            ],
            temperature=self.temperature
        )
        
        return response.choices[0].message.content

    def save_hardware_report(self, report_content: str):
        """Save hardware report to file"""
        report_path = "envgym/hardware.txt"
        os.makedirs(os.path.dirname(report_path), exist_ok=True)
        
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write(report_content)

    def run(self):
        """Execute hardware checking tool"""
        try:
            print("=== EnvGym Docker Hardware Analysis ===")
            
            # Collect hardware information
            hardware_info = self.collect_hardware_info()
            
            # Format for display and AI analysis
            hardware_info_text = self.format_hardware_info(hardware_info)
            
            print("\n=== HARDWARE SUMMARY ===")
            print(hardware_info_text)
            
            # Analyze with AI
            print("=== EXTRACTING DOCKERFILE KEY INFO ===")
            analysis_report = self.analyze_hardware_with_ai(hardware_info_text)
            
            # Create final report with only AI analysis
            final_report = analysis_report
            
            # Save report
            self.save_hardware_report(final_report)
            
            print(f"\n=== DOCKERFILE INFO EXTRACTED ===")
            print(f"Key information saved to: envgym/hardware.txt")
            print("\n" + analysis_report)
            
        except Exception as e:
            print(f"Error during hardware checking: {str(e)}")
            error_report = f"""=== HARDWARE CHECKING ERROR ===
Error: {str(e)}
Please check your system configuration and try again.
"""
            self.save_hardware_report(error_report)

def main():
    """Main function"""
    tool = HardwareCheckingTool()
    tool.run()

if __name__ == "__main__":
    main() 