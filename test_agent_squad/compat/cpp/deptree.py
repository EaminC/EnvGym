"""C++ dependency tree analysis functionality."""

import requests
import json

def get_vcpkg_dependencies(package_name: str, version: str = None, verbose=False) -> list:
    """Get C++ package dependencies from vcpkg registry."""
    if verbose:
        print(f"🔍 Getting vcpkg dependencies for {package_name}...")
    
    try:
        # vcpkg uses GitHub registry
        url = f"https://api.github.com/repos/Microsoft/vcpkg/contents/ports/{package_name}/vcpkg.json"
        
        response = requests.get(url, timeout=10)
        if response.status_code != 200:
            return []
        
        # Decode base64 content
        import base64
        content_data = response.json()
        if "content" not in content_data:
            return []
        
        content = base64.b64decode(content_data["content"]).decode('utf-8')
        vcpkg_data = json.loads(content)
        
        dependencies = []
        
        # Get dependencies from vcpkg.json
        deps = vcpkg_data.get("dependencies", [])
        for dep in deps:
            if isinstance(dep, str):
                dependencies.append(dep)
            elif isinstance(dep, dict):
                dep_name = dep.get("name", "")
                if dep_name:
                    # Check if it has platform constraints
                    platform = dep.get("platform", "")
                    if platform:
                        dependencies.append(f"{dep_name} (platform: {platform})")
                    else:
                        dependencies.append(dep_name)
                        
        return dependencies
            
    except Exception as e:
        return []

def get_conan_dependencies(package_name: str, version: str = None, verbose=False) -> list:
    """Get C++ package dependencies from Conan Center."""
    if verbose:
        print(f"🔍 Getting Conan dependencies for {package_name}...")
    
    try:
        # Conan Center API
        if version:
            url = f"https://center.conan.io/api/v2/recipes/{package_name}/revisions?version={version}"
        else:
            url = f"https://center.conan.io/api/v2/recipes/{package_name}/revisions"
        
        response = requests.get(url, timeout=10)
        if response.status_code != 200:
            return []
        
        data = response.json()
        revisions = data.get("revisions", [])
        
        if not revisions:
            return []
        
        # Get the latest revision
        latest_revision = revisions[0]
        revision_id = latest_revision.get("id", "")
        
        if not revision_id:
            return []
        
        # Get conanfile content for dependencies
        conanfile_url = f"https://center.conan.io/api/v2/recipes/{package_name}/revisions/{revision_id}/files/conanfile.py"
        
        conanfile_response = requests.get(conanfile_url, timeout=10)
        if conanfile_response.status_code != 200:
            return []
        
        conanfile_content = conanfile_response.text
        dependencies = []
        
        # Parse conanfile.py for requires
        lines = conanfile_content.split('\n')
        in_requires = False
        
        for line in lines:
            line = line.strip()
            
            # Look for requires definition
            if 'requires =' in line or line.startswith('requires'):
                in_requires = True
                # Handle single line requires
                if '"' in line:
                    parts = line.split('"')
                    for i in range(1, len(parts), 2):
                        if '/' in parts[i]:
                            dependencies.append(parts[i])
            elif in_requires and '"' in line:
                # Multi-line requires
                parts = line.split('"')
                for i in range(1, len(parts), 2):
                    if '/' in parts[i]:
                        dependencies.append(parts[i])
                if ']' in line or ')' in line:
                    in_requires = False
                    
        return dependencies
            
    except Exception as e:
        return []

def build_dependency_tree_brackets(package_name: str, package_manager: str = "vcpkg", version: str = None, visited=None, depth=0, max_depth=1) -> str:
    """Recursively build dependency tree for C++ packages using bracket notation."""
    if visited is None:
        visited = set()
    
    # Prevent infinite recursion
    package_key = f"{package_name}=={version}" if version else package_name
    if package_key in visited or depth > max_depth:
        return ""
    
    visited.add(package_key)
    
    # Get direct dependencies based on package manager
    if package_manager == "vcpkg":
        dependencies_list = get_vcpkg_dependencies(package_name, version)
    elif package_manager == "conan":
        dependencies_list = get_conan_dependencies(package_name, version)
    else:
        dependencies_list = []
    
    if not dependencies_list:
        return ""
    
    deps_with_subs = []
    for dep in dependencies_list:
        # Parse dependency name
        dep_name = dep.split()[0].split('/')[0]
        
        # Recursively get sub-dependencies (limited depth for C++ due to complexity)
        if depth < max_depth:
            sub_tree = build_dependency_tree_brackets(dep_name, package_manager, None, visited.copy(), depth + 1, max_depth)
            if sub_tree:
                deps_with_subs.append(f"{dep} ({sub_tree})")
            else:
                deps_with_subs.append(dep)
        else:
            deps_with_subs.append(dep)
    
    return ", ".join(deps_with_subs)

def get_dependency_tree(package: str, package_manager: str = "vcpkg", verbose=False) -> str:
    """Get C++ package dependency tree using bracket notation."""
    if verbose:
        print(f"🔍 Building dependency tree for {package} using {package_manager}...")
    
    # Parse package name and version
    if "==" in package:
        package_name, version = package.split("==", 1)
    else:
        package_name, version = package, None
    
    # Build the tree structure using brackets
    tree_content = build_dependency_tree_brackets(package_name, package_manager, version)
    
    if tree_content:
        return f"{package} ({tree_content})"
    else:
        return f"{package} (no dependencies)" 