#!/usr/bin/env python3
"""
setup-env.py
Reads API keys from .env and writes watch-app/entry/build-profile.json5.

Run once after cloning:
    python setup-env.py

Both .env and build-profile.json5 are gitignored — keys never touch git.
"""
import os
import re

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ENV_FILE = os.path.join(SCRIPT_DIR, '.env')
TEMPLATE_FILE = os.path.join(SCRIPT_DIR, 'watch-app', 'entry', 'build-profile.json5.template')
OUTPUT_FILE = os.path.join(SCRIPT_DIR, 'watch-app', 'entry', 'build-profile.json5')


def load_env(path):
    """Parse a .env file into a dict, ignoring comments and blank lines."""
    env = {}
    if not os.path.exists(path):
        return env
    with open(path, encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if '=' in line:
                key, _, value = line.partition('=')
                env[key.strip()] = value.strip()
    return env


def main():
    if not os.path.exists(ENV_FILE):
        print(f"[setup-env] ERROR: .env not found at {ENV_FILE}")
        print("  Create a .env file with OPENAI_API_KEY and GOOGLE_PLACES_API_KEY.")
        return 1

    env = load_env(ENV_FILE)
    openai_key = env.get('OPENAI_API_KEY', '')
    places_key = env.get('GOOGLE_PLACES_API_KEY', '')

    if not openai_key:
        print("[setup-env] WARNING: OPENAI_API_KEY is empty in .env")
    if not places_key:
        print("[setup-env] WARNING: GOOGLE_PLACES_API_KEY is empty in .env (AI context alerts need this)")

    with open(TEMPLATE_FILE, encoding='utf-8') as f:
        content = f.read()

    content = re.sub(
        r'"OPENAI_API_KEY":\s*""',
        f'"OPENAI_API_KEY": "{openai_key}"',
        content
    )
    content = re.sub(
        r'"GOOGLE_PLACES_API_KEY":\s*""',
        f'"GOOGLE_PLACES_API_KEY": "{places_key}"',
        content
    )

    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"[setup-env] Written: {OUTPUT_FILE}")
    print(f"  OPENAI_API_KEY    : {'(set)' if openai_key else '(empty)'}")
    print(f"  GOOGLE_PLACES_KEY : {'(set)' if places_key else '(empty)'}")
    print("[setup-env] Done. Rebuild the watch app in DevEco Studio.")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
