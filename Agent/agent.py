import os
import sys
from pathlib import Path
import uuid
import asyncio
import json
import time
from datetime import datetime


# Add local agent_squad module path
current_dir = Path(__file__).resolve().parent
agent_squad_path = current_dir.parent / "python" / "src"
sys.path.insert(0, str(agent_squad_path))
from agent_squad.classifiers import OpenAIClassifier, OpenAIClassifierOptions
from agent_squad.orchestrator import AgentSquad
from agent_squad.storage import InMemoryChatStorage
from agent_squad.utils import AgentTools, AgentTool
from agent_squad.agents import AgentResponse,HybridAgent, HybridAgentOptions

#Tool
from tool.codex.entry import simple_codex_agent
from tool.dockerrun.entry import run_dockerfile_with_logs
from tool.history_manager.entry import auto_save_to_history, read_history_summary
from tool.initial.entry import create_envgym_directory
from tool.update.entry import update_log_files


from prompt.planning import plan_instruction
from prompt.write_docker import write_docker_instruction
from prompt.write_docker_initial import write_docker_initial_instruction
from prompt.updating import updating_instruction
from prompt.run_docker import run_docker_instruction
#Model Config
MODEL_NAME_DEFAULT = 'gpt-4.1'

MAX_TOKENS_DEFAULT = 4500

TEMPERATURE_DEFAULT = 0.7

TOP_P_DEFAULT = 0.9

TOOL_MAX_RECURSIONS_DEFAULT = 20


from dotenv import load_dotenv
dotenv_path = Path(__file__).resolve().parent.parent / ".env"
if not dotenv_path.exists():
    raise FileNotFoundError(f".env file not found at {dotenv_path}")
    
load_dotenv(dotenv_path=dotenv_path, override=True)

my_api_key = os.getenv("OPENAI_API_KEY")
if not my_api_key:
    raise EnvironmentError("Missing OPENAI_API_KEY in .env file")

custom_openai_classifier = OpenAIClassifier(OpenAIClassifierOptions(
    api_key=my_api_key,
    model_id=MODEL_NAME_DEFAULT,
    inference_config={
        'max_tokens': MAX_TOKENS_DEFAULT,
        'temperature': TEMPERATURE_DEFAULT,
        'top_p': TOP_P_DEFAULT,
        'stop_sequences': ['']
    }
))
 
orchestrator = AgentSquad(classifier=custom_openai_classifier,storage=InMemoryChatStorage())

orchestrator.classifier.set_system_prompt(
    """
    {{AGENT_DESCRIPTIONS}}
    {{ROUTING_INSTRUCTIONS}}
    """,
    {
        "AGENT_DESCRIPTIONS": "You are AgentMatcher, an intelligent assistant designed to analyze user queries and match them with the most suitable agent or department.",
        "ROUTING_INSTRUCTIONS": " Your task is to understand the user's request,identify key entities and intents, and determine which agent or department would be best equipped to handle the query."
    }
)

tool_initial_repo = AgentTools([
    AgentTool(
        name="create_envgym_directory",
        description="Create a new envgym directory in the current repository before starting to build up the environment of this repository for the user",
        func=create_envgym_directory,
        enum_values={}
    )
])

tool_codex = AgentTools([
    AgentTool(
        name="codex_agent",
        description="Codex agent interface for executing natural language task descriptions using Codex CLI",
        properties={
            "task_description": {
                "type": "string",
                "description": "A natural language description of the task to perform, such as 'create a test.txt file in current directory', 'list files in current directory', or 'show directory structure' or write something to a file"
            }
        },
        func=simple_codex_agent,
        enum_values={}
    )
])

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

agent_initial_repo = HybridAgent(HybridAgentOptions(
    name='initial_repo_agent',
    description='An agent that creates a new envgym directory in the current repository before starting to build up the environment of this repository for the user',
    api_key=my_api_key,
    model=MODEL_NAME_DEFAULT,
    streaming=True,
    inference_config={
        'max_tokens': MAX_TOKENS_DEFAULT,
        'temperature': TEMPERATURE_DEFAULT,
        'top_p': TOP_P_DEFAULT,
        'stop_sequences': ['']
    },
    tool_config={
        'tool': tool_initial_repo,
        'toolMaxRecursions': TOOL_MAX_RECURSIONS_DEFAULT, 
    }
))

agent_planner = HybridAgent(HybridAgentOptions(
    name='planner_agent',
    description='This is an agent for making comprehensive plans before environment configuration and write it in envgym/plan.txt .It only reads the basic document but does not go through the codebase',
    api_key=my_api_key,
    model=MODEL_NAME_DEFAULT,   
    streaming=True,
    inference_config={'maxTokens': MAX_TOKENS_DEFAULT, 'temperature':TEMPERATURE_DEFAULT},
    custom_system_prompt={
        'template': plan_instruction,
        'variables': {}
    },
    tool_config={'tool': tool_codex, 'toolMaxRecursions': TOOL_MAX_RECURSIONS_DEFAULT}
))

