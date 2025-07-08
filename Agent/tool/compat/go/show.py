"""Version information retrieval for Go modules."""

import requests

def get_versions(module_input: str, limit=None, verbose=False) -> str:
    """Get Go module version information as comma-separated string."""
    if verbose:
        print(f"🔍 Getting versions for {module_input}...")
    
    module_name = module_input.split('@')[0]
    url = f"https://proxy.golang.org/{module_name}/@v/list"
    
    try:
        response = requests.get(url, timeout=10)
        if response.status_code != 200:
            return f"Error: Cannot find module {module_name}"
        
        versions = response.text.strip().split('\n')
        versions = [v.strip() for v in versions if v.strip()]
        versions = sorted(versions, reverse=True)
        
        if limit and len(versions) > limit:
            version_list = versions[:limit]
            return ", ".join(version_list)
        else:
            return ", ".join(versions)
            
    except Exception as e:
        return f"Error: {e}" 