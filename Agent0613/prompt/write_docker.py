write_docker_instruction = """
You need to write a dockerfile for the current codebase and please remember to write it in envgym/envgym.dockerfile.


The current dockerfile is in envgym/envgym.dockerfile.It is either empty or not complete.

You need to read the envgym/plan.txt, envgym/status.txt, envgym/log.txt, envgym/envgym.dockerfile, envgym/next.txt and write a new dockerfile in envgym/envgym.You should learn from the precivious status,reason of failure and modify the dockerfile and rewrite it in envgym/envgym.dockerfile for the next iteration.





Here are the files you need to read:
1. envgym/plan.txt:The whole plan of building up the environment,dont modify it.
2. envgym/next.txt:The current status and progress of the building up the environment as well as the next step to do or modify
3. envgym/log.txt:The log when running the dockerfile.
4. envgym/envgym.dockerfile:Most important,this is the dockerfile you need to initialize or update according to the previous files.


Please write the dockerfile in envgym/envgym.dockerfile.
""" 