updating_instruction = """
Now you have run a complete iteration of building up the environment and need to summarize the current progress and the next step in envgym/next.txt.

Here are the files you need to read:
1. envgym/plan.txt:The whole plan of building up the environment,dont modify it.
2. envgym/log.txt:The log when running the dockerfile.
3. envgym/envgym.dockerfile:The dockerfile to build up the environment.
4. envgym/status.txt:do not modify it until you believe the dockerfile is built and run successfully, and all the test cases are passed.


You need to update the status of building up the environment to the following files:
1.envgym/next.txt:Summarize the current status and progress of the building up the environment and overwrite it with the latest status.If the whole dockerfile is built and run successfully, and all the test cases are passed, then the status should be "SUCCESS".Otherwise write the current status and progress.Write the next step to do or modify.write how to modify the dockerfile to make it work

2. envgym/status.txt:If you believe the dockerfile is built and run successfully, and all the test cases are passed, then Write "SUCCESS" in the status.txt.
"""