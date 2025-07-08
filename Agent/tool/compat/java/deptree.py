"""Java dependency tree analysis functionality."""

import requests
import xml.etree.ElementTree as ET
import json

def get_artifact_dependencies(group_id: str, artifact_id: str, version: str = None, verbose=False) -> list:
    """Get Java artifact dependencies from Maven Central without installing."""
    if verbose:
        print(f"🔍 Getting dependencies for {group_id}:{artifact_id}...")
    
    try:
        # Get artifact info from Maven Central
        if not version:
            # Get latest version first
            search_url = f"https://search.maven.org/solrsearch/select?q=g:{group_id}+AND+a:{artifact_id}&core=gav&rows=1&wt=json"
            search_response = requests.get(search_url, timeout=10)
            if search_response.status_code != 200:
                return []
            search_data = search_response.json()
            docs = search_data.get("response", {}).get("docs", [])
            if not docs:
                return []
            version = docs[0].get("v", "")
            if not version:
                return []
        
        # Get POM file for dependency information
        pom_url = f"https://repo1.maven.org/maven2/{group_id.replace('.', '/')}/{artifact_id}/{version}/{artifact_id}-{version}.pom"
        
        response = requests.get(pom_url, timeout=10)
        if response.status_code != 200:
            return []
        
        # Parse POM XML
        root = ET.fromstring(response.content)
        
        # Handle namespace
        namespace = {"m": "http://maven.apache.org/POM/4.0.0"}
        if root.tag.startswith("{"):
            # Extract namespace from root tag
            ns_end = root.tag.find("}")
            namespace["m"] = root.tag[1:ns_end]
        else:
            namespace = {}
        
        dependencies = []
        
        # Find dependencies section
        deps_element = root.find(".//m:dependencies" if namespace else ".//dependencies", namespace)
        if deps_element is not None:
            for dep in deps_element.findall("m:dependency" if namespace else "dependency", namespace):
                group_elem = dep.find("m:groupId" if namespace else "groupId", namespace)
                artifact_elem = dep.find("m:artifactId" if namespace else "artifactId", namespace)
                version_elem = dep.find("m:version" if namespace else "version", namespace)
                scope_elem = dep.find("m:scope" if namespace else "scope", namespace)
                optional_elem = dep.find("m:optional" if namespace else "optional", namespace)
                
                # Skip test and provided dependencies, and optional dependencies
                scope = scope_elem.text if scope_elem is not None else "compile"
                optional = optional_elem.text if optional_elem is not None else "false"
                
                if scope not in ["test", "provided"] and optional.lower() != "true":
                    if group_elem is not None and artifact_elem is not None:
                        group = group_elem.text
                        artifact = artifact_elem.text
                        dep_version = version_elem.text if version_elem is not None else "latest"
                        dependencies.append(f"{group}:{artifact} {dep_version}")
                        
        return dependencies
            
    except Exception as e:
        return []

def build_dependency_tree_json(group_id: str, artifact_id: str, version: str = None, visited=None, depth=0, max_depth=1) -> dict:
    """Recursively build dependency tree for Java artifacts as JSON."""
    if visited is None:
        visited = set()
    
    # Prevent infinite recursion
    artifact_key = f"{group_id}:{artifact_id}=={version}" if version else f"{group_id}:{artifact_id}"
    if artifact_key in visited or depth > max_depth:
        return {"dependencies": []}
    
    visited.add(artifact_key)
    
    # Get direct dependencies
    dependencies_list = get_artifact_dependencies(group_id, artifact_id, version)
    
    dependencies = []
    for dep in dependencies_list:
        # Parse dependency to get group and artifact
        dep_parts = dep.split()
        if len(dep_parts) >= 1:
            dep_coord = dep_parts[0]
            if ":" in dep_coord:
                dep_group, dep_artifact = dep_coord.split(":", 1)
            else:
                continue
        else:
            continue
        
        dep_info = {
            "name": dep,
            "subdependencies": []
        }
        
        # Recursively get sub-dependencies (limited depth for Java due to complexity)
        if depth < max_depth:
            sub_tree = build_dependency_tree_json(dep_group, dep_artifact, None, visited.copy(), depth + 1, max_depth)
            dep_info["subdependencies"] = sub_tree.get("dependencies", [])
        
        dependencies.append(dep_info)
    
    return {"dependencies": dependencies}

def build_dependency_tree_brackets(group_id: str, artifact_id: str, version: str = None, visited=None, depth=0, max_depth=1) -> str:
    """Recursively build dependency tree for Java artifacts using bracket notation."""
    if visited is None:
        visited = set()
    
    # Prevent infinite recursion
    artifact_key = f"{group_id}:{artifact_id}=={version}" if version else f"{group_id}:{artifact_id}"
    if artifact_key in visited or depth > max_depth:
        return ""
    
    visited.add(artifact_key)
    
    # Get direct dependencies
    dependencies_list = get_artifact_dependencies(group_id, artifact_id, version)
    
    if not dependencies_list:
        return ""
    
    deps_with_subs = []
    for dep in dependencies_list:
        # Parse dependency to get group and artifact
        dep_parts = dep.split()
        if len(dep_parts) >= 1:
            dep_coord = dep_parts[0]
            if ":" in dep_coord:
                dep_group, dep_artifact = dep_coord.split(":", 1)
            else:
                continue
        else:
            continue
        
        # Recursively get sub-dependencies (limited depth for Java due to complexity)
        if depth < max_depth:
            sub_tree = build_dependency_tree_brackets(dep_group, dep_artifact, None, visited.copy(), depth + 1, max_depth)
            if sub_tree:
                deps_with_subs.append(f"{dep} ({sub_tree})")
            else:
                deps_with_subs.append(dep)
        else:
            deps_with_subs.append(dep)
    
    return ", ".join(deps_with_subs)

def get_dependency_tree(artifact: str, verbose=False) -> str:
    """Get Java artifact dependency tree using bracket notation."""
    if verbose:
        print(f"🔍 Building dependency tree for {artifact}...")
    
    # Parse artifact coordinates (groupId:artifactId:version or groupId:artifactId)
    if ":" in artifact:
        parts = artifact.split(":")
        if len(parts) >= 3:
            group_id, artifact_id, version = parts[0], parts[1], parts[2]
        elif len(parts) == 2:
            group_id, artifact_id, version = parts[0], parts[1], None
        else:
            return f"{artifact} (invalid format)"
    else:
        return f"{artifact} (invalid format)"
    
    # Build the tree structure using brackets
    tree_content = build_dependency_tree_brackets(group_id, artifact_id, version)
    
    if tree_content:
        return f"{artifact} ({tree_content})"
    else:
        return f"{artifact} (no dependencies)" 