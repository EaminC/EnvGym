import os
import sys
from pathlib import Path

# Add local agent_squad module path
current_dir = Path(__file__).resolve().parent
agent_squad_path = current_dir.parent / "python" / "src"
sys.path.insert(0, str(agent_squad_path))

from dotenv import load_dotenv
from agent_squad.classifiers import OpenAIClassifier, OpenAIClassifierOptions
from agent_squad.orchestrator import AgentSquad
from agent_squad.storage import InMemoryChatStorage
from agent_squad.utils import AgentTools, AgentTool
from agent_squad.agents import AgentResponse, SupervisorAgent, SupervisorAgentOptions, HybridAgent, HybridAgentOptions
import uuid
import asyncio
import json
import time

# =============================================================================
# 统一配置 - 管理所有模型和参数设置
# =============================================================================
# 模型配置
MODEL_NAME = 'gpt-4.1'  # 统一使用的OpenAI模型

# Token 配置
MAX_TOKENS_CLASSIFIER = 4500  # 分类器最大token数
MAX_TOKENS_AGENT_DEFAULT = 4500  # Agent默认最大token数
MAX_TOKENS_INITIALIZATION = 800  # 初始化Agent token数

# 温度配置 (控制随机性 0-1)
TEMPERATURE_CLASSIFIER = 0.2  # 分类器温度
TEMPERATURE_DEFAULT = 0.7  # 默认温度
TEMPERATURE_FOCUSED = 0.3  # 专注分析温度
TEMPERATURE_STABLE = 0.2  # 稳定执行温度
TEMPERATURE_PRECISE = 0.1  # 精确操作温度

# Top-P 配置 (核心采样)
TOP_P_DEFAULT = 0.9  # 默认top-p值

# 工具递归配置
TOOL_MAX_RECURSIONS_DEFAULT = 5  # 默认工具最大递归次数
TOOL_MAX_RECURSIONS_SIMPLE = 3  # 简单操作递归次数
TOOL_MAX_RECURSIONS_COMPLEX = 6  # 复杂操作递归次数
TOOL_MAX_RECURSIONS_PLANNING = 10  # 规划类操作递归次数
TOOL_MAX_RECURSIONS_DOCKER = 15  # Docker操作递归次数
TOOL_MAX_RECURSIONS_EXECUTION = 10  # 执行类操作递归次数
# =============================================================================

# Tools
from tool.compat.package_version import analyze_package_formatted
from tool.aider.entry import get_repo_map
from tool.codex.entry import simple_codex_agent
from tool.dockerrun.entry import run_dockerfile_with_logs


dotenv_path = Path(__file__).resolve().parent.parent / ".env"
if not dotenv_path.exists():
    raise FileNotFoundError(f".env file not found at {dotenv_path}")
    
load_dotenv(dotenv_path=dotenv_path, override=True)

my_api_key = os.getenv("OPENAI_API_KEY")
if not my_api_key:
    raise EnvironmentError("Missing OPENAI_API_KEY in .env file")



custom_openai_classifier = OpenAIClassifier(OpenAIClassifierOptions(
    api_key=my_api_key,
    model_id=MODEL_NAME,
    inference_config={
        'max_tokens': MAX_TOKENS_CLASSIFIER,
        'temperature': TEMPERATURE_CLASSIFIER,
        'top_p': TOP_P_DEFAULT,
        'stop_sequences': ['']
    }
))
memory_storage = InMemoryChatStorage()
orchestrator = AgentSquad(classifier=custom_openai_classifier,storage=memory_storage)

