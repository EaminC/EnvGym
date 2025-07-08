import os
import sys
from pathlib import Path
import uuid
import asyncio
import json
import time
from datetime import datetime



from tool.codex.entry import simple_codex_agent
from tool.dockerrun.entry import run_dockerfile_with_logs
from tool.history_manager.entry import auto_save_to_history, read_history_summary
from tool.initial.entry import create_envgym_directory
from tool.update.entry import update_log_files
from tool.planning.entry import PlanningTool


from prompt.scanning import scanning_instruction
from prompt.planning import plan_instruction
from prompt.write_docker import write_docker_instruction
from prompt.write_docker_initial import write_docker_initial_instruction
from prompt.updating import updating_instruction
from prompt.run_docker import run_docker_instruction


  

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


    # print("Initializing envgym directory")
    # create_envgym_directory()
    
    
    # print("Mapping the whole repo")
    # simple_codex_agent(scanning_instruction,streaming=True)
    
    #print("Planning the whole project")
    #PlanningTool().run()

    
    #simple_codex_agent(user_input,streaming=True)

    # Exec_Repeat = 20
    # for i in range(Exec_Repeat):
       
    #     print(f"=== Iteration {i+1} ===")
    #     print(f"\n--- Step 1: Write Dockerfile (Iteration {i+1}) ---")
    #     if i == 0:
    #         user_input = write_docker_initial_instruction+"""Now please write a dockerfile to build up the environment and write it in envgym/envgym.dockerfile.
    #         """
    #     else:
    #         user_input = write_docker_instruction+"""Now please write a dockerfile to build up the environment and write it in envgym/envgym.dockerfile.
    #     """
    #     simple_codex_agent(user_input)

    #     print(f"\n--- Step 2: Run Dockerfile (Iteration {i+1}) ---")
    #     user_input = run_docker_instruction+"""Now please run the dockerfile to build up the environment and capture the logs to envgym/log.txt.
    #     """
    #     run_dockerfile_with_logs()

    #     print(f"\n--- Step 3: Update Status (Iteration {i+1}) ---")
        
    #     user_input = updating_instruction+"""Please save the current execution status for iteration {i+1}. 
    #     """    
    #     simple_codex_agent(user_input)
    #     user_input = updating_instruction+"""Now please update the status of the environment to the following files:
    #     """
    #     update_log_files(i+1,verbose=True)
    #     if check_success_status():
    #         break
