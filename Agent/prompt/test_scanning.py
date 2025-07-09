test_scanning_instruction = """
You need to scan the whole codebase and identify all test files that can be used to verify if the environment is properly configured and working correctly.

Please identify and return the relative paths of files that are clearly meant for testing, including but not limited to:

1. Unit test files (test_*.py, *_test.py, test*.js, *.test.js, etc.)
2. Integration test files 
3. Example or demo files that can be run to verify the environment (examples/, demo/, sample/ directories)
4. Test scripts or verification scripts
5. Benchmark files that might serve as tests
6. Configuration test files
7. Any files with "test", "spec", "example", "demo", "sample" in their names or paths
8. Files in test-related directories (tests/, test/, __tests__, spec/, examples/, demos/, samples/)

Focus on files that could be executed to validate that the environment setup is working correctly. Ignore files in the envgym directory.

If there are submodules that also include test files, you should include them as well.
""" 