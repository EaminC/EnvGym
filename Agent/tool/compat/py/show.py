"""Version information retrieval from PyPI."""

import requests

def get_versions(package_input: str, limit=None, verbose=False) -> str:
    """Get package version information as comma-separated string."""
    if verbose:
        print(f"🔍 Getting versions for {package_input}...")
    
    package_name = package_input.split('==')[0]
    url = f"https://pypi.org/pypi/{package_name}/json"
    
    try:
        response = requests.get(url, timeout=10)
        if response.status_code != 200:
            return f"Error: Cannot find package {package_name}"
        
        data = response.json()
        versions = sorted(data["releases"].keys(), reverse=True)
        
        if limit and len(versions) > limit:
            version_list = versions[:limit]
            return ", ".join(version_list)
        else:
            return ", ".join(versions)
            
    except Exception as e:
        return f"Error: {e}" 