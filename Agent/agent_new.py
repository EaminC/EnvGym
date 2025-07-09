import os
import sys
from pathlib import Path
import uuid
import asyncio
import json
import time
from datetime import datetime


from tool.scanning.entry import ScanningTool
from tool.test_scanning.entry import TestScanningTool
from tool.codex.entry import simple_codex_agent
from tool.hardware_checking.entry import HardwareCheckingTool
from tool.dockerrun.entry import run_dockerfile_with_logs
from tool.history_manager.entry import auto_save_to_history, read_history_summary
from tool.initial.entry import create_envgym_directory
from tool.update.entry import update_log_files
from tool.planning.entry import PlanningTool
from tool.hardware_adjustment.entry import HardwareAdjustmentTool
from tool.writing_docker_initial.entry import WritingDockerInitialTool
from tool.writing_docker_revision.entry import WritingDockerRevisionTool
from tool.summarize.entry import SummarizeTool



  

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

    print("Initializing envgym directory")
    create_envgym_directory()
    
    print("Mapping the whole repo")
    ScanningTool().run()

    print("Scanning for test files")
    TestScanningTool().run()
    
    print("Checking the hardware")
    HardwareCheckingTool().run()

    print("Planning the whole project")
    PlanningTool().run()
    
    print("Adjusting plan based on hardware")
    HardwareAdjustmentTool().run()
    
    Exec_Repeat = 20
    for i in range(Exec_Repeat):
        print(f"=== Iteration {i+1} ===")
        print(f"\n--- Step 1: Write Dockerfile (Iteration {i+1}) ---")
        if i == 0:
            print("Writing initial dockerfile based on plan...")
            WritingDockerInitialTool().run()
        else:
            print("Revising dockerfile based on logs and recommendations...")
            WritingDockerRevisionTool().run()

        print(f"\n--- Step 2: Run Dockerfile (Iteration {i+1}) ---")
        run_dockerfile_with_logs()

        print(f"\n--- Step 3: Summarize Progress (Iteration {i+1}) ---")
        print("Summarizing current progress...")
        SummarizeTool().run()

        print(f"\n--- Step 4: Update Status (Iteration {i+1}) ---")
        update_log_files(i+1,verbose=True)
        if check_success_status():
            break
 

