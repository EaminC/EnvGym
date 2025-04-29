import subprocess
import os
from datetime import datetime
import threading
import sys
import json

# List of interesting repos as local directory paths (edit as needed)
interesting_repos = [
    "../../data/Metis"
]

# Instruction prompt for Codex CLI
CODEX_INSTRUCTION = "Follow the README carefully in the repo and set up all the dependency requirements to run the code. Verify that you have successfully set up the environment by running the code. You have sudo privileges. Remember you can set the timeout of your own commands, so make it longer for long-running commands."

# Create output directory if it doesn't exist
os.makedirs("output", exist_ok=True)

# Log file paths will be set per repo with timestamp
def get_log_paths(repo_name):
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    base_filename = f"{repo_name}_{timestamp}"
    return (
        f"output/{base_filename}_log.txt",
        f"output/{base_filename}_concise_log.txt"
    )

# Log truncation length
LOG_TRUNCATE_LENGTH = 250

def log_output(pipe, logfile, concise_logfile, prefix):
    """Log output from a pipe in real-time, parsing each line as JSON"""
    with open(logfile, 'a', encoding='utf-8') as log, open(concise_logfile, 'a', encoding='utf-8') as concise_log:
        for line in iter(pipe.readline, ''):
            try:
                # Maintain a set of seen message IDs to avoid duplicates in concise log
                if not hasattr(log_output, 'seen_ids'):
                    log_output.seen_ids = set()
                
                # Try to parse as JSON for prettier logging
                parsed_json = json.loads(line.strip())
                
                # Save prettified JSON to detailed log (always)
                pretty_json = json.dumps(parsed_json, indent=4)
                log.write(f"{prefix}: {pretty_json}\n")
                log.flush()
                
                # Check for duplicate based on id field
                is_duplicate = False
                if "id" in parsed_json:
                    message_id = parsed_json["id"]
                    if message_id in log_output.seen_ids:
                        is_duplicate = True
                    else:
                        log_output.seen_ids.add(message_id)
                
                # Skip duplicate entries in concise log
                if is_duplicate:
                    continue
                    
                # Create concise log entry
                if "type" in parsed_json:
                    # Extract the most relevant content based on type
                    if parsed_json["type"] == "function_call" and "name" in parsed_json and "arguments" in parsed_json:
                        try:
                            args = json.loads(parsed_json["arguments"])
                            if "command" in args:
                                concise_log.write(f"{prefix} ({parsed_json['name']}) $ {' '.join(args['command'])}\n")
                            else:
                                concise_log.write(f"{prefix} ({parsed_json['name']}) $ {parsed_json['arguments']}\n")
                        except:
                            concise_log.write(f"{prefix} ({parsed_json['name']}) $ {parsed_json['arguments']}\n")
                    elif parsed_json["type"] == "function_call_output" and "output" in parsed_json:
                        try:
                            output_data = json.loads(parsed_json["output"])
                            if "output" in output_data:
                                # Truncate long outputs
                                output_text = output_data["output"]
                                if len(output_text) > LOG_TRUNCATE_LENGTH:
                                    output_text = output_text[:LOG_TRUNCATE_LENGTH-3] + "..."
                                concise_log.write(f"{prefix} OUTPUT: {output_text}\n")
                            else:
                                concise_log.write(f"{prefix} OUTPUT: {str(output_data)[:LOG_TRUNCATE_LENGTH]}\n")
                        except:
                            concise_log.write(f"{prefix} output: {str(parsed_json['output'])[:LOG_TRUNCATE_LENGTH]}\n")
                    elif parsed_json["type"] == "message" and "content" in parsed_json:
                        # Handle message type with content field
                        for content_item in parsed_json["content"]:
                            if content_item["type"] == "output_text" and "text" in content_item:
                                # Truncate long message text
                                message_text = content_item["text"]
                                if len(message_text) > LOG_TRUNCATE_LENGTH:
                                    message_text = message_text[:LOG_TRUNCATE_LENGTH-3] + "..."
                                concise_log.write(f"{prefix} MESSAGE: {message_text}\n")
                    else:
                        concise_log.write(f"{prefix} {parsed_json['type']}: {str(parsed_json)[:LOG_TRUNCATE_LENGTH]}\n")
                else:
                    # Fallback for JSON without type field
                    concise_log.write(f"{prefix} event: {str(parsed_json)[:LOG_TRUNCATE_LENGTH]}\n")
                
                concise_log.flush()
                print(f"{prefix}: {line}", end='')
            except json.JSONDecodeError:
                # If not valid JSON, log as is
                log.write(f"{prefix}: {line}")
                log.flush()
                concise_log.write(f"{prefix} text: {line[:LOG_TRUNCATE_LENGTH]}\n")
                concise_log.flush()
                print(f"{prefix}: {line}", end='')
            sys.stdout.flush()

