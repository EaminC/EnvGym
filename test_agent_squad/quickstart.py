import os
from dotenv import load_dotenv
from agent_squad.classifiers import OpenAIClassifier, OpenAIClassifierOptions
from agent_squad.orchestrator import AgentSquad
from agent_squad.agents import OpenAIAgent, OpenAIAgentOptions
import uuid
import asyncio
import sys
from compat.py.deptree import get_dependency_tree as get_dependency_tree_py
from compat.py.show import get_versions as get_versions_py
from compat.go.deptree import get_dependency_tree as get_dependency_tree_go
from compat.go.show import get_versions as get_versions_go
from compat.rust.deptree import get_dependency_tree as get_dependency_tree_rust
from compat.rust.show import get_versions as get_versions_rust
from compat.java.deptree import get_dependency_tree as get_dependency_tree_java
from compat.java.show import get_versions as get_versions_java
from compat.cpp.deptree import get_dependency_tree as get_dependency_tree_cpp
from compat.cpp.show import get_versions as get_versions_cpp
import json


dotenv_path = "../.env"
load_dotenv(dotenv_path=dotenv_path)
my_api_key = os.getenv("OPENAI_API_KEY")
custom_openai_classifier = OpenAIClassifier(OpenAIClassifierOptions(
    api_key=my_api_key,
    model_id='gpt-4o',
    inference_config={
        'max_tokens': 1500,
        'temperature': 0.7,
        'top_p': 0.9,
        'stop_sequences': ['']
    }
))

orchestrator = AgentSquad(classifier=custom_openai_classifier)

orchestrator.classifier.set_system_prompt(
    """
    {{AGENT_DESCRIPTIONS}}
    {{ROUTING_INSTRUCTIONS}}
    """,
    {
        "AGENT_DESCRIPTIONS": "You are an AI assistant with expertise in package compatibility analysis. Your primary function is to assess whether one software package is compatible with another, considering versioning, dependencies, and platform requirements.",
        "ROUTING_INSTRUCTIONS": "Multiple specialized agents are available, each with proficiency in a specific programming language. You are responsible for intelligently routing incoming requests to the most appropriate agent based on the language and context of the query."
    }
)


#python agent

agent_python = OpenAIAgent(OpenAIAgentOptions(
    # Required fields
    name='python_agent',
    description='A python package compatibility checker',
    api_key=my_api_key,

    # Optional fields
    model='gpt-4o',         # Choose OpenAI model
    streaming=True,        # Enable streaming responses
    #retriever=custom_retriever,  # Custom retriever for additional context

    # Inference configuration
    inference_config={
        'maxTokens': 500,     # Maximum tokens to generate
        'temperature': 0.7,   # Control randomness (0-1)
        'topP': 0.9,         # Control diversity via nucleus sampling
        'stopSequences': ['Human:', 'AI:']  # Sequences that stop generation
    },

    # Custom system prompt with variables
    custom_system_prompt={
        'template': """You are an AI assistant specialized in {{DOMAIN}}.You are a specialist in programming language : {{LANGUAGE}}.Now you are given two package names and their versions.Your task is to check if the package is compatible with another package.
               }""",
        'variables': {
            'DOMAIN': 'Help determine if a package is compatible with another package',
            'LANGUAGE': 'Python'
        }
    }
))

orchestrator.add_agent(agent_python)

#rust agent
agent_rust = OpenAIAgent(OpenAIAgentOptions(
    # Required fields
    name='rust_agent',
    description='A rust package compatibility checker',
    api_key=my_api_key,

    # Optional fields
    model='gpt-4o',         # Choose OpenAI model
    streaming=True,        # Enable streaming responses
    #retriever=custom_retriever,  # Custom retriever for additional context

    # Inference configuration
    inference_config={
        'maxTokens': 500,     # Maximum tokens to generate
        'temperature': 0.7,   # Control randomness (0-1)
        'topP': 0.9,         # Control diversity via nucleus sampling
        'stopSequences': ['Human:', 'AI:']  # Sequences that stop generation
    },

    # Custom system prompt with variables
    custom_system_prompt={
        'template': """You are an AI assistant specialized in {{DOMAIN}}.You are a specialist in programming language : {{LANGUAGE}}.Now you are given two package names and their versions.Your task is to check if the package is compatible with another package.
               }""",
        'variables': {
            'DOMAIN': 'Help determine if a package is compatible with another package',
            'LANGUAGE': 'Rust'
        }
    }
))

