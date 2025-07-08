"""Version information retrieval for Rust crates."""

import requests

def get_versions(crate_input: str, limit=None, verbose=False) -> str:
    """Get Rust crate version information as comma-separated string."""
    if verbose:
        print(f"🔍 Getting versions for {crate_input}...")
    
    crate_name = crate_input.split('==')[0]
    url = f"https://crates.io/api/v1/crates/{crate_name}/versions"
    
    try:
        response = requests.get(url, timeout=10)
        if response.status_code != 200:
            return f"Error: Cannot find crate {crate_name}"
        
        data = response.json()
        versions_data = data.get("versions", [])
        versions = [v.get("num", "") for v in versions_data if v.get("num")]
        
        if limit and len(versions) > limit:
            version_list = versions[:limit]
            return ", ".join(version_list)
        else:
            return ", ".join(versions)
            
    except Exception as e:
        return f"Error: {e}" 