agent_dockerfile_writer = HybridAgent(HybridAgentOptions(
    name='dockerfile_writer_agent',
    description='This is an agent for writing a dockerfile to build up the environment:Writes Dockerfile: analyzes status, creates virtual environment, generates/updates Dockerfile',
    api_key=my_api_key,
    model=MODEL_NAME_DEFAULT,   
    streaming=True,
    inference_config={'maxTokens': MAX_TOKENS_DEFAULT, 'temperature':TEMPERATURE_DEFAULT},
    custom_system_prompt={
        'template': write_docker_instruction
    },
    tool_config={'tool': tool_codex, 'toolMaxRecursions': TOOL_MAX_RECURSIONS_DEFAULT}
))

agent_dockerfile_runner = HybridAgent(HybridAgentOptions(
    name='run_docker_agent',
    description='Runs Docker: executes envgym/envgym.dockerfile and captures all logs to envgym/log.txt using the run_dockerfile tool,also summarize the build and run status to envgym/next.txt using the codex tool',
    api_key=my_api_key,
    model=MODEL_NAME_DEFAULT,  
    streaming=True,
    
    # Inference configuration
    inference_config={
        'maxTokens': MAX_TOKENS_DEFAULT,
        'temperature': TEMPERATURE_DEFAULT,  
        'topP': TOP_P_DEFAULT,
        'stopSequences': None
    },

    # Custom system prompt
    custom_system_prompt={
        'template': run_docker_instruction
    },
    
    # Tool configuration
    tool_config={
        'tool': [tool_docker_runner,tool_codex],
        'toolMaxRecursions': TOOL_MAX_RECURSIONS_DEFAULT,
    }
))

agent_auto_save = HybridAgent(HybridAgentOptions(
    name='auto_save_agent',
    description='Automatically saves execution status and file contents to history.txt for each iteration',
    api_key=my_api_key,
    model=MODEL_NAME_DEFAULT,  # Use unified model configuration
    streaming=True,
    inference_config={'maxTokens': MAX_TOKENS_DEFAULT, 'temperature': TEMPERATURE_DEFAULT},
    custom_system_prompt={
        'template': updating_instruction,
        'variables': {}
    },
    tool_config={'tool': tool_codex, 'toolMaxRecursions': TOOL_MAX_RECURSIONS_DEFAULT}
))
orchestrator.add_agent(agent_initial_repo)
orchestrator.add_agent(agent_planner)
orchestrator.add_agent(agent_dockerfile_writer)
orchestrator.add_agent(agent_dockerfile_runner)
orchestrator.add_agent(agent_auto_save)


async def handle_request(_orchestrator: AgentSquad, _user_input: str, _user_id: str, _session_id: str):
    response: AgentResponse = await _orchestrator.route_request(_user_input, _user_id, _session_id)
    print("\nMetadata:")
    print(f"Selected Agent: {response.metadata.agent_name}")
    if response.streaming:
        print('Response:', response.output.content[0]['text'])
    else:
        print('Response:', response.output.content[0]['text'])   

def check_success_status():
    """Check if the environment build is successful"""
    status_file_path = os.path.join(os.getcwd(), "envgym", "status.txt")
    
    if os.path.exists(status_file_path):
        with open(status_file_path, "r") as f:
            if "SUCCESS" in f.read():
                return True
    return False
            
if __name__ == "__main__":
    USER_ID = "user1231"
    SESSION_ID = str(uuid.uuid4())


    user_input = """Now please initialize the envgym directory in current directory.
    """
    await_response = asyncio.run(handle_request(orchestrator, user_input, USER_ID, SESSION_ID))
    
    user_input = plan_instruction+"""Now please make a comprehensive plan of how to build up a complete docker image to run the project and write it in envgym/plan.txt.
    """
    await_response = asyncio.run(handle_request(orchestrator, user_input, USER_ID, SESSION_ID))

    Exec_Repeat = 20
    for i in range(Exec_Repeat):
       
        print(f"=== Iteration {i+1} ===")
        print(f"\n--- Step 1: Write Dockerfile (Iteration {i+1}) ---")
        if i == 0:
            user_input = write_docker_initial_instruction+"""Now please write a dockerfile to build up the environment and write it in envgym/envgym.dockerfile.
            """
        else:
            user_input = write_docker_instruction+"""Now please write a dockerfile to build up the environment and write it in envgym/envgym.dockerfile.
        """
        await_response = asyncio.run(handle_request(orchestrator, user_input, USER_ID, SESSION_ID))

        print(f"\n--- Step 2: Run Dockerfile (Iteration {i+1}) ---")
        user_input = run_docker_instruction+"""Now please run the dockerfile to build up the environment and capture the logs to envgym/log.txt.
        """
        await_response = asyncio.run(handle_request(orchestrator, user_input, USER_ID, SESSION_ID))

        print(f"\n--- Step 3: Update Status (Iteration {i+1}) ---")
        
        user_input = updating_instruction+"""Please save the current execution status for iteration {i+1}. 
        """    
        await_response = asyncio.run(handle_request(orchestrator, user_input, USER_ID, SESSION_ID))
        user_input = updating_instruction+"""Now please update the status of the environment to the following files:
        """
        update_log_files(i+1,verbose=True)
        if check_success_status():
            break
