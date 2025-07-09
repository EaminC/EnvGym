import os
from pathlib import Path
from typing import Optional, Dict, Any, List
from datetime import datetime


def read_file_safe(file_path: Path) -> str:
    """
    Safely read file content
    
    Args:
        file_path: File path
        
    Returns:
        File content, returns empty string if file doesn't exist or is empty
    """
    try:
        if file_path.exists() and file_path.is_file():
            content = file_path.read_text(encoding='utf-8').strip()
            return content if content else ""
        return ""
    except Exception as e:
        print(f"Warning: Unable to read file {file_path}: {e}")
        return ""


def append_to_file_safe(file_path: Path, content: str) -> bool:
    """
    Safely append content to file
    
    Args:
        file_path: File path
        content: Content to append
        
    Returns:
        Whether append was successful
    """
    try:
        # Ensure parent directory exists
        file_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Append content
        with open(file_path, 'a', encoding='utf-8') as f:
            f.write(content + '\n')
        return True
    except Exception as e:
        print(f"Error: Unable to write to file {file_path}: {e}")
        return False


def update_log_files(
    iteration_number: int,
    envgym_path: Optional[str] = None,
    verbose: bool = False
) -> Dict[str, Any]:
    """
    Update log files: Save current iteration execution status to history.txt
    
    Args:
        iteration_number: Iteration number
        envgym_path: envgym directory path, defaults to envgym under current directory
        verbose: Whether to show detailed information
        
    Returns:
        Dictionary containing operation results
    """
    try:
        # Determine envgym directory path
        if envgym_path is None:
            envgym_path = os.path.join(os.getcwd(), "envgym")
        
        envgym_dir = Path(envgym_path)
        
        # Check if envgym directory exists
        if not envgym_dir.exists():
            return {
                "success": False,
                "message": f"envgym directory does not exist: {envgym_dir}",
                "iteration": iteration_number,
                "files_processed": []
            }
        
        # Define file paths
        files_to_read = {
            "plan.txt": "PLAN",
            "next.txt": "NEXT", 
            "status.txt": "STATUS",
            "log_complete.txt": "LOG",
            "envgym.dockerfile": "DOCKERFILE"
        }
        
        history_file = envgym_dir / "history.txt"
        
        # Get current timestamp
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # Start writing history record
        processed_files = []
        
        # Write iteration start marker
        start_marker = f"=== Iteration {iteration_number} - [{timestamp}] ==="
        if not append_to_file_safe(history_file, start_marker):
            return {
                "success": False,
                "message": "Unable to write to history file",
                "iteration": iteration_number,
                "files_processed": []
            }
        
        if verbose:
            print(f"Starting to process iteration {iteration_number}")
        
        # Read and append content from each file
        for filename, prefix in files_to_read.items():
            file_path = envgym_dir / filename
            content = read_file_safe(file_path)
            
            if content:  # Only process non-empty files
                # Display line by line: write title first, then content
                if append_to_file_safe(history_file, f"{prefix}:"):
                    # Split content by lines and indent
                    for line in content.split('\n'):
                        if line.strip():  # Skip empty lines
                            append_to_file_safe(history_file, f"  {line}")
                    
                    processed_files.append(filename)
                    if verbose:
                        print(f"Processed {filename}")
                else:
                    if verbose:
                        print(f"Unable to write content of {filename}")
            else:
                if verbose:
                    print(f"Skipping empty file {filename}")
        
        # Write iteration end marker
        end_marker = f"--- End of Iteration {iteration_number} ---"
        append_to_file_safe(history_file, end_marker)
        
        # Add empty line separator
        append_to_file_safe(history_file, "")
        
        if verbose:
            print(f"Iteration {iteration_number} processing completed")
        
        return {
            "success": True,
            "message": f"Successfully updated log files for iteration {iteration_number}",
            "iteration": iteration_number,
            "files_processed": processed_files,
            "history_file": str(history_file),
            "timestamp": timestamp
        }
        
    except Exception as e:
        return {
            "success": False,
            "message": f"Error updating log files: {str(e)}",
            "iteration": iteration_number,
            "files_processed": [],
            "error": str(e)
        }


