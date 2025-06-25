import os

next_path = os.path.join(os.path.dirname(__file__), "next.txt")
history_path = os.path.join(os.path.dirname(__file__), "history.txt")

# Only proceed if next.txt is not empty
if os.path.isfile(next_path) and os.path.getsize(next_path) > 0:
    with open(next_path, "r", encoding="utf-8") as nf:
        lines = [line.rstrip('\n') for line in nf]
    if lines:
        with open(history_path, "a", encoding="utf-8") as hf:
            for line in lines:
                hf.write(f"NEXT: {line}\n")