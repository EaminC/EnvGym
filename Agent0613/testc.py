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

# Create dummy agents for supervisor team
dummy_agent2 = HybridAgent(HybridAgentOptions(
    name='dummy_agent that cant do anything',
    description='do not call me, i will not do anything',
    api_key=my_api_key,
))

dummy_agent = HybridAgent(HybridAgentOptions(
    name='dummy_agent2 that cant do anything',
    description='This agent is a dummy agent that can only respond to the user\'s request',
    api_key=my_api_key,
))

Dummy_leader=SupervisorAgent(SupervisorAgentOptions(
    name="SupervisorAgent",
    description="You are a supervisor agent that manages dummy/testing agents and handles general coordination tasks",
    lead_agent=HybridAgent(HybridAgentOptions(
        name="Dummy Support Team",
        description="Coordinates dummy agents for testing and fallback purposes",
        api_key=my_api_key,
    )),
    team=[dummy_agent, dummy_agent2]  # Only dummy agents under supervisor
))


orchestrator.add_agent(agent_package_compatibility)
orchestrator.add_agent(agent_repo_map)
orchestrator.add_agent(Dummy_leader)
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


    
    # Step 3: Use codex_agent to create and test Dockerfile
    print("\nStep 3: Dockerfile Creation")
    user_input = """Create a python script that prints 'Hello, World!in the current directory"""
    
    print("Sending request to codex_agent for Dockerfile creation...")
    await_response = asyncio.run(handle_request(orchestrator, user_input, USER_ID, SESSION_ID))
    
 



 