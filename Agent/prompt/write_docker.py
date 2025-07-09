write_docker_instruction = """
This is the current working directory structure:
{directory_tree}

This is the current dockerfile:
{dockerfile_content}

This is the previous failure log:
{log_content}

This is the summary and next steps:
{next_content}

Please modify the dockerfile based on the failure log and next steps recommendations. 

IMPORTANT REQUIREMENTS:
1. ONLY reference files and directories that exist in the directory tree shown above
2. Do NOT add COPY or ADD commands for files that don't exist
3. Verify all file paths against the directory structure
4. Return ONLY the revised dockerfile content, no explanations, no markdown formatting, no additional text

Only return the new dockerfile content, nothing else.
""" 