orchestrator.classifier.set_system_prompt(
    """
    {{AGENT_DESCRIPTIONS}}
    {{ROUTING_INSTRUCTIONS}}
    """,
    {
        "AGENT_DESCRIPTIONS": "You are an AI assistant specialized in development environment setup and orchestration. Your primary function is to coordinate a group of expert agents that handle tasks such as installing dependencies, configuring language toolchains, setting environment variables, and initializing project templates. Each agent is responsible for a specific domain, such as Python, C++, Rust, or system-level configuration.",
        "ROUTING_INSTRUCTIONS": "Multiple specialized agents are available to support different phases of environment configuration. Based on the user's request, you are responsible for identifying the relevant subtask—such as dependency analysis, package installation, or environment setup—and routing it to the appropriate agent. You may delegate tasks to one or more agents as needed and are expected to manage their coordination and output integration. Treat each request as part of a larger configuration workflow, not in isolation."
    }
)

# Use new HybridAgent instead of OpenAIAgent


# Create AgentTools instance
package_tools = AgentTools([
    AgentTool(
        name="package_dependency",
        description="Get the dependency tree of a package and its versions",
        properties={
            "language": {
                "type": "string",
                "description": "The language of the package selected from [python, go, rust, java, cpp]"
            },
            "package_name_and_version": {
                "type": "string",
                "description": """
                Specify the package name and version in a language-specific format. Each language uses a different syntax:
    - Python: 'package==version', e.g., 'pandas==1.1.1'
    - Go: 'module@version', e.g., 'k8s.io/kubernetes@v1.27.1'
    - Rust: 'crate==version', e.g., 'tokio==1.28.0'
    - Java: 'group:artifact:version', e.g., 'org.apache.hadoop:hadoop-common:3.3.6'
    - C++: 'package==version', e.g., 'fmt==10.0.0'
    """
            }
        },
        func=analyze_package_formatted,
        enum_values={"language": ["python", "go", "rust", "java", "cpp"]}
    )
])

agent_package_compatibility = HybridAgent(HybridAgentOptions(
    # Required fields
    name='package_compatibility_agent',
    description='An hybrid agent that uses OpenAI API and tools to check package compatibility and analyze dependencies',
    api_key=my_api_key,

    # Optional fields
    model=MODEL_NAME,         # 使用统一的模型配置
    streaming=True,        # Enable streaming responses
    #retriever=custom_retriever,  # Custom retriever for additional context

    # Inference configuration
    inference_config={
        'maxTokens': MAX_TOKENS_AGENT_DEFAULT,     # Maximum tokens to generate
        'temperature': TEMPERATURE_DEFAULT,   # Control randomness (0-1)
        'topP': TOP_P_DEFAULT,         # Control diversity via nucleus sampling
        'stopSequences': None  # Sequences that stop generation
    },

    # Custom system prompt with variables
    custom_system_prompt={
        'template': """You are an AI assistant specialized in {{DOMAIN}}.
You have access to powerful tools that can analyze package dependencies and versions across multiple programming languages.

IMPORTANT: When using tools, always display the complete tool output exactly as provided. The tools provide rich, detailed information that should be shown to the user in full.

Your workflow should be:
1. Use the package analysis tool for each package mentioned
2. Display the complete tool output for each package (dependency trees, version lists, etc.)
3. Add your own compatibility analysis and recommendations based on the tool results

Current supported languages: {{LANGUAGES}}""",
        'variables': {
            'DOMAIN': 'Package Compatibility and Dependency Analysis',
            'LANGUAGES': 'Python, Go, Rust, Java, C++'
        }
    },
    
    # Tool configuration
    tool_config={
        'tool': package_tools,
        'toolMaxRecursions': TOOL_MAX_RECURSIONS_DEFAULT,  # Maximum number of tool calls in one conversation
    }
))