def analyze_log_files(
    envgym_path: Optional[str] = None,
    verbose: bool = False
) -> Dict[str, Any]:
    """
    Analyze log files: Read current Docker execution results and analyze
    
    Args:
        envgym_path: envgym directory path, defaults to envgym under current directory
        verbose: Whether to show detailed information
        
    Returns:
        Dictionary containing analysis results
    """
    try:
        # Determine envgym directory path
        if envgym_path is None:
            envgym_path = os.path.join(os.getcwd(), "envgym")
        
        envgym_dir = Path(envgym_path)
        
        # Check if envgym directory exists
        if not envgym_dir.exists():
            return {
                "success": False,
                "message": f"envgym directory does not exist: {envgym_dir}",
                "analysis": {}
            }
        
        log_file = envgym_dir / "log.txt"
        status_file = envgym_dir / "status.txt"
        next_file = envgym_dir / "next.txt"
        
        # Read log file
        log_content = read_file_safe(log_file)
        
        if not log_content:
            return {
                "success": False,
                "message": "log.txt file is empty or does not exist",
                "analysis": {}
            }
        
        if verbose:
            print("Starting log file analysis...")
        
        # Analyze log content
        analysis = {
            "total_lines": len(log_content.split('\n')),
            "has_errors": False,
            "has_warnings": False,
            "success_indicators": [],
            "error_indicators": [],
            "warning_indicators": []
        }
        
        # Check common success/failure indicators
        success_patterns = [
            "Successfully built",
            "Successfully tagged",
            "BUILD SUCCESSFUL",
            "build successful",
            "Tests passed",
            "All tests passed"
        ]
        
        error_patterns = [
            "ERROR",
            "Error",
            "error:",
            "FAILED",
            "Failed",
            "Exception",
            "BUILD FAILED",
            "build failed"
        ]
        
        warning_patterns = [
            "WARNING",
            "Warning",
            "warning:",
            "WARN",
            "deprecated"
        ]
        
        lines = log_content.split('\n')
        
        for line in lines:
            line_lower = line.lower()
            
            # Check success indicators
            for pattern in success_patterns:
                if pattern.lower() in line_lower:
                    analysis["success_indicators"].append(line.strip())
                    break
            
            # Check error indicators
            for pattern in error_patterns:
                if pattern.lower() in line_lower:
                    analysis["has_errors"] = True
                    analysis["error_indicators"].append(line.strip())
                    break
            
            # Check warning indicators
            for pattern in warning_patterns:
                if pattern.lower() in line_lower:
                    analysis["has_warnings"] = True
                    analysis["warning_indicators"].append(line.strip())
                    break
        
        # Generate analysis summary
        if analysis["success_indicators"] and not analysis["has_errors"]:
            overall_status = "SUCCESS"
        elif analysis["has_errors"]:
            overall_status = "FAILED"
        elif analysis["has_warnings"]:
            overall_status = "WARNING"
        else:
            overall_status = "UNKNOWN"
        
        analysis["overall_status"] = overall_status
        
        # Generate suggested next steps
        if overall_status == "SUCCESS":
            next_steps = "Environment build successful. You can proceed to the next step."
        elif overall_status == "FAILED":
            next_steps = "Environment build failed. Need to check error logs and fix Dockerfile."
        elif overall_status == "WARNING":
            next_steps = "Environment build has warnings. Recommend checking warning messages and consider optimization."
        else:
            next_steps = "Unable to determine build status. Manual log file inspection needed."
        
        analysis["suggested_next_steps"] = next_steps
        
        # Update status file
        status_content = f"Analysis result: {overall_status}\n"
        status_content += f"Success indicators: {len(analysis['success_indicators'])}\n"
        status_content += f"Error indicators: {len(analysis['error_indicators'])}\n"
        status_content += f"Warning indicators: {len(analysis['warning_indicators'])}\n"
        status_content += f"Total lines: {analysis['total_lines']}\n"
        
        status_file.write_text(status_content, encoding='utf-8')
        
        # Update next steps file
        next_file.write_text(next_steps, encoding='utf-8')
        
        if verbose:
            print(f"Log analysis completed, overall status: {overall_status}")
            print(f"Suggested next step: {next_steps}")
        
        return {
            "success": True,
            "message": "Log file analysis completed",
            "analysis": analysis,
            "files_updated": [str(status_file), str(next_file)]
        }
        
    except Exception as e:
        return {
            "success": False,
            "message": f"Error analyzing log files: {str(e)}",
            "analysis": {},
            "error": str(e)
        }


