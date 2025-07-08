plan_instruction = """
Based on the newly provided file content, combine it with the existing environment configuration plan to update and improve the plan.

Analysis requirements:
- Identify new requirements introduced by the new file
- Check for conflicts with existing plans
- Supplement missing configuration items
- Optimize existing configuration steps

Output format requirements (complete updated plan):
=== ENVIRONMENT SETUP PLAN ===

1. DOWNLOADS NEEDED: 
   - [Complete updated download list]
   - [Newly added dependencies and tools]
   - [Version compatibility requirements]

2. FILES TO CREATE: 
   - [Complete updated file creation list]
   - [Newly added configuration files]
   - [Modified existing files]

3. NECESSARY TEST CASES IN THE CODEBASE: 
   - [Complete updated test case list]
   - [Newly added test scenarios]
   - [Tests for new features]

4. COMPLETE TODO LIST: 
   - [Complete updated step list]
   - [Integrate new and old steps, maintaining logical order]
   - [Include configuration steps for new features]
   - [Updated verification methods]

Update principles:
- Maintain plan consistency and completeness
- Reasonably integrate new and old requirements
- Avoid duplication and conflicts
- Ensure step executability

Please output the complete updated plan without any additional explanatory text.
"""