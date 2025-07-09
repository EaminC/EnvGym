write_docker_instruction = """
This is the current dockerfile:
{dockerfile_content}

This is the previous failure log:
{log_content}

This is the summary and next steps:
{next_content}

Please modify the dockerfile based on the failure log and next steps recommendations. Only return the new dockerfile content, nothing else.

IMPORTANT: Return ONLY the revised dockerfile content, no explanations, no markdown formatting, no additional text.
""" 