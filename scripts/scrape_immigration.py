#!/usr/bin/env python3
"""
scrape_immigration.py
Build-time script to fetch official immigration arrival procedures from government
sources and update the country JSON asset files.

Usage:
    pip install requests beautifulsoup4 openai
    OPENAI_API_KEY=sk-... python scripts/scrape_immigration.py

The script:
  1. Fetches each country's official immigration page.
  2. Extracts raw text from the page.
  3. Sends the text + a structured prompt to GPT to produce clean arrival steps.
  4. Merges the new arrivalSteps into the existing country JSON (airport scenario only).
  5. Writes the updated JSON back to assets/countries/{code}.json.

Existing non-airport scenarios, fallbackAlerts, and phrases are preserved.
A backup of the original file is written to assets/countries/{code}.json.bak.
"""

import json
import os
import sys
import time
from pathlib import Path

try:
    import requests
    from bs4 import BeautifulSoup
    from openai import OpenAI
except ImportError:
    print("ERROR: Missing dependencies. Run: pip install requests beautifulsoup4 openai")
    sys.exit(1)

# ── Configuration ──────────────────────────────────────────────────────────────

ASSETS_DIR = Path(__file__).parent.parent / "phone-app" / "app" / "src" / "main" / "assets" / "countries"

OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY", "")
if not OPENAI_API_KEY:
    print("ERROR: Set OPENAI_API_KEY environment variable.")
    sys.exit(1)

client = OpenAI(api_key=OPENAI_API_KEY)

# Official immigration sources per country code
SOURCES: dict[str, dict] = {
    "JP": {
        "name": "Japan",
        "urls": [
            "https://www.mofa.go.jp/j_info/visit/visa/index.html",
            "https://www.customs.go.jp/english/",
        ],
    },
    "TH": {
        "name": "Thailand",
        "urls": [
            "https://www.immigration.go.th",
            "https://www.customs.go.th/content.php?ini_content=personal_traveler_001_160459_EngVersion&lang=en-US",
        ],
    },
    "IN": {
        "name": "India",
        "urls": [
            "https://www.boi.gov.in",
            "https://indianvisaonline.gov.in",
        ],
    },
    "AE": {
        "name": "United Arab Emirates",
        "urls": [
            "https://u.ae/en/information-and-services/visa-and-emirates-id",
            "https://www.icp.gov.ae/en/",
        ],
    },
    "SG": {
        "name": "Singapore",
        "urls": [
            "https://www.ica.gov.sg/enter-transit-depart/entering-singapore",
        ],
    },
    "VN": {
        "name": "Vietnam",
        "urls": [
            "https://evisa.xuatnhapcanh.gov.vn",
            "https://www.customs.gov.vn/index.jsp?pageIndex=1&site=1",
        ],
    },
    "ID": {
        "name": "Indonesia",
        "urls": [
            "https://molina.imigrasi.go.id",
            "https://www.beacukai.go.id/page/ketentuan-pembawaan-barang-penumpang.html",
        ],
    },
    "MY": {
        "name": "Malaysia",
        "urls": [
            "https://www.imi.gov.my",
            "https://imigresen-online.imi.gov.my/mdac/main",
        ],
    },
    "LA": {
        "name": "Laos",
        "urls": [
            "https://www.laoevisa.gov.la",
        ],
    },
    "KH": {
        "name": "Cambodia",
        "urls": [
            "https://www.evisa.gov.kh",
            "https://www.customs.gov.kh/en/",
        ],
    },
}

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (compatible; ArrivalRitualBot/1.0; "
        "+https://github.com/arrivalritual/hackathon)"
    )
}

GPT_SYSTEM_PROMPT = """
You are a travel compliance specialist. Given raw text scraped from an official government
immigration website, extract the arrival steps for an international air traveller arriving
at the country's main international airport for the first time.

Output ONLY valid JSON (no markdown, no prose) in this exact schema:
[
  {
    "stepIndex": 0,
    "title": "Short imperative title (max 8 words)",
    "description": "Clear, actionable description (1-3 sentences). Include specific thresholds, allowances, or penalties where mentioned.",
    "riskLevel": "NORM | SENSITIVE | LEGAL"
  }
]

riskLevel rules:
- NORM: routine procedure, no penalty for travellers who follow instructions
- SENSITIVE: cultural or procedural sensitivity, could cause embarrassment or minor delays
- LEGAL: legal requirement with a potential fine, detention, or criminal penalty

Produce 5-7 steps ordered as a traveller would experience them (plane → exit arrivals hall).
If the scraped text is insufficient, use authoritative knowledge about this country's procedures.
""".strip()