def batch_update_logs(
    start_iteration: int,
    end_iteration: int,
    envgym_path: Optional[str] = None,
    verbose: bool = False
) -> Dict[str, Any]:
    """
    Batch update log files for multiple iterations
    
    Args:
        start_iteration: Starting iteration number
        end_iteration: Ending iteration number
        envgym_path: envgym directory path
        verbose: Whether to show detailed information
        
    Returns:
        Dictionary containing batch operation results
    """
    results = []
    
    for iteration in range(start_iteration, end_iteration + 1):
        if verbose:
            print(f"Processing iteration {iteration}...")
        
        result = update_log_files(
            iteration_number=iteration,
            envgym_path=envgym_path,
            verbose=verbose
        )
        
        results.append(result)
        
        # If an iteration fails, ask whether to continue
        if not result["success"] and verbose:
            print(f"Iteration {iteration} processing failed: {result['message']}")
    
    successful_count = sum(1 for r in results if r["success"])
    
    return {
        "success": successful_count > 0,
        "message": f"Batch processing completed: {successful_count}/{len(results)} successful",
        "total_iterations": len(results),
        "successful_iterations": successful_count,
        "results": results
    }


def get_log_summary(
    envgym_path: Optional[str] = None,
    last_n_iterations: int = 3
) -> Dict[str, Any]:
    """
    Get log summary: Read summary of the last few iterations
    
    Args:
        envgym_path: envgym directory path
        last_n_iterations: Show last n iterations
        
    Returns:
        Dictionary containing log summary
    """
    try:
        # Determine envgym directory path
        if envgym_path is None:
            envgym_path = os.path.join(os.getcwd(), "envgym")
        
        envgym_dir = Path(envgym_path)
        history_file = envgym_dir / "history.txt"
        
        if not history_file.exists():
            return {
                "success": False,
                "message": "history.txt file does not exist",
                "summary": {}
            }
        
        history_content = read_file_safe(history_file)
        
        if not history_content:
            return {
                "success": False,
                "message": "history.txt file is empty",
                "summary": {}
            }
        
        # Analyze history records
        lines = history_content.split('\n')
        iterations = []
        current_iteration = None
        
        for line in lines:
            if line.startswith("=== Iteration"):
                # Extract iteration information
                parts = line.split()
                if len(parts) >= 3:
                    iteration_num = parts[2]
                    timestamp = line.split('[')[1].split(']')[0] if '[' in line else "Unknown time"
                    current_iteration = {
                        "iteration": iteration_num,
                        "timestamp": timestamp,
                        "content": []
                    }
            elif line.startswith("--- End of Iteration"):
                if current_iteration:
                    iterations.append(current_iteration)
                    current_iteration = None
            elif current_iteration and line.strip():
                current_iteration["content"].append(line.strip())
        
        # Get the last n iterations
        recent_iterations = iterations[-last_n_iterations:] if iterations else []
        
        summary = {
            "total_iterations": len(iterations),
            "recent_iterations": recent_iterations,
            "last_n_shown": len(recent_iterations)
        }
        
        return {
            "success": True,
            "message": f"Successfully retrieved log summary, showing last {len(recent_iterations)} iterations",
            "summary": summary
        }
        
    except Exception as e:
        return {
            "success": False,
            "message": f"Error retrieving log summary: {str(e)}",
            "summary": {},
            "error": str(e)
        }


if __name__ == "__main__":
    # Test functionality
    print("Testing log update functionality...")
    
    # Test updating log files
    result = update_log_files(iteration_number=1, verbose=True)
    print(f"Update result: {result}")
    
    # Test analyzing log files
    analysis_result = analyze_log_files(verbose=True)
    print(f"Analysis result: {analysis_result}")
    
    # Test getting log summary
    summary_result = get_log_summary()
    print(f"Summary result: {summary_result}") 