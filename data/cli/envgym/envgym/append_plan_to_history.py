import os

plan_path = os.path.join(os.path.dirname(__file__), "plan.txt")
history_path = os.path.join(os.path.dirname(__file__), "history.txt")

# Only proceed if plan.txt is not empty
if os.path.isfile(plan_path) and os.path.getsize(plan_path) > 0:
    with open(plan_path, "r", encoding="utf-8") as pf:
        lines = [line.rstrip('\n') for line in pf]
    if lines:
        with open(history_path, "a", encoding="utf-8") as hf:
            for line in lines:
                hf.write(f"PLAN: {line}\n")