#!/usr/bin/env python3
from dotenv import load_dotenv
import os
from openai import OpenAI
import json

load_dotenv()
key = os.getenv('OPENAI_API_KEY')

if not key:
    print("[Test] ERROR: No API key found!")
    exit(1)

print("[Test] Calling OpenAI with valid key...")
client = OpenAI(api_key=key)

try:
    response = client.chat.completions.create(
        model='gpt-3.5-turbo',
        messages=[{
            'role': 'user', 
            'content': 'Generate 3 Japanese phrases for thanking someone. Return ONLY a JSON array like ["thank you", "sorry", "excuse me"]'
        }],
        max_tokens=100,
        temperature=0.7
    )
    
    result = response.choices[0].message.content
    print("[Test] ✓ OpenAI Response:")
    print(f"     {result}")
    
    # Try to parse as JSON
    try:
        phrases = json.loads(result)
        print(f"[Test] ✓ Parsed {len(phrases)} phrases:")
        for p in phrases:
            print(f"     - {p}")
    except:
        print("[Test] (Could not parse as JSON, but API is working)")
        
except Exception as e:
    print(f"[Test] ERROR: {e}")
