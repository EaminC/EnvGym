"""Dependency tree analysis functionality."""

import requests

def get_package_requirements(package_name: str, version: str = None, verbose=False) -> list:
    """Get package requirements from PyPI without installing."""
    if verbose:
        print(f"🔍 Getting requirements for {package_name}...")
    
    try:
        # Get package info from PyPI
        if version:
            url = f"https://pypi.org/pypi/{package_name}/{version}/json"
        else:
            url = f"https://pypi.org/pypi/{package_name}/json"
        
        response = requests.get(url, timeout=10)
        if response.status_code != 200:
            return []
        
        data = response.json()
        
        # Get requirements from package info
        if version and version in data.get("releases", {}):
            # Get specific version info
            releases = data["releases"][version]
            if releases:
                # Try to get requirements from wheel or source distribution
                for release in releases:
                    if release.get("requires_dist"):
                        requirements = []
                        for req in release["requires_dist"]:
                            # Filter out extra requirements and environment markers
                            if "extra ==" not in req and ";" not in req:
                                clean_req = req.strip()
                                if clean_req.endswith(','):
                                    clean_req = clean_req[:-1].strip()
                                requirements.append(clean_req)
                        return requirements
        
        # Fallback: get from general package info
        info = data.get("info", {})
        requires_dist = info.get("requires_dist", [])
        
        if requires_dist:
            requirements = []
            for req in requires_dist:
                # Filter out extra requirements and environment markers
                if "extra ==" not in req and ";" not in req:
                    clean_req = req.strip()
                    if clean_req.endswith(','):
                        clean_req = clean_req[:-1].strip()
                    if ';' in clean_req:
                        clean_req = clean_req.split(';')[0].strip()
                    requirements.append(clean_req)
            return requirements
        else:
            return []
            
    except Exception as e:
        return []

def build_dependency_tree_brackets(package_name: str, version: str = None, visited=None, depth=0, max_depth=2) -> str:
    """Recursively build dependency tree using bracket notation."""
    if visited is None:
        visited = set()
    
    # Prevent infinite recursion
    package_key = f"{package_name}=={version}" if version else package_name
    if package_key in visited or depth > max_depth:
        return ""
    
    visited.add(package_key)
    
    # Get direct requirements
    requirements = get_package_requirements(package_name, version)
    
    if not requirements:
        return ""
    
    deps_with_subs = []
    for req in requirements:
        # Parse requirement to get package name
        req_name = req.split()[0].split('=')[0].split('>')[0].split('<')[0].split('!')[0].split('~')[0]
        
        # Recursively get sub-dependencies
        if depth < max_depth:
            sub_tree = build_dependency_tree_brackets(req_name, None, visited.copy(), depth + 1, max_depth)
            if sub_tree:
                deps_with_subs.append(f"{req} ({sub_tree})")
            else:
                deps_with_subs.append(req)
        else:
            deps_with_subs.append(req)
    
    return ", ".join(deps_with_subs)

def get_dependency_tree(package: str, verbose=False) -> str:
    """Get package dependency tree using bracket notation."""
    if verbose:
        print(f"🔍 Building dependency tree for {package}...")
    
    # Parse package name and version
    if "==" in package:
        package_name, version = package.split("==", 1)
    else:
        package_name, version = package, None
    
    # Build the tree structure using brackets
    tree_content = build_dependency_tree_brackets(package_name, version)
    
    if tree_content:
        return f"{package} ({tree_content})"
    else:
        return f"{package} (no dependencies)" 