def run_codex_in_repo(repo_path):
    result = {
        "repo": repo_path,
        "start_time": datetime.utcnow().isoformat(),
        "returncode": None,
        "exception": None,
    }
    abspath = os.path.abspath(repo_path)
    
    # Get repo name from path
    repo_name = os.path.basename(repo_path)
    log_file, concise_log_file = get_log_paths(repo_name)

    # Log the start of the run
    with open(log_file, 'a', encoding='utf-8') as f, open(concise_log_file, 'a', encoding='utf-8') as cf:
        f.write("="*80 + "\n")
        start_info = {
            "repo": result['repo'],
            "start_time": result['start_time']
        }
        f.write(json.dumps(start_info, indent=4) + "\n")
        cf.write("="*80 + "\n")
        cf.write(f"Starting run for {result['repo']} at {result['start_time']}\n")
    
    # Call codex CLI in the repo directory
    try:
        proc = subprocess.Popen(
            [
                "codex",
                "--approval-mode", "full-auto",
                "--quiet",
                CODEX_INSTRUCTION,
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=abspath,
            text=True,
            bufsize=1  # Line buffered
        )
        
        # Start threads to log stdout and stderr in real-time
        stdout_thread = threading.Thread(
            target=log_output, 
            args=(proc.stdout, log_file, concise_log_file, f"[{repo_path}][STDOUT]")
        )
        stderr_thread = threading.Thread(
            target=log_output, 
            args=(proc.stderr, log_file, concise_log_file, f"[{repo_path}][STDERR]")
        )
        
        stdout_thread.daemon = True
        stderr_thread.daemon = True
        stdout_thread.start()
        stderr_thread.start()
        
        # Wait for the process to complete (with timeout)
        result["returncode"] = proc.wait(timeout=1800)  # 30 min
        
        # Wait for logging threads to finish
        stdout_thread.join()
        stderr_thread.join()
        
    except Exception as e:
        result["exception"] = str(e)
        # Log the exception
        with open(log_file, 'a', encoding='utf-8') as f, open(concise_log_file, 'a', encoding='utf-8') as cf:
            exception_info = {"exception": result['exception']}
            f.write(json.dumps(exception_info, indent=4) + "\n")
            cf.write(f"Exception: {result['exception']}\n")
    
    # Log completion
    with open(log_file, 'a', encoding='utf-8') as f, open(concise_log_file, 'a', encoding='utf-8') as cf:
        completion_info = {"completed_with_return_code": result['returncode']}
        f.write(json.dumps(completion_info, indent=4) + "\n")
        f.write("="*80 + "\n\n")
        cf.write(f"Completed with return code: {result['returncode']}\n")
        cf.write("="*80 + "\n\n")
        
    return result

def main():
    for repo in interesting_repos:
        print(f"Running Codex CLI in repo: {repo} ...")
        result = run_codex_in_repo(repo)
        
        # Output parsable JSON for the result
        result_json = {
            "repo": repo,
            "status": "success" if result["returncode"] == 0 else "fail",
            "return_code": result["returncode"],
            "exception": result["exception"]
        }
        print(json.dumps(result_json))

if __name__ == "__main__":
    main()