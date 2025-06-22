"""Go dependency tree analysis functionality."""

import requests
import json
import time
import re
from typing import Optional, List, Set, Tuple

def get_module_dependencies(module_name: str, version: str = None, verbose=False, max_retries=3) -> List[str]:
    """Get Go module dependencies from Go Proxy without installing."""
    if verbose:
        print(f"🔍 Getting dependencies for {module_name}...")
    
    for attempt in range(max_retries):
        try:
            # Use Go Proxy API to get module info
            if version:
                url = f"https://proxy.golang.org/{module_name}/@v/{version}.mod"
            else:
                # Get latest version first
                latest_url = f"https://proxy.golang.org/{module_name}/@latest"
                latest_response = requests.get(latest_url, timeout=10)
                if latest_response.status_code != 200:
                    if verbose:
                        print(f"⚠️ Failed to get latest version for {module_name}: {latest_response.status_code}")
                    return []
                latest_data = latest_response.json()
                version = latest_data.get("Version", "")
                if not version:
                    if verbose:
                        print(f"⚠️ No version found for {module_name}")
                    return []
                url = f"https://proxy.golang.org/{module_name}/@v/{version}.mod"
            
            response = requests.get(url, timeout=10)
            if response.status_code != 200:
                if verbose:
                    print(f"⚠️ Failed to get mod file for {module_name}: {response.status_code}")
                return []
            
            mod_content = response.text
            dependencies = parse_go_mod(mod_content)
            return dependencies
                
        except requests.RequestException as e:
            if verbose:
                print(f"⚠️ Network error (attempt {attempt + 1}/{max_retries}): {e}")
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)  # Exponential backoff
            continue
        except Exception as e:
            if verbose:
                print(f"⚠️ Unexpected error: {e}")
            return []
    
    if verbose:
        print(f"❌ Failed to get dependencies for {module_name} after {max_retries} attempts")
    return []

def parse_go_mod(mod_content: str) -> List[str]:
    """Parse go.mod file content to extract dependencies."""
    dependencies = []
    lines = mod_content.split('\n')
    in_require_block = False
    
    for line in lines:
        line = line.strip()
        
        # Skip empty lines and comments
        if not line or line.startswith('//'):
            continue
        
        # Check for require block
        if line.startswith('require ('):
            in_require_block = True
            continue
        elif line == ')' and in_require_block:
            in_require_block = False
            continue
        
        # Parse require statements
        if in_require_block or line.startswith('require '):
            dep = parse_require_line(line, in_require_block)
            if dep:
                dependencies.append(dep)
                    
    return dependencies

def parse_require_line(line: str, in_require_block: bool) -> Optional[str]:
    """Parse a single require line and return dependency string."""
    if not in_require_block:
        # Single require statement
        if not line.startswith('require '):
            return None
        line = line.replace('require ', '').strip()
    
    # Remove inline comments
    if '//' in line:
        line = line.split('//')[0].strip()
    
    # Parse module name and version
    # Handle quoted module names
    if line.startswith('"'):
        # Find closing quote
        end_quote = line.find('"', 1)
        if end_quote == -1:
            return None
        mod_name = line[1:end_quote]
        remaining = line[end_quote + 1:].strip()
        parts = remaining.split()
    else:
        parts = line.split()
        if not parts:
            return None
        mod_name = parts[0]
        parts = parts[1:]
    
    if not parts:
        return None
    
    mod_version = parts[0]
    
    # Filter out replace directives and other non-standard versions
    if mod_version.startswith('v') or re.match(r'^\d+\.\d+\.\d+', mod_version):
        return f"{mod_name} {mod_version}"
    
    return None

def build_dependency_tree_json(module_name: str, version: str = None, visited: Set[str] = None, 
                         depth: int = 0, max_depth: int = 1) -> dict:
    """Recursively build dependency tree for Go modules as JSON."""
    if visited is None:
        visited = set()
    
    # Prevent infinite recursion
    module_key = f"{module_name}@{version}" if version else module_name
    if module_key in visited or depth > max_depth:
        return {"dependencies": []}
    
    # Add to visited set (shared across all recursive calls)
    visited.add(module_key)
    
    # Get direct dependencies
    dependencies_list = get_module_dependencies(module_name, version)
    
    dependencies = []
    for dep in dependencies_list:
        # Parse dependency to get module name and version
        dep_parts = dep.split()
        if len(dep_parts) < 2:
            continue
        dep_name = dep_parts[0]
        dep_version = dep_parts[1]
        
        dep_info = {
            "name": dep,
            "subdependencies": []
        }
        
        # Recursively get sub-dependencies (use same visited set)
        if depth < max_depth:
            sub_tree = build_dependency_tree_json(dep_name, dep_version, visited, depth + 1, max_depth)
            dep_info["subdependencies"] = sub_tree.get("dependencies", [])
        
        dependencies.append(dep_info)
    
    return {"dependencies": dependencies}

def build_dependency_tree_brackets(module_name: str, version: str = None, visited: Set[str] = None, 
                         depth: int = 0, max_depth: int = 1) -> str:
    """Recursively build dependency tree for Go modules using bracket notation."""
    if visited is None:
        visited = set()
    
    # Prevent infinite recursion
    module_key = f"{module_name}@{version}" if version else module_name
    if module_key in visited or depth > max_depth:
        return ""
    
    # Add to visited set (shared across all recursive calls)
    visited.add(module_key)
    
    # Get direct dependencies
    dependencies_list = get_module_dependencies(module_name, version)
    
    if not dependencies_list:
        return ""
    
    deps_with_subs = []
    for dep in dependencies_list:
        # Parse dependency to get module name and version
        dep_parts = dep.split()
        if len(dep_parts) < 2:
            continue
        dep_name = dep_parts[0]
        dep_version = dep_parts[1]
        
        # Recursively get sub-dependencies (use same visited set)
        if depth < max_depth:
            sub_tree = build_dependency_tree_brackets(dep_name, dep_version, visited, depth + 1, max_depth)
            if sub_tree:
                deps_with_subs.append(f"{dep} ({sub_tree})")
            else:
                deps_with_subs.append(dep)
        else:
            deps_with_subs.append(dep)
    
    return ", ".join(deps_with_subs)

def get_dependency_tree(module: str, verbose=False, max_depth: int = 1) -> str:
    """Get Go module dependency tree using bracket notation."""
    if verbose:
        print(f"🔍 Building dependency tree for {module}...")
    
    # Parse module name and version
    if "@" in module:
        module_name, version = module.split("@", 1)
    else:
        module_name, version = module, None
    
    # Build the tree structure using brackets
    tree_content = build_dependency_tree_brackets(module_name, version, max_depth=max_depth)
    
    if tree_content:
        return f"{module} ({tree_content})"
    else:
        return f"{module} (no dependencies)" 