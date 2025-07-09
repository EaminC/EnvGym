scanning_instruction = """
You need to scan the whole codebase and write down all the relative path of the documents including README and other turoial files (README.md, README.txt, readme.md etc.) into envgym/documents.json.
You can breifly scan the whole codebase but through tree command and read following documents and dont read the other files and you can ignore the files in envgym directory:

1. README and other turoial files (README.md, README.txt, readme.md etc.)
2. Existing environment files (Dockerfile, requirements.txt, package.json, setup.py, pyproject.toml etc.)

"""