# ── Helpers ────────────────────────────────────────────────────────────────────

def fetch_text(url: str) -> str:
    """Fetch a URL and return visible page text (stripped of tags)."""
    try:
        resp = requests.get(url, headers=HEADERS, timeout=15)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "html.parser")
        # Remove nav/footer noise
        for tag in soup(["nav", "footer", "script", "style", "noscript"]):
            tag.decompose()
        return soup.get_text(separator=" ", strip=True)[:8000]  # cap to 8k chars
    except Exception as exc:
        print(f"  WARNING: Could not fetch {url}: {exc}")
        return ""


def generate_steps_via_llm(country_name: str, raw_text: str) -> list[dict]:
    """Call GPT with scraped text and return a list of step dicts."""
    user_content = (
        f"Country: {country_name}\n\n"
        f"Scraped official source text (may be partial):\n{raw_text}\n\n"
        "Generate the arrival steps JSON array as instructed."
    )
    try:
        response = client.chat.completions.create(
            model="gpt-5-mini",
            messages=[
                {"role": "system", "content": GPT_SYSTEM_PROMPT},
                {"role": "user", "content": user_content},
            ],
            temperature=0.2,
            response_format={"type": "json_object"},
        )
        raw = response.choices[0].message.content
        parsed = json.loads(raw)
        # GPT sometimes wraps in {"steps": [...]}
        if isinstance(parsed, list):
            return parsed
        for key in ("steps", "arrivalSteps", "arrival_steps"):
            if key in parsed and isinstance(parsed[key], list):
                return parsed[key]
        print("  WARNING: Unexpected GPT response shape:", list(parsed.keys()))
        return []
    except Exception as exc:
        print(f"  ERROR: GPT call failed: {exc}")
        return []


def load_json(path: Path) -> dict:
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def save_json(path: Path, data: dict) -> None:
    # Backup original
    backup = path.with_suffix(".json.bak")
    if path.exists() and not backup.exists():
        backup.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def merge_steps(country_data: dict, new_steps: list[dict]) -> dict:
    """Replace arrivalSteps in the 'airport' scenario with new_steps."""
    if not new_steps:
        return country_data
    for scenario in country_data.get("scenarios", []):
        if scenario.get("id") == "airport":
            # Re-index to ensure stepIndex is sequential
            for i, step in enumerate(new_steps):
                step["stepIndex"] = i
            scenario["arrivalSteps"] = new_steps
            return country_data
    print("  WARNING: No 'airport' scenario found in JSON — steps not merged.")
    return country_data


# ── Main ───────────────────────────────────────────────────────────────────────

def process_country(code: str, meta: dict) -> None:
    json_path = ASSETS_DIR / f"{code.lower()}.json"
    if not json_path.exists():
        print(f"  SKIP: {json_path} not found.")
        return

    print(f"\n[{code}] {meta['name']}")

    # 1. Scrape all source URLs
    combined_text = ""
    for url in meta["urls"]:
        print(f"  Fetching: {url}")
        combined_text += fetch_text(url) + "\n"
        time.sleep(1)  # polite crawl delay

    # 2. Generate steps via LLM
    print(f"  Calling GPT for {meta['name']} arrival steps…")
    new_steps = generate_steps_via_llm(meta["name"], combined_text.strip())

    if not new_steps:
        print(f"  SKIP: No steps generated for {meta['name']}.")
        return

    print(f"  Generated {len(new_steps)} steps.")

    # 3. Merge and save
    country_data = load_json(json_path)
    updated = merge_steps(country_data, new_steps)
    save_json(json_path, updated)
    print(f"  Saved → {json_path}")


def main() -> None:
    if not ASSETS_DIR.exists():
        print(f"ERROR: Assets directory not found: {ASSETS_DIR}")
        sys.exit(1)

    codes = sys.argv[1:] if len(sys.argv) > 1 else list(SOURCES.keys())
    unknown = [c.upper() for c in codes if c.upper() not in SOURCES]
    if unknown:
        print(f"ERROR: Unknown country codes: {unknown}")
        print(f"Available: {list(SOURCES.keys())}")
        sys.exit(1)

    print(f"ArrivalRitual — Immigration Scraper")
    print(f"Assets dir: {ASSETS_DIR}")
    print(f"Countries:  {codes}")

    for code in codes:
        process_country(code.upper(), SOURCES[code.upper()])

    print("\nDone. Review changes with: git diff phone-app/app/src/main/assets/countries/")


if __name__ == "__main__":
    main()
