plan_instruction = """
Based on the provided file content, analyze the project requirements and create a complete environment configuration plan.

Output format requirements:
=== ENVIRONMENT SETUP PLAN ===

1. DOWNLOADS NEEDED: 
   - [List software, tools, dependencies, etc. that need to be downloaded]
   - [Include version requirements]

2. FILES TO CREATE: 
   - [List configuration files that need to be created]
   - [Include file paths and basic content descriptions]

3. NECESSARY TEST CASES IN THE CODEBASE: 
   - [List test cases that need to be written]
   - [Include key functionality points to test]

4. COMPLETE TODO LIST: 
   - [Detailed step list, arranged in execution order]
   - [Each step should be specific and executable]
   - [Include verification methods]

Important notes:
- The plan should be detailed and actionable
- Consider compatibility across different operating systems
- Include error handling and verification steps
- Ensure completeness of environment configuration

Please output the complete plan content without any additional explanatory text.
"""