orchestrator.add_agent(agent_rust)

agent_go = OpenAIAgent(OpenAIAgentOptions(
    # Required fields
    name='go_agent',
    description='A python package compatibility checker',
    api_key=my_api_key,

    # Optional fields
    model='gpt-4o',         # Choose OpenAI model
    streaming=True,        # Enable streaming responses
    #retriever=custom_retriever,  # Custom retriever for additional context

    # Inference configuration
    inference_config={
        'maxTokens': 500,     # Maximum tokens to generate
        'temperature': 0.7,   # Control randomness (0-1)
        'topP': 0.9,         # Control diversity via nucleus sampling
        'stopSequences': ['Human:', 'AI:']  # Sequences that stop generation
    },

    # Custom system prompt with variables
    custom_system_prompt={
        'template': """You are an AI assistant specialized in {{DOMAIN}}.You are a specialist in programming language : {{LANGUAGE}}.Now you are given two package names and their versions.Your task is to check if the package is compatible with another package.
               }""",
        'variables': {
            'DOMAIN': 'Help determine if a package is compatible with another package',
            'LANGUAGE': 'Go'
        }
    }
))

orchestrator.add_agent(agent_go)

agent_cpp = OpenAIAgent(OpenAIAgentOptions(
    # Required fields
    name='cpp_agent',
    description='A cpp package compatibility checker',
    api_key=my_api_key,

    # Optional fields
    model='gpt-4o',         # Choose OpenAI model
    streaming=True,        # Enable streaming responses
    #retriever=custom_retriever,  # Custom retriever for additional context

    # Inference configuration
    inference_config={
        'maxTokens': 1500,     # Maximum tokens to generate
        'temperature': 0.7,   # Control randomness (0-1)
        'topP': 0.9,         # Control diversity via nucleus sampling
        'stopSequences': ['Human:', 'AI:']  # Sequences that stop generation
    },

    # Custom system prompt with variables
    custom_system_prompt={
        'template': """You are an AI assistant specialized in {{DOMAIN}}.You are a specialist in programming language : {{LANGUAGE}}.Now you are given two package names and their versions.Your task is to check if the package is compatible with another package.
               }""",
        'variables': {
            'DOMAIN': 'Help determine if a package is compatible with another package',
            'LANGUAGE': 'C++'
        }
    }
))

orchestrator.add_agent(agent_cpp)

agent_java = OpenAIAgent(OpenAIAgentOptions(
    # Required fields
    name='java_agent',
    description='A java package compatibility checker',
    api_key=my_api_key,

    # Optional fields
    model='gpt-4o',         # Choose OpenAI model
    streaming=True,        # Enable streaming responses
    #retriever=custom_retriever,  # Custom retriever for additional context

    # Inference configuration
    inference_config={
        'maxTokens': 500,     # Maximum tokens to generate
        'temperature': 0.7,   # Control randomness (0-1)
        'topP': 0.9,         # Control diversity via nucleus sampling
        'stopSequences': ['Human:', 'AI:']  # Sequences that stop generation
    },

    # Custom system prompt with variables
    custom_system_prompt={
        'template': """You are an AI assistant specialized in {{DOMAIN}}.You are a specialist in programming language : {{LANGUAGE}}.Now you are given two package names and their versions.Your task is to check if the package is compatible with another package.
               }""",
        'variables': {
            'DOMAIN': 'Help determine if a package is compatible with another package',
            'LANGUAGE': 'java'
        }
    }
))

orchestrator.add_agent(agent_java)

