"""C++ dependency tree analysis functionality."""

import requests
import json
import time

def search_vcpkg_package(package_name: str, verbose=False) -> str:
    """Search for package in vcpkg registry using GitHub search API."""
    try:
        # Use GitHub search API to find the package directory
        search_url = f"https://api.github.com/search/code"
        params = {
            'q': f'filename:vcpkg.json repo:Microsoft/vcpkg path:ports/{package_name}',
            'per_page': 1
        }
        
        response = requests.get(search_url, params=params, timeout=10)
        if response.status_code == 200:
            results = response.json()
            if results.get('total_count', 0) > 0:
                items = results.get('items', [])
                if items:
                    # Found the package, return the exact name from path
                    path = items[0].get('path', '')
                    if path.startswith('ports/') and path.endswith('/vcpkg.json'):
                        return path.split('/')[1]  # Extract package name from path
        
        return package_name  # Return original name if not found
        
    except Exception as e:
        if verbose:
            print(f"⚠️ Search failed: {e}")
        return package_name

def get_vcpkg_git_commits(package_name: str, verbose=False) -> list:
    """Get Git commits for a specific vcpkg package to find historical versions."""
    try:
        # Use GitHub API to get commits for the package directory
        commits_url = f"https://api.github.com/repos/Microsoft/vcpkg/commits"
        params = {
            'path': f'ports/{package_name}',
            'per_page': 30  # Get recent commits
        }
        
        response = requests.get(commits_url, params=params, timeout=15)
        if response.status_code == 200:
            commits = response.json()
            if verbose:
                print(f"📊 Found {len(commits)} commits for {package_name}")
            return commits
        else:
            if verbose:
                print(f"⚠️ Failed to get commits: {response.status_code}")
            return []
            
    except Exception as e:
        if verbose:
            print(f"⚠️ Error getting Git commits: {e}")
        return []

def get_vcpkg_dependencies_by_commit(package_name: str, commit_sha: str, verbose=False) -> list:
    """Get vcpkg dependencies from a specific Git commit."""
    try:
        # Get vcpkg.json from specific commit
        url = f"https://api.github.com/repos/Microsoft/vcpkg/contents/ports/{package_name}/vcpkg.json"
        params = {'ref': commit_sha}
        
        response = requests.get(url, params=params, timeout=15)
        if response.status_code == 200:
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
            
            if verbose:
                print(f"📦 Found {len(dependencies)} dependencies in commit {commit_sha[:8]}")
            return dependencies
            
    except Exception as e:
        if verbose:
            print(f"⚠️ Error getting dependencies from commit {commit_sha[:8]}: {e}")
        return []

def get_vcpkg_version_from_commit(package_name: str, commit_sha: str, verbose=False) -> str:
    """Extract version information from a specific commit."""
    try:
        url = f"https://api.github.com/repos/Microsoft/vcpkg/contents/ports/{package_name}/vcpkg.json"
        params = {'ref': commit_sha}
        
        response = requests.get(url, params=params, timeout=15)
        if response.status_code == 200:
            import base64
            content_data = response.json()
            if "content" not in content_data:
                return ""
            
            content = base64.b64decode(content_data["content"]).decode('utf-8')
            vcpkg_data = json.loads(content)
            
            # Try to get version information
            version = vcpkg_data.get("version", "")
            version_string = vcpkg_data.get("version-string", "")
            port_version = vcpkg_data.get("port-version", "")
            
            if version:
                return f"{version}" + (f".{port_version}" if port_version else "")
            elif version_string:
                return f"{version_string}" + (f".{port_version}" if port_version else "")
            
        return ""
        
    except Exception as e:
        if verbose:
            print(f"⚠️ Error getting version from commit {commit_sha[:8]}: {e}")
        return ""

