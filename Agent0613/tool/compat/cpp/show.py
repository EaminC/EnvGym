"""Version information retrieval for C++ packages."""

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

def get_versions(package_input: str, package_manager: str = "vcpkg", limit=None, verbose=False) -> str:
    """Get C++ package version information as comma-separated string."""
    if verbose:
        print(f"🔍 Getting versions for {package_input} using {package_manager}...")
    
    package_name = package_input.split('==')[0]
    versions = []
    
    try:
        if package_manager == "vcpkg":
            # First, try to find the exact package name
            actual_package_name = search_vcpkg_package(package_name, verbose)
            
            # Try multiple approaches for vcpkg
            
            # Approach 1: Direct vcpkg.json file
            url = f"https://api.github.com/repos/Microsoft/vcpkg/contents/ports/{actual_package_name}/vcpkg.json"
            success = False
            
            # Add retry logic for robustness
            for attempt in range(3):
                try:
                    if verbose and attempt > 0:
                        print(f"⏳ Retry attempt {attempt + 1}...")
                    
                    response = requests.get(url, timeout=15)
                    
                    if response.status_code == 200:
                        import base64
                        content_data = response.json()
                        if "content" in content_data:
                            content = base64.b64decode(content_data["content"]).decode('utf-8')
                            vcpkg_data = json.loads(content)
                            version = vcpkg_data.get("version", "")
                            version_string = vcpkg_data.get("version-string", "")
                            port_version = vcpkg_data.get("port-version", "")
                            
                            if version:
                                versions.append(version)
                            elif version_string:
                                versions.append(version_string)
                            if port_version:
                                versions.append(f"port-{port_version}")
                            
                            success = True
                            break
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
            
            # Approach 2: If direct method failed, try directory listing
            if not success and not versions:
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
                                    version = vcpkg_data.get("version", "")
                                    version_string = vcpkg_data.get("version-string", "")
                                    port_version = vcpkg_data.get("port-version", "")
                                    
                                    if version:
                                        versions.append(version)
                                    elif version_string:
                                        versions.append(version_string)
                                    if port_version:
                                        versions.append(f"port-{port_version}")
                except Exception as e:
                    if verbose:
                        print(f"⚠️ Alternative approach failed: {e}")
            
        elif package_manager == "conan":
            # Conan Center API
            url = f"https://center.conan.io/api/v2/recipes/{package_name}/revisions"
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                revisions = data.get("revisions", [])
                for revision in revisions:
                    version = revision.get("version", "")
                    if version:
                        versions.append(version)
        
        if not versions:
            error_msg = f"Cannot find package {package_name} in {package_manager}"
            if package_manager == "vcpkg":
                error_msg += ". Please verify the package name is correct"
            return f"Error: {error_msg}"
        else:
            # Remove duplicates and sort
            versions = sorted(list(set(versions)), reverse=True)
            
            if limit and len(versions) > limit:
                version_list = versions[:limit]
                return ", ".join(version_list)
            else:
                return ", ".join(versions)
            
    except Exception as e:
        return f"Error: {e}" 