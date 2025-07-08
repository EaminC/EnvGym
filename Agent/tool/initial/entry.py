import os
from pathlib import Path
from typing import Optional, Dict, Any


def create_envgym_directory(base_path: Optional[str] = None) -> Dict[str, Any]:
    """
    Create envgym folder in the specified directory (default is current working directory) 
    and create necessary empty files inside it
    
    Args:
        base_path: Base path, if None then use current working directory
        
    Returns:
        Dict containing operation results and file paths
    """
    try:
        # Determine base path
        if base_path is None:
            base_path = os.getcwd()
        
        base_path = Path(base_path)
        envgym_dir = base_path / "envgym"
        
        # Create envgym directory
        envgym_dir.mkdir(exist_ok=True)
        
        # Define list of files to create
        files_to_create = [
            "plan.txt",
            "history.txt", 
            "next.txt",
            "status.txt",
            "envgym.dockerfile",
            "documents.json"
        ]
        
        created_files = []
        
        # Create empty files
        for filename in files_to_create:
            file_path = envgym_dir / filename
            file_path.touch()  # Create empty file
            created_files.append(str(file_path))
        
        result = {
            "success": True,
            "message": f"Successfully created envgym directory and related files",
            "envgym_directory": str(envgym_dir),
            "created_files": created_files,
            "base_path": str(base_path)
        }
        
        return result
        
    except Exception as e:
        result = {
            "success": False,
            "message": f"Error occurred while creating envgym directory: {str(e)}",
            "envgym_directory": None,
            "created_files": [],
            "base_path": str(base_path) if base_path else None,
            "error": str(e)
        }
        
        return result