def find_vcpkg_version_by_history(package_name: str, target_version: str, verbose=False) -> tuple:
    """Find the Git commit that matches a specific version."""
    if verbose:
        print(f"🔍 Searching Git history for {package_name} version {target_version}...")
    
    commits = get_vcpkg_git_commits(package_name, verbose)
    if not commits:
        return None, []
    
    # Search through commits to find matching version
    for commit in commits:
        commit_sha = commit.get('sha', '')
        if not commit_sha:
            continue
            
        commit_version = get_vcpkg_version_from_commit(package_name, commit_sha, verbose)
        if commit_version and (target_version in commit_version or commit_version in target_version):
            if verbose:
                print(f"✅ Found matching version {commit_version} in commit {commit_sha[:8]}")
            dependencies = get_vcpkg_dependencies_by_commit(package_name, commit_sha, verbose)
            return commit_sha, dependencies
            
        # Also check if the target version is a partial match
        if commit_version:
            try:
                if target_version.replace('v', '').replace('.', '') in commit_version.replace('v', '').replace('.', ''):
                    if verbose:
                        print(f"✅ Found partial match {commit_version} in commit {commit_sha[:8]}")
                    dependencies = get_vcpkg_dependencies_by_commit(package_name, commit_sha, verbose)
                    return commit_sha, dependencies
            except:
                pass
    
    if verbose:
        print(f"⚠️ No matching version found for {target_version}")
    return None, []

def get_vcpkg_dependencies(package_name: str, version: str = None, verbose=False) -> list:
    """Get C++ package dependencies from vcpkg registry."""
    if verbose:
        print(f"🔍 Getting vcpkg dependencies for {package_name}...")
    
    try:
        # First, try to find the exact package name
        actual_package_name = search_vcpkg_package(package_name, verbose)
        
        # If version is specified, try to find it in Git history
        if version:
            if verbose:
                print(f"🔍 Searching for specific version: {version}")
            commit_sha, historical_deps = find_vcpkg_version_by_history(actual_package_name, version, verbose)
            if commit_sha and historical_deps:
                return historical_deps
            elif verbose:
                print(f"⚠️ Version {version} not found in history, falling back to current version")
        
        # Approach 1: Direct vcpkg.json file access
        url = f"https://api.github.com/repos/Microsoft/vcpkg/contents/ports/{actual_package_name}/vcpkg.json"
        
        # Add retry logic for robustness
        for attempt in range(3):
            try:
                if verbose and attempt > 0:
                    print(f"⏳ Retry attempt {attempt + 1}...")
                
                response = requests.get(url, timeout=15)
                if response.status_code == 200:
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
                    
                elif response.status_code == 404:
                    # Package not found, try alternative approach
                    break
                elif response.status_code == 403:
                    # Rate limited, wait and retry
                    if attempt < 2:
                        wait_time = (attempt + 1) * 2
                        if verbose:
                            print(f"⏳ Rate limited, waiting {wait_time}s...")
                        time.sleep(wait_time)
                    continue
                else:
                    # Other HTTP error, retry with delay
                    if attempt < 2:
                        time.sleep(1)
                    continue
                    
            except requests.exceptions.RequestException as e:
                if verbose:
                    print(f"⚠️ Network error on attempt {attempt + 1}: {e}")
                if attempt < 2:
                    time.sleep(2 ** attempt)
                continue
        
        # Approach 2: Try directory listing if direct method failed
        if verbose:
            print("🔄 Trying alternative approach via directory listing...")
        
        try:
            dir_url = f"https://api.github.com/repos/Microsoft/vcpkg/contents/ports/{actual_package_name}"
            dir_response = requests.get(dir_url, timeout=10)
            
            if dir_response.status_code == 200:
                files = dir_response.json()
                if isinstance(files, list):
                    # Look for vcpkg.json in the directory
                    vcpkg_file = next((f for f in files if f.get("name") == "vcpkg.json"), None)
                    if vcpkg_file and "download_url" in vcpkg_file:
                        # Try to download the file directly
                        file_response = requests.get(vcpkg_file["download_url"], timeout=10)
                        if file_response.status_code == 200:
                            vcpkg_data = json.loads(file_response.text)
                            
                            dependencies = []
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
            if verbose:
                print(f"⚠️ Alternative approach failed: {e}")
        
        if verbose:
            print(f"⚠️ Package {package_name} not found in vcpkg registry")
        return []
                    
    except Exception as e:
        if verbose:
            print(f"❌ Error getting dependencies for {package_name}: {e}")
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
    elif package_manager == "hunter":
        dependencies_list = get_hunter_dependencies(package_name, version)
    elif package_manager == "cpm":
        dependencies_list = get_cpm_dependencies(package_name, version)
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