tool_repo_map = AgentTools([
    AgentTool(
        name="generate_repo_map",
        description="Generate a comprehensive repository map showing the structure and key components of a codebase",
        properties={
            "repo_path": {
                "type": "string",
                "description": "The path to the repository or directory to analyze"
            },
            "max_tokens": {
                "type": "integer",
                "description": "Maximum number of tokens for the generated repo map (default: 1024, recommended range: 512-4096)"
            },
            "include_patterns": {
                "type": "array",
                "items": {"type": "string"},
                "description": """
                File patterns to include in the analysis. Use glob patterns like:
    - ['*.py'] for Python files only
    - ['*.js', '*.ts', '*.jsx', '*.tsx'] for JavaScript/TypeScript files
    - ['*.java'] for Java files
    - ['*.cpp', '*.c', '*.h', '*.hpp'] for C/C++ files
    - ['*.go'] for Go files
    - ['*.rs'] for Rust files
    If not specified, includes common source file types automatically.
                """
            },
            "exclude_patterns": {
                "type": "array",
                "items": {"type": "string"},
                "description": """
                File patterns to exclude from the analysis. Common exclusions:
    - ['*__pycache__*', '*.pyc'] for Python cache files
    - ['node_modules*', '*.log'] for Node.js and log files
    - ['*.git*', '*.tmp*', '*.cache*'] for version control and temporary files
    If not specified, uses sensible defaults for common ignore patterns.
                """
            },
            "verbose": {
                "type": "boolean",
                "description": "Enable verbose output to show detailed processing information (default: false)"
            }
        },
        func=get_repo_map,
        enum_values={}
    )
])

agent_repo_map = HybridAgent(HybridAgentOptions(
    # Required fields
    name='repository_map_agent',
    description='An advanced agent that generates comprehensive repository maps and analyzes codebase structure using tree-sitter parsing',
    api_key=my_api_key,

    # Optional fields
    model=MODEL_NAME,         # 使用统一的模型配置
    streaming=True,        # Enable streaming responses
    #retriever=custom_retriever,  # Custom retriever for additional context

    # Inference configuration
    inference_config={
        'maxTokens': MAX_TOKENS_AGENT_DEFAULT,     # Maximum tokens to generate
        'temperature': TEMPERATURE_FOCUSED,   # Lower temperature for more focused analysis
        'topP': TOP_P_DEFAULT,         # Control diversity via nucleus sampling
        'stopSequences': None  # Sequences that stop generation
    },

    # Custom system prompt with variables
    custom_system_prompt={
        'template': """You are an AI assistant specialized in {{DOMAIN}}.
You have access to powerful tools that can analyze repository structure and generate comprehensive code maps using advanced tree-sitter parsing technology.

IMPORTANT: When using the repository mapping tool, always display the complete tool output exactly as provided. The tool generates rich, hierarchical views of codebases that should be shown to the user in full.

Your workflow should be:
1. Use the repository mapping tool with appropriate parameters based on user requirements
2. Display the complete tool output (repository structure, key components, function definitions, etc.)
3. Provide insightful analysis of the codebase structure, patterns, and organization
4. Suggest improvements or highlight important architectural decisions based on the map

Supported file types: {{SUPPORTED_TYPES}}
Key capabilities: {{CAPABILITIES}}""",
        'variables': {
            'DOMAIN': 'Repository Structure Analysis and Code Mapping',
            'SUPPORTED_TYPES': 'Python, JavaScript/TypeScript, Java, C/C++, Go, Rust, PHP, Ruby, Swift, Kotlin, Scala, HTML/CSS, Markdown, YAML, JSON',
            'CAPABILITIES': 'Hierarchical code structure analysis, Function/class definition extraction, Cross-reference mapping, Dependency visualization, Code organization assessment'
        }
    },
    
    # Tool configuration
    tool_config={
        'tool': tool_repo_map,
        'toolMaxRecursions': TOOL_MAX_RECURSIONS_SIMPLE,  # Maximum number of tool calls in one conversation
    }
))

# Add functional agents directly to orchestrator
tool_codex = AgentTools([
    AgentTool(
        name="simple_codex_agent",
        description="Simplified Codex agent interface for executing natural language task descriptions using Codex CLI",
        properties={
            "task_description": {
                "type": "string",
                "description": "A natural language description of the task to perform, such as 'create a test.txt file', 'list files in current directory', or 'show directory structure'"
            }
        },
        func=simple_codex_agent,
        enum_values={}
    )
])