async def handle_request(_orchestrator: AgentSquad, _user_input: str, _user_id: str, _session_id: str):
    response: AgentResponse = await _orchestrator.route_request(_user_input, _user_id, _session_id)
    print("\nMetadata:")
    print(f"Selected Agent: {response.metadata.agent_name}")
    if response.streaming:
        print('Response:', response.output.content[0]['text'])
    else:
        print('Response:', response.output.content[0]['text'])


def get_package_analysis(language, package1, package2):
    """Get dependency trees and version information for packages"""
    try:
        if language == "python":
            tree1 = get_dependency_tree_py(package1)
            tree2 = get_dependency_tree_py(package2)
            version1 = get_versions_py(package1.split("==")[0] if "==" in package1 else package1)
            version2 = get_versions_py(package2.split("==")[0] if "==" in package2 else package2)
        elif language == "go":
            tree1 = get_dependency_tree_go(package1)
            tree2 = get_dependency_tree_go(package2)
            version1 = get_versions_go(package1.split("@")[0] if "@" in package1 else package1)
            version2 = get_versions_go(package2.split("@")[0] if "@" in package2 else package2)
        elif language == "rust":
            tree1 = get_dependency_tree_rust(package1)
            tree2 = get_dependency_tree_rust(package2)
            version1 = get_versions_rust(package1.split("@")[0] if "@" in package1 else package1)
            version2 = get_versions_rust(package2.split("@")[0] if "@" in package2 else package2)
        elif language == "java":
            tree1 = get_dependency_tree_java(package1)
            tree2 = get_dependency_tree_java(package2)
            version1 = get_versions_java(package1.split(":")[0] + ":" + package1.split(":")[1] if ":" in package1 else package1)
            version2 = get_versions_java(package2.split(":")[0] + ":" + package2.split(":")[1] if ":" in package2 else package2)
        elif language == "cpp":
            tree1 = get_dependency_tree_cpp(package1)
            tree2 = get_dependency_tree_cpp(package2)
            version1 = get_versions_cpp(package1.split("[")[0] if "[" in package1 else package1)
            version2 = get_versions_cpp(package2.split("[")[0] if "[" in package2 else package2)
        else:
            return None
        
        return {
            'tree1': tree1,
            'tree2': tree2,
            'version1': version1,
            'version2': version2
        }
    except Exception as e:
        print(f"Error getting package analysis: {e}")
        return None
if __name__ == "__main__":
    USER_ID = "user123"
    SESSION_ID = str(uuid.uuid4())

    if len(sys.argv) >= 3:
        language = sys.argv[1]
        package1 = sys.argv[2]
        package2 = sys.argv[3]
        analysis = get_package_analysis(language, package1, package2)
    else:
        print("Please provide the language, package1, and package2 as command line arguments")
        sys.exit()
    print(analysis)
    if analysis:
        # 限制字符串长度并清理特殊字符
        def clean_and_limit(text, max_length=500):
            if not text:
                return "No information"
            # 清理特殊字符
            cleaned = text.replace('\n', ' ').replace('\r', '').replace('\t', ' ').replace('"', "'").replace('\\', '/').strip()
            # 限制长度
            if len(cleaned) > max_length:
                cleaned = cleaned[:max_length] + "..."
            return cleaned
        
        tree1_clean = clean_and_limit(analysis['tree1'])
        tree2_clean = clean_and_limit(analysis['tree2'])
        version1_clean = clean_and_limit(analysis['version1'])
        version2_clean = clean_and_limit(analysis['version2'])
        
        user_input = f"Please analyze compatibility between {language} packages {package1} and {package2}. Please determine if these two packages are compatible based on the dependency analysis. If compatible, just answer 'Compatible'; If incompatible, answer 'Incompatible' followed by suggested modifications. The first package is {package1}, dependency tree: {tree1_clean}, versions: {version1_clean}. The second package is {package2}, dependency tree: {tree2_clean}, versions: {version2_clean}."

        asyncio.run(handle_request(orchestrator, user_input, USER_ID, SESSION_ID))
    else:
        print(f"Error: Unsupported language '{language}' or package analysis failed")
        sys.exit()
   
    





