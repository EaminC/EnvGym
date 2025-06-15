"""Version information retrieval for C++ packages."""

import requests
import json

def get_versions(package_input: str, package_manager: str = "vcpkg", limit=None, verbose=False) -> str:
    """Get C++ package version information as comma-separated string."""
    if verbose:
        print(f"🔍 Getting versions for {package_input} using {package_manager}...")
    
    package_name = package_input.split('==')[0]
    versions = []
    
    try:
        if package_manager == "vcpkg":
            # vcpkg uses GitHub registry
            url = f"https://api.github.com/repos/Microsoft/vcpkg/contents/ports/{package_name}/vcpkg.json"
            response = requests.get(url, timeout=10)
            
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
            return f"Error: Cannot find package {package_name} in {package_manager}"
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