# Initialization agent - creates envgym folder and related files
agent_initialization = HybridAgent(HybridAgentOptions(
    name='initialization_agent',
    description='Creates envgym directory with plan.txt, next.txt, status.txt, log.txt ,history.txt, envgym.dockerfile files',
    api_key=my_api_key,
    model=MODEL_NAME,  # 使用统一的模型配置
    streaming=True,
    inference_config={'maxTokens': MAX_TOKENS_INITIALIZATION, 'temperature': TEMPERATURE_STABLE},
    custom_system_prompt={
        'template': """You create envgym directory structure. Use this single command:
"create envgym directory with empty files plan.txt next.txt status.txt log.txt ,history.txt, envgym.dockerfile inside it"
Then verify with: "list envgym directory contents".""",
        'variables': {}
    },
    tool_config={'tool': tool_codex, 'toolMaxRecursions': TOOL_MAX_RECURSIONS_SIMPLE}
))

# Auto-save agent - records execution status to history.txt
agent_auto_save = HybridAgent(HybridAgentOptions(
    name='auto_save_agent',
    description='Automatically saves execution status and file contents to history.txt for each iteration',
    api_key=my_api_key,
    model=MODEL_NAME,  # 使用统一的模型配置
    streaming=True,
    inference_config={'maxTokens': MAX_TOKENS_AGENT_DEFAULT, 'temperature': TEMPERATURE_PRECISE},
    custom_system_prompt={
        'template': """You save execution status to history.txt. For iteration {i}, execute these commands:
1. "append to envgym/history.txt: === Iteration {i} - [current timestamp] ==="
2. "If any file in step 3,4,5,6 is empty, just skip it"
3. "read envgym/plan.txt and append its content to envgym/history.txt with prefix 'PLAN: '"
4. "read envgym/next.txt and append its content to envgym/history.txt with prefix 'NEXT: '"
5. "read envgym/status.txt and append its content to envgym/history.txt with prefix 'STATUS: '"
6. "read envgym/log.txt and append its content to envgym/history.txt with prefix 'LOG: '"
7. "append to envgym/history.txt: '--- End of Iteration {i} ---'"
Always append, never overwrite history.txt.""",
        'variables': {}
    },
    tool_config={'tool': tool_codex, 'toolMaxRecursions': TOOL_MAX_RECURSIONS_COMPLEX}
))

# Planning agent - analyzes project and generates environment configuration plan
agent_planner = HybridAgent(HybridAgentOptions(
    name='planner_agent',
    description='This is an agent for making comprehensive plans before environment configuration and write it in envgym/plan.txt',
    api_key=my_api_key,
    model=MODEL_NAME,  # 使用统一的模型配置
    streaming=True,
    inference_config={'maxTokens': MAX_TOKENS_AGENT_DEFAULT, 'temperature': TEMPERATURE_STABLE},
    custom_system_prompt={
        'template': """You need to make a comprehensive plan of how to build up a complete docker image to run the project and please remember to write it in envgym/plan.txt.
First ,make sure you can access the envgym directory and there is a plan.txt file in it.

Analysis priority:
1. First check existing README files (README.md, README.txt, readme.md etc.)
2. Then check existing environment files (Dockerfile, requirements.txt, package.json, setup.py, pyproject.toml etc.)
3. If above info insufficient, analyze repository structure
4. If you find any new information, update the plan.txt with the new information.

Output format to envgym/plan.txt:
=== ENVIRONMENT SETUP PLAN ===
1. DOWNLOADS NEEDED: [specific list]
2. FILES TO CREATE: [specific list]  
3. COMPLETE TODO LIST: [specific steps]
Make sure you have make a complete plan, and the plan is updated to envgym/plan.txt.Tell me if there is something wrong saving it to envgym/plan.txt""",
        'variables': {}
    },
    tool_config={'tool': tool_codex, 'toolMaxRecursions': TOOL_MAX_RECURSIONS_PLANNING}
))

