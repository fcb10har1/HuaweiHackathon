#!/usr/bin/env python3
"""
Translation Backend - Supports both OpenAI-based and fallback suggestions
"""
import os
import base64
from flask import Flask, request, jsonify
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)

# Minimal valid WAV file (silence, 100ms @ 16kHz)
MINIMAL_WAV_BASE64 = "UklGRiYAAABXQVZFZm10IBAAAAABAAEAQB8AAAB9AAACABAAZGF0YQIAAAAAAA=="

# Hardcoded suggestion replies (fallback when no OpenAI key)
SUGGESTION_REPLIES = {
    'ja': [
        'ありがとうございます',
        ' すみません、わかりません',
        'もう一度言ってもらえますか'
    ],
    'th': [
        'ขอบคุณค่ะ',
        'ขออภัยค่ะ ไม่เข้าใจ',
        'พูดซ้ำให้ฉันฟังหน่อยได้ไหมค่ะ'
    ],
    'id': [
        'Terima kasih',
        'Maaf, saya tidak mengerti',
        'Bisakah Anda mengulanginya?'
    ]
}

try:
    import openai
    OPENAI_AVAILABLE = True
    OPENAI_API_KEY = os.getenv('OPENAI_API_KEY', '')
    if OPENAI_API_KEY:
        print(f"[Backend] ✓ OpenAI API key loaded")
    else:
        print("[Backend] ⚠ OPENAI_API_KEY environment variable not set - will use fallback suggestions")
        OPENAI_AVAILABLE = False
except ImportError:
    print("[Backend] ⚠ OpenAI module not installed - will use fallback suggestions")
    OPENAI_AVAILABLE = False

def get_ai_suggestions(transcript, language_code, target_language):
    """
    Generate AI-powered suggestions using OpenAI or return fallback.
    """
    if not OPENAI_API_KEY:
        print(f"[Backend] No API key - using fallback")
        return SUGGESTION_REPLIES.get(language_code, SUGGESTION_REPLIES['ja']), ['I am from Japan', 'America', 'India']
    
    try:
        print(f"[Backend] 🤖 Calling OpenAI for {target_language}...")
        from openai import OpenAI
        
        client = OpenAI(api_key=OPENAI_API_KEY)
        
        prompt = f"Generate 3 polite {target_language} phrases for a traveler. Return ONLY a JSON array like [\"phrase1\", \"phrase2\", \"phrase3\"]"
        
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7,
            max_tokens=150
        )
        
        reply_text = response.choices[0].message.content.strip()
        print(f"[Backend] OpenAI returned: {reply_text}")
        
        # Parse JSON
        import json
        suggestions = json.loads(reply_text)
        if isinstance(suggestions, list) and len(suggestions) >= 3:
            print(f"[Backend] ✓ Using AI suggestions: {suggestions[:3]}")
            
            # Now translate each suggestion to English
            print(f"[Backend] Translating suggestions to English...")
            translations = []
            for suggestion in suggestions[:3]:
                try:
                    trans_response = client.chat.completions.create(
                        model="gpt-3.5-turbo",
                        messages=[{"role": "user", "content": f"Translate this {target_language} phrase to English. Return ONLY the translation, nothing else:\n{suggestion}"}],
                        temperature=0.3,
                        max_tokens=50
                    )
                    translation = trans_response.choices[0].message.content.strip()
                    translations.append(translation)
                    print(f"[Backend]   {suggestion} → {translation}")
                except Exception as e:
                    print(f"[Backend]   Translation failed: {e}")
                    translations.append("")
            
            return suggestions[:3], translations
        else:
            print(f"[Backend] Invalid format, using fallback")
            return SUGGESTION_REPLIES.get(language_code, SUGGESTION_REPLIES['ja']), ['I am from Japan', 'America', 'India']
        
    except Exception as e:
        print(f"[Backend] ❌ OpenAI error: {type(e).__name__}: {str(e)}")
        print(f"[Backend] Falling back to hardcoded suggestions")
        return SUGGESTION_REPLIES.get(language_code, SUGGESTION_REPLIES['ja']), ['I am from Japan', 'America', 'India']


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'ok', 'openai': OPENAI_AVAILABLE and bool(OPENAI_API_KEY)})


@app.route('/api/translate', methods=['POST'])
def translate():
    """
    Translate audio from filename query parameter.
    Returns: {
        sourceLanguage, transcript, translationEnglish,
        replySuggestionsJapanese (or Thai/Indonesian based on filename),
        ttsAudioUrl, suggestionAudios
    }
    """
    filename = request.args.get('filename', 'japanese_sample.wav')
    print(f"\n[Backend] 🌐 Processing translation request")
    print(f"[Backend] Filename: {filename}")
    
    # Determine language from filename
    if 'thai' in filename.lower() or 'th' in filename.lower():
        language_code = 'th'
        language_name = 'Thai'
        transcript = 'สวัสดีค่ะ คุณพูดภาษาอังกฤษได้ไหมค่ะ'
        translation = 'Hello, do you speak English?'
    elif 'indo' in filename.lower() or 'id' in filename.lower():
        language_code = 'id'
        language_name = 'Indonesian'
        transcript = 'Halo, bisakah Anda berbicara bahasa Inggris?'
        translation = 'Hello, can you speak English?'
    else:  # Japanese
        language_code = 'ja'
        language_name = 'Japanese'
        transcript = 'こんにちは、あなたはどこの出身ですか？'
        translation = 'Hi, where are you from?'
    
    # Get suggestions (AI-powered or fallback)
    print(f"[Backend] Getting {language_name} suggestions...")
    suggestions, translations = get_ai_suggestions(transcript, language_code, language_name)
    print(f"[Backend] Suggestions: {suggestions}")
    print(f"[Backend] Translations: {translations}")
    
    # Create response with BOTH text suggestions AND audio AND translations
    # NOTE: Always use 'replySuggestionsJapanese' key for app compatibility (app expects this exact key)
    response = {
        'sourceLanguage': language_code,
        'transcript': transcript,
        'translationEnglish': translation,
        'replySuggestionsJapanese': suggestions,  # Use consistent key name for app
        'suggestionTranslations': translations,  # English translations for each suggestion
        'ttsAudioUrl': f'data:audio/wav;base64,{MINIMAL_WAV_BASE64}',
        'suggestionAudios': [
            f'data:audio/wav;base64,{MINIMAL_WAV_BASE64}',
            f'data:audio/wav;base64,{MINIMAL_WAV_BASE64}',
            f'data:audio/wav;base64,{MINIMAL_WAV_BASE64}'
        ]
    }
    
    print(f"[Backend] ✓ Response ready")
    return jsonify(response)


if __name__ == '__main__':
    print("[Backend] Starting server on port 5000...")
    print(f"[Backend] OpenAI Support: {OPENAI_AVAILABLE and bool(OPENAI_API_KEY)}")
    app.run(host='0.0.0.0', port=5000, debug=False)
