"""Rust dependency tree analysis functionality."""

import requests
import json

def get_crate_dependencies(crate_name: str, version: str = None, verbose=False) -> list:
    """Get crate dependencies from crates.io without installing."""
    if verbose:
        print(f"🔍 Getting dependencies for {crate_name}...")
    
    try:
        # Get crate info from crates.io
        if version:
            url = f"https://crates.io/api/v1/crates/{crate_name}/{version}/dependencies"
        else:
            url = f"https://crates.io/api/v1/crates/{crate_name}/dependencies"
        
        response = requests.get(url, timeout=10)
        if response.status_code != 200:
            return []
        
        data = response.json()
        dependencies = data.get("dependencies", [])
        
        requirements = []
        for dep in dependencies:
            # Only include normal dependencies (not dev or build dependencies)
            if dep.get("kind") == "normal":
                crate_name = dep.get("crate_id", "")
                version_req = dep.get("req", "")
                requirements.append(f"{crate_name} {version_req}")
                
        return requirements
            
    except Exception as e:
        return []

def build_dependency_tree_brackets(crate_name: str, version: str = None, visited=None, depth=0, max_depth=2) -> str:
    """Recursively build dependency tree for Rust crates using bracket notation."""
    if visited is None:
        visited = set()
    
    # Prevent infinite recursion
    crate_key = f"{crate_name}=={version}" if version else crate_name
    if crate_key in visited or depth > max_depth:
        return ""
    
    visited.add(crate_key)
    
    # Get direct dependencies
    dependencies_list = get_crate_dependencies(crate_name, version)
    
    if not dependencies_list:
        return ""
    
    deps_with_subs = []
    for dep in dependencies_list:
        # Parse dependency to get crate name
        dep_name = dep.split()[0]
        
        # Recursively get sub-dependencies
        if depth < max_depth:
            sub_tree = build_dependency_tree_brackets(dep_name, None, visited.copy(), depth + 1, max_depth)
            if sub_tree:
                deps_with_subs.append(f"{dep} ({sub_tree})")
            else:
                deps_with_subs.append(dep)
        else:
            deps_with_subs.append(dep)
    
    return ", ".join(deps_with_subs)

def get_dependency_tree(crate: str, verbose=False) -> str:
    """Get Rust crate dependency tree using bracket notation."""
    if verbose:
        print(f"🔍 Building dependency tree for {crate}...")
    
    # Parse crate name and version
    if "==" in crate:
        crate_name, version = crate.split("==", 1)
    else:
        crate_name, version = crate, None
    
    # Build the tree structure using brackets
    tree_content = build_dependency_tree_brackets(crate_name, version)
    
    if tree_content:
        return f"{crate} ({tree_content})"
    else:
        return f"{crate} (no dependencies)" 