# Write Docker agent - writes and prepares Dockerfile
write_docker_agent = HybridAgent(HybridAgentOptions(
    name='write_docker_agent',
    description='Writes Dockerfile: analyzes status, creates virtual environment, generates/updates Dockerfile',
    api_key=my_api_key,
    model=MODEL_NAME,  # 使用统一的模型配置
    streaming=True,
    inference_config={'maxTokens': MAX_TOKENS_AGENT_DEFAULT, 'temperature': TEMPERATURE_STABLE},
    custom_system_prompt={
        'template': """IMPORTANT: You write Dockerfile to envgym/envgym.dockerfile - this is the ONLY target file for Dockerfile generation.

You write Dockerfile. Execute these steps:

1. Please read the codebase before writing dockerfile
2. Check envgym/status.txt and envgym/next.txt - if empty, this is first execution (only read plan.txt), otherwise read all files to understand current situation
3. "create or modify Dockerfile in envgym/envgym.dockerfile based on plan.txt requirements and current status/next steps"
4. "write 'Ready for Docker execution' to envgym/next.txt"
5. "write current Dockerfile preparation status to envgym/status.txt"

CRITICAL: 
- ALL Dockerfile content MUST be written to envgym/envgym.dockerfile
- You only write Dockerfile, do NOT run Docker commands
- The run docker agent will automatically use envgym/envgym.dockerfile""",
        'variables': {}
    },
    tool_config={'tool': tool_codex, 'toolMaxRecursions': TOOL_MAX_RECURSIONS_DOCKER}
))

# Update log file agent - updates log files and status
update_log_file_agent = HybridAgent(HybridAgentOptions(
    name='update_log_file_agent',
    description='Updates log files: analyzes Docker execution results from log.txt and updates status.txt and next.txt',
    api_key=my_api_key,
    model=MODEL_NAME,  # 使用统一的模型配置
    streaming=True,
    inference_config={'maxTokens': MAX_TOKENS_AGENT_DEFAULT, 'temperature': TEMPERATURE_STABLE},
    custom_system_prompt={
        'template': """You update log files and status. Execute these steps:

1. "read envgym/log.txt to understand Docker execution results"
2. Analyze execution results:
   - Identify successful steps and failed steps
   - Determine root causes of any failures
   - Assess overall progress toward environment setup goals
3. "write detailed analysis of successful and failed steps to envgym/status.txt"
4. "write specific next steps needed based on results to envgym/next.txt"
5. If major issues found, suggest Dockerfile improvements for next iteration

Always provide actionable analysis and clear next steps for continuous improvement.""",
        'variables': {}
    },
    tool_config={'tool': tool_codex, 'toolMaxRecursions': TOOL_MAX_RECURSIONS_COMPLEX}
))


# Docker runner tool
tool_docker_runner = AgentTools([
    AgentTool(
        name="run_dockerfile",
        description="Execute Dockerfile using defaults: envgym/envgym.dockerfile and capture logs to envgym/log.txt",
        properties={
            "cleanup": {
                "type": "boolean",
                "description": "Whether to cleanup Docker images after execution (default: true)"
            },
            "verbose": {
                "type": "boolean", 
                "description": "Enable verbose output during Docker operations (default: true)"
            }
        },
        func=run_dockerfile_with_logs,
        enum_values={}
    )
])

