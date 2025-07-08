plan_instruction = """
You need to make a comprehensive plan of how to build up a complete docker image to run the project and please remember to write it into envgym/plan.txt.

You dont need to run any source code but only to read the README and DOCKERFILE and output the plan.
You can breifly scan the whole codebase but through tree command and read following documents and dont read the other files:

1. README and other turoial files (README.md, README.txt, readme.md etc.)
2. Existing environment files (Dockerfile, requirements.txt, package.json, setup.py, pyproject.toml etc.)



Output format to envgym/plan.txt:
=== ENVIRONMENT SETUP PLAN ===
1. DOWNLOADS NEEDED: [specific list]
2. FILES TO CREATE: [specific list]  
3. NECESSARY TEST CASES IN THE CODEBASE: [specific list]
4. COMPLETE TODO LIST: [specific steps]
The plan should be comprehensive and detailed, You can
You can write the plan step by step and update the envgym/plan.txt file
"""