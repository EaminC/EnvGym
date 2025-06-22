"""Version information retrieval for Java artifacts."""

import requests

def get_versions(artifact_input: str, limit=None, verbose=False) -> str:
    """Get Java artifact version information as comma-separated string."""
    if verbose:
        print(f"🔍 Getting versions for {artifact_input}...")
    
    # Parse artifact coordinates
    if ":" in artifact_input:
        parts = artifact_input.split(":")
        if len(parts) >= 2:
            group_id, artifact_id = parts[0], parts[1]
        else:
            return f"Error: Invalid artifact format (expected groupId:artifactId)"
    else:
        return f"Error: Invalid artifact format (expected groupId:artifactId)"
    
    url = f"https://search.maven.org/solrsearch/select?q=g:{group_id}+AND+a:{artifact_id}&core=gav&rows=100&wt=json"
    
    try:
        response = requests.get(url, timeout=10)
        if response.status_code != 200:
            return f"Error: Cannot find artifact {group_id}:{artifact_id}"
        
        data = response.json()
        docs = data.get("response", {}).get("docs", [])
        versions = [doc.get("v", "") for doc in docs if doc.get("v")]
        
        # Sort versions in descending order
        versions = sorted(list(set(versions)), reverse=True)
        
        if limit and len(versions) > limit:
            version_list = versions[:limit]
            return ", ".join(version_list)
        else:
            return ", ".join(versions)
            
    except Exception as e:
        return f"Error: {e}" 