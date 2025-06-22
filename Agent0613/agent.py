import os
from dotenv import load_dotenv
from agent_squad.classifiers import OpenAIClassifier, OpenAIClassifierOptions
from agent_squad.orchestrator import AgentSquad
from agent_squad.storage import InMemoryChatStorage
from agent_squad.utils import AgentTools, AgentTool
from agent_squad.agents import AgentResponse, SupervisorAgent, SupervisorAgentOptions, HybridAgent, HybridAgentOptions
import uuid
import asyncio
import sys
import json
from pathlib import Path
import time

#tools
from tool.compat.package_version import analyze_package_formatted
from tool.aider.entry import get_repo_map
from tool.codex.entry import simple_codex_agent


dotenv_path = Path(__file__).resolve().parent.parent / ".env"
if not dotenv_path.exists():
    raise FileNotFoundError(f".env file not found at {dotenv_path}")
    
load_dotenv(dotenv_path=dotenv_path, override=True)

my_api_key = os.getenv("OPENAI_API_KEY")
if not my_api_key:
    raise EnvironmentError("Missing OPENAI_API_KEY in .env file")



custom_openai_classifier = OpenAIClassifier(OpenAIClassifierOptions(
    api_key=my_api_key,
    model_id='gpt-4o',
    inference_config={
        'max_tokens': 1500,
        'temperature': 0.2,
        'top_p': 0.9,
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

# 使用新的HybridAgent替代OpenAIAgent


# 创建AgentTools实例
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
    model='gpt-4o',         # Choose OpenAI model
    streaming=True,        # Enable streaming responses
    #retriever=custom_retriever,  # Custom retriever for additional context

    # Inference configuration
    inference_config={
        'maxTokens': 1000,     # Maximum tokens to generate
        'temperature': 0.7,   # Control randomness (0-1)
        'topP': 0.9,         # Control diversity via nucleus sampling
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
        'toolMaxRecursions': 5,  # Maximum number of tool calls in one conversation
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
    model='gpt-4o',         # Choose OpenAI model
    streaming=True,        # Enable streaming responses
    #retriever=custom_retriever,  # Custom retriever for additional context

    # Inference configuration
    inference_config={
        'maxTokens': 2000,     # Maximum tokens to generate
        'temperature': 0.3,   # Lower temperature for more focused analysis
        'topP': 0.9,         # Control diversity via nucleus sampling
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
        'toolMaxRecursions': 3,  # Maximum number of tool calls in one conversation
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

# 初始化设置agent - 创建envgym文件夹和相关文件
agent_initialization = HybridAgent(HybridAgentOptions(
    name='initialization_agent',
    description='Creates envgym directory with plan.txt, next.txt, status.txt, log.txt ,history.txt, envgym.dockerfile files',
    api_key=my_api_key,
    model='gpt-4o',
    streaming=True,
    inference_config={'maxTokens': 800, 'temperature': 0.2},
    custom_system_prompt={
        'template': """You create envgym directory structure. Use this single command:
"create envgym directory with empty files plan.txt next.txt status.txt log.txt ,history.txt, envgym.dockerfile inside it"
Then verify with: "list envgym directory contents".""",
        'variables': {}
    },
    tool_config={'tool': tool_codex, 'toolMaxRecursions': 3}
))

# 自动保存agent - 记录执行状态到history.txt
agent_auto_save = HybridAgent(HybridAgentOptions(
    name='auto_save_agent',
    description='Automatically saves execution status and file contents to history.txt for each iteration',
    api_key=my_api_key,
    model='gpt-4o',
    streaming=True,
    inference_config={'maxTokens': 1000, 'temperature': 0.1},
    custom_system_prompt={
        'template': """You save execution status to history.txt. For iteration {i}, execute these commands:
1. "append to envgym/history.txt: === Iteration {i} - [current timestamp] ==="
2. "If the any file in step 3,4,5,6 is empty, just skip it"
3. "read envgym/plan.txt and append its content to envgym/history.txt with prefix 'PLAN: '"
4. "read envgym/next.txt and append its content to envgym/history.txt with prefix 'NEXT: '"
5. "read envgym/status.txt and append its content to envgym/history.txt with prefix 'STATUS: '"
6. "read envgym/log.txt and append its content to envgym/history.txt with prefix 'LOG: '"
7. "append to envgym/history.txt: '--- End of Iteration {i} ---'"
Always append, never overwrite history.txt.""",
        'variables': {}
    },
    tool_config={'tool': tool_codex, 'toolMaxRecursions': 6}
))

# 计划agent - 分析项目并生成环境配置计划
agent_planner = HybridAgent(HybridAgentOptions(
    name='planner_agent',
    description='This is an agent for making comprehensive plans before environment configuration and write it in envgym/plan.txt',
    api_key=my_api_key,
    model='gpt-4o',
    streaming=True,
    inference_config={'maxTokens': 3000, 'temperature': 0.2},
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
    tool_config={'tool': tool_codex, 'toolMaxRecursions': 10}
))

# 环境搭建agent - 尝试搭建Docker环境
agent_env_setup = HybridAgent(HybridAgentOptions(
    name='env_setup_agent', 
    description='Attempts to setup Docker environment based on plan.txt, builds and tests configurations',
    api_key=my_api_key,
    model='gpt-4o',
    streaming=True,
    inference_config={'maxTokens': 2000, 'temperature': 0.2},
    custom_system_prompt={
        'template':  """You setup Docker environment based on current situation. Execute these steps:

1. "create virtual environment for the project"
2. Check envgym/status.txt and envgym/next.txt - if empty, this is first execution (only read plan.txt), otherwise read all files to understand current situation
3. "create or modify Dockerfile in envgym/envgym.dockerfile based on plan.txt requirements and current status/next steps"
4. "build Docker image from envgym/envgym.dockerfile and run it to test"
5. "capture all Docker build and run logs, write them to envgym/log.txt"
6. Analyze execution results:
   - "write successful steps and failed steps analysis to envgym/status.txt"
   - "write next steps needed based on results to envgym/next.txt"

Always check what worked and what didn't, update status and next steps accordingly.""",
        'variables': {}
    },
    tool_config={'tool': tool_codex, 'toolMaxRecursions': 8}
))

agent_codex = HybridAgent(HybridAgentOptions(
    # Required fields
    name='codex_agent',
    description='An advanced agent that executes natural language commands using Codex CLI for file operations and system tasks',
    api_key=my_api_key,
    model='gpt-4o',
    streaming=True,

    # Inference configuration
    inference_config={
        'maxTokens': 1500,     # 增加token以处理更复杂的命令
        'temperature': 0.3,    # 降低温度以获得更确定的输出
        'topP': 0.9,
        'stopSequences': None
    },

    # Custom system prompt with variables
    custom_system_prompt={
        'template': """You are an AI assistant specialized in {{DOMAIN}}.
You have access to a simplified Codex CLI tool that can execute natural language task descriptions for various system operations.

IMPORTANT GUIDELINES:
1. SAFETY FIRST: Always analyze tasks for potential risks before execution
2. CLARITY: Ensure task descriptions are clear and unambiguous
3. VERIFICATION: When possible, verify the results of executed tasks
4. ERROR HANDLING: Gracefully handle and report any errors
5. PERMISSIONS: Be mindful of file and system permissions

The simplified interface automatically uses:
{{AUTO_CONFIG}}

Best Practices:
1. Use clear, descriptive task descriptions
2. Start with safer operations before destructive ones
3. Be specific about file paths and operations
4. Provide clear feedback about task execution results
5. Break complex tasks into simpler, manageable steps

Current supported operations: {{OPERATIONS}}

Example task descriptions:
- "create a hello.txt file with content 'Hello World'"
- "list all Python files in current directory"
- "show current directory structure"
- "copy file.txt to backup_file.txt"
""",
        'variables': {
            'DOMAIN': 'System Operations and File Management',
            'AUTO_CONFIG': '''- Full-auto execution mode for immediate results
- Simplified single-parameter interface
- Automatic error handling and reporting''',
            'OPERATIONS': '''- File operations (create, read, modify, delete, copy)
- Directory management and listing
- System information queries
- Basic system commands
- Environment configuration
- Code analysis and manipulation'''
        }
    },
    
    # Tool configuration
    tool_config={
        'tool': tool_codex,
        'toolMaxRecursions': 7,  # 增加递归限制以处理复杂操作
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
orchestrator.add_agent(agent_initialization)  # 添加初始化agent
orchestrator.add_agent(agent_auto_save)  # 添加自动保存agent
orchestrator.add_agent(agent_planner)  # 添加计划agent
orchestrator.add_agent(agent_env_setup)  # 添加环境搭建agent
orchestrator.add_agent(agent_codex)




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
    
    # Test repository mapping functionality
    #user_input = "Generate a repository map for the current project directory '.' with maximum 2048 tokens, including  all necessary files and print the result in a markdown format including the repo map"
    
    # Alternative test cases:
    # user_input = "Please analyze compatibility between rust packages tokio==1.28.0 and serde==1.0.200"
    # user_input = "create a python script that prints 'Hello, World!'"
    #Output the current directory,only the last part of the path
#     Repo_Name = print(os.getcwd().split('/')[-1])
#     print("=== Environment Setup Demo ===")
    
#     # Step 1: Use repository_map_agent to analyze project structure
#     print("\nStep 1: Project Structure Analysis")
#     user_input = """I want to set up the development environment for this project in the current directory.
#     First, use the repository map tool to:
#     1. Analyze the project structure
#     2. List all Python files and their dependencies
#     3. Identify configuration files (requirements.txt, setup.py)
#     4. Determine the main entry points
#     5. Suggest key environment requirements"""
    
#     print("Sending request to repository_map_agent...")
#     await_response = asyncio.run(handle_request(orchestrator, user_input, USER_ID, SESSION_ID))
    
#     # # Step 2: Use package_compatibility_agent to check dependencies
#     # print("\nStep 2: Package Compatibility Check")
#     # user_input = """Now that we have the project structure, please:
#     # 1. Check all Python package dependencies
#     # 2. Identify any version conflicts
#     # 3. Analyze compatibility between packages
#     # 4. Suggest specific versions that work well together
#     # 5. List any potential issues we need to address in the Dockerfile"""
    
#     # print("Sending request to package_compatibility_agent...")
#     # await_response = asyncio.run(handle_request(orchestrator, user_input, USER_ID, SESSION_ID))
#     print("Step 2: What did i gave you just now about the repo map?")
#     user_input = """Repeat what you just responded to me.
#     """
#     await_response = asyncio.run(handle_request(orchestrator, user_input, USER_ID, SESSION_ID))
    
#     # Step 3: Use codex_agent to create and test Dockerfile
   


    
# #     print("\nStep 3: Dockerfile Creation")
# #     user_input = """First,tell me what you have learned about key points.Then,Thinking over previous conversations, please create a Dockerfile in current directory that Named as EnvGym-Today'sDate.Dockerfile:
# #     """
    
# #     print("Sending request to codex_agent for Dockerfile creation...")
# #     await_response = asyncio.run(handle_request(orchestrator, user_input, USER_ID, SESSION_ID))
    
# #     # Step 4: Build and test the environment
# #     print("\nStep 4: Environment Testing")
# #     user_input = """Please execute the following tasks:
# #     1. Build the Docker image using the created Dockerfile
# #     2. Run a test container with the image
# #     3. Execute a simple test (e.g., import all required packages)
# #     4. Run a basic example from the project
# #     5. Report any issues or success"""
    
# #     print("Sending request to codex_agent for testing...")
# #     await_response = asyncio.run(handle_request(orchestrator, user_input, USER_ID, SESSION_ID))
    
# #     # Step 5: Final verification and next steps
# #     print("\nStep 5: Verification and Next Steps")
# #     user_input = """Based on the test results:
# #     1. Verify if all components are working
# #     2. Check if all dependencies are properly installed
# #     3. Confirm the example ran successfully
# #     4. Suggest any improvements needed
# #     5. Provide instructions for daily development use"""
    
# #     print("Sending request for final verification...")
# #     await_response = asyncio.run(handle_request(orchestrator, user_input, USER_ID, SESSION_ID))
    
# #     print("\n=== Environment Setup Demo Completed ===")
    
# #     user_input = """
# # Summary the result of the environment setup process and provide next steps
# # """
# #     print("Sending request for final summary...")
# #     await_response = asyncio.run(handle_request(orchestrator, user_input, USER_ID, SESSION_ID))
   
    user_input = """Now please initialize the envgym directory in current directory.
    """
    await_response = asyncio.run(handle_request(orchestrator, user_input, USER_ID, SESSION_ID))
    Exec_Repeat = 2
    for i in range(Exec_Repeat):
        print(f"=== Iteration {i+1} ===")
        
        # 第一次迭代时生成项目计划
        if i == 0:
            plan_input = """You need to make a comprehensive plan of how to build up a complete docker image to run the project and please remember to write it in envgym/plan.txt.
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
Make sure you have make a complete plan, and the plan is updated to envgym/plan.txt.Tell me if there is something wrong saving it to envgym/plan.txt"""
            print(f"Generating project plan for iteration {i+1}...")
            await_response = asyncio.run(handle_request(orchestrator, plan_input, USER_ID, SESSION_ID))
        
        # 从第二次迭代开始执行环境配置
        if i >= 1:
            config_input = """You setup Docker environment based on current situation. Execute these steps:

1. "create virtual environment for the project"
2. Check envgym/status.txt and envgym/next.txt - if empty, this is first execution (only read plan.txt), otherwise read all files to understand current situation
3. "create or modify Dockerfile in envgym/envgym.dockerfile based on plan.txt requirements and current status/next steps"
4. "build Docker image from envgym/envgym.dockerfile and run it to test"
5. "capture all Docker build and run logs, write them to envgym/log.txt"
6. Analyze execution results:
   - "write successful steps and failed steps analysis to envgym/status.txt"
   - "write next steps needed based on results to envgym/next.txt"

Always check what worked and what didn't, update status and next steps accordingly."""
            
            print(f"Setting up environment for iteration {i+1}...")
            await_response = asyncio.run(handle_request(orchestrator, config_input, USER_ID, SESSION_ID))
        
        # 自动保存当前状态到history.txt
        save_input = f"""Please auto_save the current execution status for iteration {i+1}. 
        Read the contents of plan.txt, next.txt, status.txt, log.txt from envgym directory 
        and append them all to history.txt with proper formatting and timestamps.Always append, never overwrite history.txt."""
        
        print(f"Saving iteration {i+1} status...")
        await_response = asyncio.run(handle_request(orchestrator, save_input, USER_ID, SESSION_ID))
        





 