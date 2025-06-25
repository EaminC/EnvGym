import os

status_path = os.path.join(os.path.dirname(__file__), "status.txt")
history_path = os.path.join(os.path.dirname(__file__), "history.txt")

# Only proceed if status.txt is not empty
if os.path.isfile(status_path) and os.path.getsize(status_path) > 0:
    with open(status_path, "r", encoding="utf-8") as sf:
        lines = [line.rstrip('\n') for line in sf]
    if lines:
        with open(history_path, "a", encoding="utf-8") as hf:
            for line in lines:
                hf.write(f"STATUS: {line}\n")
