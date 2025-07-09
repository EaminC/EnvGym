from openai import OpenAI
from dotenv import load_dotenv
import os

# .env is in ../../.env

load_dotenv()

FORGE_API_KEY = os.getenv("FORGE_API_KEY")
client = OpenAI(
    base_url="https://api.forge.tensorblock.co/v1", 
    api_key=FORGE_API_KEY,  
)
    
# models = client.models.list()

completion = client.chat.completions.create(
    model="Azure/gpt4.1",
    messages=[
        {"role": "developer", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Hello!"}
    ]
)

print(completion.choices[0].message)

completion = client.chat.completions.create(
    model="Azure/gpt-4",
    messages=[
        {"role": "developer", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Hello!"}
    ]
)

print(completion.choices[0].message)