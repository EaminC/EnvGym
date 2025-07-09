import os
import time


def check_success_status():
    """Check if the environment build is successful"""
    status_file_path = os.path.join(os.getcwd(), "envgym", "status.txt")
    
    if os.path.exists(status_file_path):
        with open(status_file_path, "r") as f:
            if "SUCCESS" in f.read():
                return True
    return False


def format_execution_time(start_time, end_time):
    """Format execution time into readable format"""
    total_time = end_time - start_time
    hours = int(total_time // 3600)
    minutes = int((total_time % 3600) // 60)
    seconds = int(total_time % 60)
    
    return hours, minutes, seconds, total_time


def print_execution_summary(start_time, end_time):
    """Print execution time summary"""
    hours, minutes, seconds, total_time = format_execution_time(start_time, end_time)
    
    print(f"\n=== Execution Completed ===")
    print(f"Total execution time: {hours:02d}:{minutes:02d}:{seconds:02d} ({total_time:.2f} seconds)")