# Run Docker agent - runs Docker and captures logs
run_docker_agent = HybridAgent(HybridAgentOptions(
    name='run_docker_agent',
    description='Runs Docker: executes envgym/envgym.dockerfile and captures all logs to envgym/log.txt',
    api_key=my_api_key,
    model=MODEL_NAME,  # 使用统一的模型配置
    streaming=True,
    
    # Inference configuration
    inference_config={
        'maxTokens': MAX_TOKENS_AGENT_DEFAULT,
        'temperature': TEMPERATURE_STABLE,    # Lower temperature for stable execution
        'topP': TOP_P_DEFAULT,
        'stopSequences': None
    },

    # Custom system prompt
    custom_system_prompt={
        'template': """You are an AI assistant specialized in {{DOMAIN}}.

IMPORTANT: The tool automatically uses default paths:
- Dockerfile: "envgym/envgym.dockerfile" (relative to current working directory)
- Log output: "envgym/log.txt" (will be overwritten)

Your workflow:
1. Use the run_dockerfile tool with minimal parameters (it has smart defaults)
2. The tool automatically captures ALL build and run logs to "envgym/log.txt"
3. Display the complete execution results
4. Report success/failure status clearly
5. If there are errors, provide detailed diagnostics

Key capabilities:
{{CAPABILITIES}}

Always provide detailed feedback about:
- Docker build success/failure
- Container run results
- Any error messages or warnings
- Performance information
- Next steps or recommendations""",
        'variables': {
            'DOMAIN': 'Docker Environment Execution and Log Management',
            'CAPABILITIES': '''- Automatically find and execute envgym/envgym.dockerfile
- Use smart defaults for paths (no manual configuration needed)
- Capture comprehensive build and run logs
- Overwrite envgym/log.txt with fresh results
- Handle Docker errors gracefully
- Provide detailed execution reports
- Cleanup Docker resources after execution'''
        }
    },
    
    # Tool configuration
    tool_config={
        'tool': tool_docker_runner,
        'toolMaxRecursions': TOOL_MAX_RECURSIONS_EXECUTION,
    }
))

# # Create dummy agents for supervisor team
# dummy_agent2 = HybridAgent(HybridAgentOptions(
#     name='dummy_agent that cant do anything',
#     description='do not call me, i will not do anything',
#     api_key=my_api_key,
# ))

# dummy_agent = HybridAgent(HybridAgentOptions(
#     name='dummy_agent2 that cant do anything',
#     description='This agent is a dummy agent that can only respond to the user\'s request',
#     api_key=my_api_key,
# ))

# Dummy_leader=SupervisorAgent(SupervisorAgentOptions(
#     name="SupervisorAgent",
#     description="You are a supervisor agent that manages dummy/testing agents and handles general coordination tasks",
#     lead_agent=HybridAgent(HybridAgentOptions(
#         name="Dummy Support Team",
#         description="Coordinates dummy agents for testing and fallback purposes",
#         api_key=my_api_key,
#     )),
#     team=[dummy_agent, dummy_agent2]  # Only dummy agents under supervisor
# ))


# orchestrator.add_agent(agent_package_compatibility)
# orchestrator.add_agent(agent_repo_map)
# orchestrator.add_agent(Dummy_leader)
orchestrator.add_agent(agent_initialization)  # Add initialization agent
orchestrator.add_agent(agent_auto_save)  # Add auto-save agent
orchestrator.add_agent(agent_planner)  # Add planning agent
orchestrator.add_agent(write_docker_agent)  # Add write docker agent
orchestrator.add_agent(run_docker_agent)  # Add run docker agent
orchestrator.add_agent(update_log_file_agent)  # Add update log file agent




async def handle_request(_orchestrator: AgentSquad, _user_input: str, _user_id: str, _session_id: str):
    response: AgentResponse = await _orchestrator.route_request(_user_input, _user_id, _session_id)
    print("\nMetadata:")
    print(f"Selected Agent: {response.metadata.agent_name}")
    if response.streaming:
        print('Response:', response.output.content[0]['text'])
    else:
        print('Response:', response.output.content[0]['text'])  
if __name__ == "__main__":
    USER_ID = "user1231"
    SESSION_ID = str(uuid.uuid4())
    
    user_input = """Please build and run the dockerfile in envgym/envgym.dockerfile and output the log in envgym/log.txt
    """
    await_response = asyncio.run(handle_request(orchestrator, user_input, USER_ID, SESSION_ID))
   
   




 