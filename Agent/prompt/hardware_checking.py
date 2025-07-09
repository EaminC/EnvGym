hardware_checking_prompt = """
Given the system, hardware, and GPU information, return only the essential factors that influence Dockerfile writing and image compatibility.

Respond in the following fixed format (no extra text):

- Architecture: [detected CPU architecture and recommended --platform value]
- Base Image: [compatible base image types or tags based on CPU/GPU info]
- GPU: [presence of NVIDIA GPU, GPU architecture, and recommended CUDA base image tag if applicable]
- Instruction Notes: [any Dockerfile instruction limitations or adjustments based on hardware]
- Docker Version: [Docker version and compatibility with BuildKit, GPU builds, or features like --gpus]

Exclude runtime flags like memory/CPU/gpu limits. Do not include explanations or extra formatting.
"""