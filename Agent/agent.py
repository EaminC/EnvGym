import os
import sys
from pathlib import Path
import json
import time
from datetime import datetime

from utils import check_success_status, print_execution_summary

from tool.scanning.entry import ScanningTool
from tool.test_scanning.entry import TestScanningTool
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



  

if __name__ == "__main__":
    

    start_time = time.time()
    print("Starting envgym execution...")

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
    

    end_time = time.time()
    print_execution_summary(start_time, end_time)
 

