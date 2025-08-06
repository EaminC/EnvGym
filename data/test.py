import pandas as pd
from tabulate import tabulate
from colorama import Fore, Back, Style, init
import os
import json
from datetime import datetime
from pathlib import Path

# Initialize colorama
init(autoreset=True)

def print_header():
    """Print beautiful header"""
    print(f"{Fore.CYAN}{'='*70}")
    print(f"{Fore.CYAN}{'='*15} Environment Test Results Analysis {'='*15}")
    print(f"{Fore.CYAN}{'='*70}")
    print(f"{Fore.LIGHTBLACK_EX}Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

def print_loading_animation():
    """Print loading animation"""
    print(f"{Fore.YELLOW}Loading data...", end="", flush=True)
    for i in range(3):
        print(".", end="", flush=True)
        import time
        time.sleep(0.2)
    print(f"{Fore.GREEN} ✓")

def get_accuracy_color(acc):
    """Return color based on accuracy"""
    if pd.isna(acc):
        return Fore.LIGHTBLACK_EX, Back.LIGHTBLACK_EX
    elif acc >= 0.9:
        return Fore.GREEN, Back.GREEN
    elif acc >= 0.8:
        return Fore.LIGHTGREEN_EX, Back.LIGHTGREEN_EX
    elif acc >= 0.6:
        return Fore.YELLOW, Back.YELLOW
    elif acc >= 0.4:
        return Fore.LIGHTRED_EX, Back.LIGHTRED_EX
    else:
        return Fore.RED, Back.RED

def format_accuracy(acc):
    """Format accuracy display"""
    if pd.isna(acc):
        return f"{Fore.RED}✗ 00.0%"
    elif acc >= 0.9:
        return f"{Fore.GREEN}★ {acc:.1%}"
    elif acc >= 0.8:
        return f"{Fore.LIGHTGREEN_EX}✓ {acc:.1%}"
    elif acc >= 0.6:
        return f"{Fore.YELLOW}○ {acc:.1%}"
    elif acc >= 0.4:
        return f"{Fore.LIGHTRED_EX}⚠ {acc:.1%}"
    else:
        return f"{Fore.RED}✗ {acc:.1%}"

def print_summary_stats(df_sorted, excluded):
    """Print summary statistics"""
    print(f"{Fore.CYAN}{'─'*50}")
    print(f"{Fore.CYAN}📊 Summary Statistics")
    print(f"{Fore.CYAN}{'─'*50}")
    
    # Overall average: include all repos, skipped repos count as 0% accuracy
    overall_avg = df_sorted['Accuracy'].fillna(0).mean()
    
    # Filtered average: exclude skipped repos (those with 0 tests)
    tested_repos = df_sorted[df_sorted['TestStatus'] == 'Tested']
    filtered_avg = tested_repos['Accuracy'].mean()
    
    total_repos = len(df_sorted)
    tested_count = len(tested_repos)
    skipped_count = len(df_sorted[df_sorted['TestStatus'] == 'Skipped'])
    
    print(f"{Fore.WHITE}Total Repositories: {Fore.LIGHTBLUE_EX}{total_repos:>3}")
    print(f"{Fore.WHITE}Tested:            {Fore.LIGHTBLUE_EX}{tested_count:>3}")
    print(f"{Fore.WHITE}Skipped:           {Fore.LIGHTBLUE_EX}{skipped_count:>3}")
    
    def print_progress_bar(label, value, color):
        bar_length = 25
        filled_length = int(bar_length * value) if not pd.isna(value) else 0
        bar = '█' * filled_length + '░' * (bar_length - filled_length)
        percentage = f"{value:.1%}" if not pd.isna(value) else "N/A"
        print(f"{Fore.WHITE}{label:<18} {color}{bar} {percentage}")
    
    print_progress_bar("Overall Average:", overall_avg, Fore.CYAN)
    print_progress_bar("Filtered Average:", filtered_avg, Fore.MAGENTA)

def load_data_from_json_files():
    """Load data from individual JSON files in each repo"""
    data = []
    data_dir = Path(".")
    
    # Find all directories that contain envgym folder
    for repo_dir in data_dir.iterdir():
        if repo_dir.is_dir() and not repo_dir.name.startswith('.'):
            envgym_dir = repo_dir / "envgym"
            if envgym_dir.exists():
                envbench_json = envgym_dir / "envbench.json"
                stat_json = envgym_dir / "stat.json"
                
                if envbench_json.exists():
                    try:
                        # Read envbench.json
                        with open(envbench_json, 'r') as f:
                            envbench_data = json.load(f)
                        
                        # Read stat.json if exists
                        stat_data = None
                        if stat_json.exists():
                            with open(stat_json, 'r') as f:
                                stat_data = json.load(f)
                        
                        # Calculate accuracy
                        pass_count = envbench_data.get('PASS', 0)
                        fail_count = envbench_data.get('FAIL', 0)
                        warn_count = envbench_data.get('WARN', 0)
                        total_tests = pass_count + fail_count + warn_count
                        
                        if total_tests > 0:
                            accuracy = pass_count / total_tests
                        else:
                            accuracy = None
                        
                        # Determine test status
                        if total_tests == 0:
                            test_status = "Skipped"
                        else:
                            test_status = "Tested"
                        
                        # Extract data from stat.json
                        requests = 0
                        input_tokens = 0
                        output_tokens = 0
                        total_tokens = 0
                        duration = "00:00:00"
                        cost = "$0.00"
                        model = "gpt-4.1"
                        
                        if stat_data and 'usage_delta' in stat_data:
                            delta = stat_data['usage_delta']
                            requests = delta.get('requests_count', 0)
                            input_tokens = delta.get('input_tokens', 0)
                            output_tokens = delta.get('output_tokens', 0)
                            total_tokens = delta.get('total_tokens', 0)
                            
                            # Calculate cost based on GPT-4.1 pricing
                            # Input: $2.00 per 1M tokens, Output: $8.00 per 1M tokens
                            input_cost = (input_tokens / 1_000_000) * 2.00
                            output_cost = (output_tokens / 1_000_000) * 8.00
                            total_cost = input_cost + output_cost
                            cost = f"${total_cost:.2f}"
                        
                        if stat_data and 'api_info' in stat_data:
                            model = stat_data['api_info'].get('model', 'gpt-4.1')
                        
                        # Calculate duration from session times if available
                        if stat_data and 'session_start' in stat_data and 'session_end' in stat_data:
                            try:
                                from datetime import datetime
                                start_time = datetime.fromisoformat(stat_data['session_start'].replace('Z', '+00:00'))
                                end_time = datetime.fromisoformat(stat_data['session_end'].replace('Z', '+00:00'))
                                duration_delta = end_time - start_time
                                total_seconds = int(duration_delta.total_seconds())
                                hours = total_seconds // 3600
                                minutes = (total_seconds % 3600) // 60
                                seconds = total_seconds % 60
                                duration = f"{hours:02d}:{minutes:02d}:{seconds:02d}"
                            except:
                                duration = "00:00:00"
                        
                        # Create row data
                        row = {
                            'Index': len(data) + 1,
                            'Repository': repo_dir.name,
                            'Pass': pass_count,
                            'Fail': fail_count,
                            'Error': warn_count,
                            'Accuracy': accuracy,
                            'TestStatus': test_status,
                            'Model': model,
                            'Requests': requests,
                            'InputTokens': input_tokens,
                            'OutputTokens': output_tokens,
                            'TotalTokens': total_tokens,
                            'Duration': duration,
                            'Cost': cost
                        }
                        
                        data.append(row)
                        
                    except Exception as e:
                        print(f"{Fore.RED}Error reading {repo_dir.name}: {e}")
                        continue
    
    return pd.DataFrame(data)

def main():
    # Print header
    print_header()
    print()
    
    # Print loading animation
    print_loading_animation()
    print()
    
    # Load data from JSON files
    try:
        df = load_data_from_json_files()
        if df.empty:
            print(f"{Fore.RED}✗ Error: No data found in JSON files")
            return
            
        print(f"{Fore.GREEN}✓ Loaded {len(df)} records from JSON files")
    except Exception as e:
        print(f"{Fore.RED}✗ Error: {e}")
        return
    
    # Excluded repositories
    excluded = {
        "SymMC", "vuejs_core", "CrossPrefetch",
        "ponylang_ponyc", "mui_material-ui", "rfuse"
    }
    
    # Sort by accuracy descending
    df_sorted = df.sort_values(by='Accuracy', ascending=False, na_position='last')
    
    # Apply color to rows
    colored_rows = []
    for idx, row in df_sorted.iterrows():
        values = row.tolist()
        acc = row['Accuracy']
        color, bg_color = get_accuracy_color(acc)
        
        # Format values
        formatted_values = []
        for i, v in enumerate(values):
            if i == 1:  # Repository column (index 1)
                formatted_values.append(f"{Fore.LIGHTBLUE_EX}{v}")
            elif i == 5:  # Accuracy column (index 5)
                formatted_values.append(format_accuracy(acc))
            elif i == 6:  # TestStatus column
                if v == "Tested":
                    formatted_values.append(f"{Fore.GREEN}{v}")
                elif v == "Skipped":
                    formatted_values.append(f"{Fore.YELLOW}{v}")
                else:
                    formatted_values.append(f"{Fore.WHITE}{v}")
            elif i == 7:  # Model column
                formatted_values.append(f"{Fore.CYAN}{v}")
            elif i == 13:  # Cost column
                formatted_values.append(f"{Fore.MAGENTA}{v}")
            else:
                formatted_values.append(f"{Fore.WHITE}{v}")
        
        colored_rows.append(formatted_values)
    
    # Build colored table
    print(f"{Fore.CYAN}{'─'*50}")
    print(f"{Fore.CYAN}📋 Detailed Results")
    print(f"{Fore.CYAN}{'─'*50}")
    
    # Create headers function to ensure consistency
    def create_headers():
        headers = []
        for col in df.columns.tolist():
            if col == "Error":
                headers.append(f"{Fore.CYAN}Warn")
            else:
                headers.append(f"{Fore.CYAN}{col}")
        return headers
    
    # Use consistent headers for both tables
    headers = create_headers()
    print(tabulate(colored_rows, headers=headers, tablefmt="simple", stralign="right"))
    
    # Add totals row
    print(f"{Fore.CYAN}{'─'*50}")
    print(f"{Fore.CYAN}📊 Totals")
    print(f"{Fore.CYAN}{'─'*50}")
    
    # Calculate totals for numeric columns (excluding Accuracy)
    totals = []
    for i, col in enumerate(df.columns):
        if i == 0:  # Index column
            totals.append(f"{Fore.LIGHTBLUE_EX}Total")
        elif i == 1:  # Repository column
            totals.append(f"{Fore.LIGHTBLUE_EX}{len(df)} repos")
        elif i == 5:  # Accuracy column - calculate from totals
            try:
                total_pass = df['Pass'].sum()
                total_fail = df['Fail'].sum()
                total_error = df['Error'].sum()
                total_tests = total_pass + total_fail + total_error
                
                if total_tests > 0:
                    accuracy = total_pass / total_tests
                    if accuracy >= 0.9:
                        formatted_acc = f"{Fore.GREEN}★ {accuracy:.1%} ★"
                    elif accuracy >= 0.8:
                        formatted_acc = f"{Fore.LIGHTGREEN_EX}✓ {accuracy:.1%}"
                    elif accuracy >= 0.6:
                        formatted_acc = f"{Fore.YELLOW}⚠ {accuracy:.1%}"
                    elif accuracy >= 0.4:
                        formatted_acc = f"{Fore.LIGHTRED_EX}✗ {accuracy:.1%}"
                    else:
                        formatted_acc = f"{Fore.RED}✗ {accuracy:.1%}"
                else:
                    formatted_acc = f"{Fore.LIGHTBLACK_EX}N/A"
                
                totals.append(formatted_acc)
            except:
                totals.append(f"{Fore.LIGHTBLACK_EX}N/A")
        elif i == 6:  # TestStatus column
            tested_count = len(df[df['TestStatus'] == 'Tested'])
            skipped_count = len(df[df['TestStatus'] == 'Skipped'])
            totals.append(f"{Fore.WHITE}{tested_count} tested, {skipped_count} skipped")
        elif i == 7:  # Model column
            model_counts = df['Model'].value_counts()
            totals.append(f"{Fore.CYAN}{model_counts.index[0]}")
        elif i in [2, 3, 4, 8, 9, 10, 11]:  # Numeric columns: Pass, Fail, Error, Requests, InputTokens, OutputTokens, TotalTokens
            try:
                total_val = df[col].sum()
                if col in ['InputTokens', 'OutputTokens', 'TotalTokens']:
                    # Format large numbers with commas
                    formatted_val = f"{total_val:,}"
                else:
                    formatted_val = f"{total_val}"
                totals.append(f"{Fore.WHITE}{formatted_val}")
            except:
                totals.append(f"{Fore.WHITE}N/A")
        elif i == 12:  # Duration column
            try:
                # Parse duration strings and sum them
                total_minutes = 0
                total_seconds = 0
                for duration in df['Duration']:
                    if duration != 'OOT':  # Skip Out of Time entries
                        # Parse format like "00:44:59" or "02:05:31"
                        parts = duration.split(':')
                        if len(parts) == 3:
                            hours = int(parts[0])
                            minutes = int(parts[1])
                            seconds = int(parts[2])
                            total_minutes += hours * 60 + minutes
                            total_seconds += seconds
                
                # Convert to hours, minutes, seconds
                total_minutes += total_seconds // 60
                total_seconds = total_seconds % 60
                total_hours = total_minutes // 60
                total_minutes = total_minutes % 60
                
                formatted_duration = f"{total_hours:02d}:{total_minutes:02d}:{total_seconds:02d}"
                totals.append(f"{Fore.WHITE}{formatted_duration}")
            except:
                totals.append(f"{Fore.WHITE}N/A")
        elif i == 13:  # Cost column
            try:
                # Remove $ and convert to float for sum
                cost_series = df['Cost'].str.replace('$', '').astype(float)
                total_cost = cost_series.sum()
                totals.append(f"{Fore.MAGENTA}${total_cost:.2f}")
            except:
                totals.append(f"{Fore.MAGENTA}N/A")
        else:
            totals.append(f"{Fore.WHITE}N/A")
    
    # Use the same headers for totals table
    print(tabulate([totals], headers=headers, tablefmt="simple", stralign="right"))
    
    # Print summary statistics
    print_summary_stats(df_sorted, excluded)
    
    # Print footer
    print(f"{Fore.CYAN}{'='*70}")
    print(f"{Fore.LIGHTBLACK_EX}Report completed ✓")

if __name__ == "__main__":
    main()