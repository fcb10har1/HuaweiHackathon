#!/usr/bin/env python3
"""
Translation Backend - Supports both OpenAI-based and fallback suggestions
Uses OpenAI Whisper to transcribe sample audio files in real time.
"""
import sys
import os
import base64
from flask import Flask, request, jsonify
from dotenv import load_dotenv
from pathlib import Path
from datetime import datetime

# Force UTF-8 stdout so Japanese/Thai/Indonesian chars don't crash on Windows
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
if sys.stderr.encoding != 'utf-8':
    sys.stderr.reconfigure(encoding='utf-8', errors='replace')

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)

# Store last suggestion audio for playback
LAST_SUGGESTION_AUDIOS = []

# Sample audio files live in the samples/ subfolder
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SAMPLES_DIR = os.path.join(SCRIPT_DIR, 'samples')
print(f"[Backend] Looking for sample audio files in: {SAMPLES_DIR}")

# Get NewRecordings folder path - save to C:\NewRecordings (outside OneDrive)
RECORDINGS_PATH = r"C:\NewRecordings"
if not os.path.exists(RECORDINGS_PATH):
    os.makedirs(RECORDINGS_PATH, exist_ok=True)
print(f"[Backend] Using recordings folder: {RECORDINGS_PATH}")

# Minimal valid WAV file (silence, 100ms @ 16kHz)
MINIMAL_WAV_BASE64 = "UklGRiYAAABXQVZFZm10IBAAAAABAAEAQB8AAAB9AAACABAAZGF0YQIAAAAAAA=="

# Hardcoded useful travel phrases shown in ConvoAssist.
# The frontend contract stays the same; only the backend phrase source changes.
USEFUL_PHRASE_SETS = {
    'ja': [
        {"local": "\u3053\u3093\u306b\u3061\u306f", "english": "Hello"},
        {"local": "\u3055\u3088\u3046\u306a\u3089", "english": "Goodbye"},
        {"local": "\u304a\u9858\u3044\u3057\u307e\u3059", "english": "Please"},
        {"local": "\u3042\u308a\u304c\u3068\u3046\u3054\u3056\u3044\u307e\u3059", "english": "Thank you"},
        {"local": "\u306f\u3044", "english": "Yes"},
        {"local": "\u3044\u3044\u3048", "english": "No"},
        {"local": "\u3059\u307f\u307e\u305b\u3093", "english": "Excuse me"},
        {"local": "\u7533\u3057\u8a33\u3042\u308a\u307e\u305b\u3093", "english": "Sorry"},
        {"local": "\u82f1\u8a9e\u3092\u8a71\u305b\u307e\u3059\u304b\uff1f", "english": "Do you speak English?"},
        {"local": "\u304a\u624b\u6d17\u3044\u306f\u3069\u3053\u3067\u3059\u304b\uff1f", "english": "Where is the bathroom?"},
        {"local": "\u3044\u304f\u3089\u3067\u3059\u304b\uff1f", "english": "How much does this cost?"},
        {"local": "\u301c\u3092\u304a\u9858\u3044\u3057\u307e\u3059", "english": "I would like..."},
        {"local": "\u52a9\u3051\u3066\uff01", "english": "Help!"},
        {"local": "\u308f\u304b\u308a\u307e\u305b\u3093", "english": "I don't understand"},
        {"local": "\u65e5\u672c\u8a9e\u3092\u8a71\u305b\u307e\u305b\u3093", "english": "I don't speak Japanese"},
    ],
    'th': [
        {"local": "\u0e2a\u0e27\u0e31\u0e2a\u0e14\u0e35", "english": "Hello"},
        {"local": "\u0e25\u0e32\u0e01\u0e48\u0e2d\u0e19", "english": "Goodbye"},
        {"local": "\u0e01\u0e23\u0e38\u0e13\u0e32", "english": "Please"},
        {"local": "\u0e02\u0e2d\u0e1a\u0e04\u0e38\u0e13", "english": "Thank you"},
        {"local": "\u0e43\u0e0a\u0e48", "english": "Yes"},
        {"local": "\u0e44\u0e21\u0e48", "english": "No"},
        {"local": "\u0e02\u0e2d\u0e42\u0e17\u0e29", "english": "Excuse me"},
        {"local": "\u0e02\u0e2d\u0e42\u0e17\u0e29", "english": "Sorry"},
        {"local": "\u0e04\u0e38\u0e13\u0e1e\u0e39\u0e14\u0e20\u0e32\u0e29\u0e32\u0e2d\u0e31\u0e07\u0e01\u0e24\u0e29\u0e44\u0e14\u0e49\u0e44\u0e2b\u0e21", "english": "Do you speak English?"},
        {"local": "\u0e2b\u0e49\u0e2d\u0e07\u0e19\u0e49\u0e33\u0e2d\u0e22\u0e39\u0e48\u0e17\u0e35\u0e48\u0e44\u0e2b\u0e19", "english": "Where is the bathroom?"},
        {"local": "\u0e2d\u0e31\u0e19\u0e19\u0e35\u0e49\u0e23\u0e32\u0e04\u0e32\u0e40\u0e17\u0e48\u0e32\u0e44\u0e2b\u0e23\u0e48", "english": "How much does this cost?"},
        {"local": "\u0e09\u0e31\u0e19\u0e15\u0e49\u0e2d\u0e07\u0e01\u0e32\u0e23...", "english": "I would like..."},
        {"local": "\u0e0a\u0e48\u0e27\u0e22\u0e14\u0e49\u0e27\u0e22!", "english": "Help!"},
        {"local": "\u0e09\u0e31\u0e19\u0e44\u0e21\u0e48\u0e40\u0e02\u0e49\u0e32\u0e43\u0e08", "english": "I don't understand"},
        {"local": "\u0e09\u0e31\u0e19\u0e1e\u0e39\u0e14\u0e20\u0e32\u0e29\u0e32\u0e44\u0e17\u0e22\u0e44\u0e21\u0e48\u0e44\u0e14\u0e49", "english": "I don't speak Thai"},
    ],
    'id': [
        {"local": "Halo", "english": "Hello"},
        {"local": "Selamat tinggal", "english": "Goodbye"},
        {"local": "Tolong", "english": "Please"},
        {"local": "Terima kasih", "english": "Thank you"},
        {"local": "Ya", "english": "Yes"},
        {"local": "Tidak", "english": "No"},
        {"local": "Permisi", "english": "Excuse me"},
        {"local": "Maaf", "english": "Sorry"},
        {"local": "Apakah Anda bisa berbahasa Inggris?", "english": "Do you speak English?"},
        {"local": "Di mana kamar mandi?", "english": "Where is the bathroom?"},
        {"local": "Berapa harganya?", "english": "How much does this cost?"},
        {"local": "Saya mau...", "english": "I would like..."},
        {"local": "Tolong!", "english": "Help!"},
        {"local": "Saya tidak mengerti", "english": "I don't understand"},
        {"local": "Saya tidak bisa berbahasa Indonesia", "english": "I don't speak Indonesian"},
    ],
}

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
        print("[Backend] [OK] OpenAI API key loaded")
    else:
        print("[Backend] [WARN] OPENAI_API_KEY environment variable not set - will use fallback suggestions")
        OPENAI_AVAILABLE = False
except ImportError:
    print("[Backend] [WARN] OpenAI module not installed - will use fallback suggestions")
    OPENAI_AVAILABLE = False

def generate_tts_audio(text, language_code='ja'):
    """
    Generate TTS audio for a phrase using OpenAI's TTS API.
    Returns base64-encoded MP3 audio.
    """
    if not OPENAI_API_KEY:
        return None
    
    try:
        from openai import OpenAI
        client = OpenAI(api_key=OPENAI_API_KEY)
        
        print(f"[Backend] Generating TTS for: {text}")
        response = client.audio.speech.create(
            model="tts-1",
            voice="nova",  # Natural sounding voice
            input=text,
            response_format="mp3"
        )
        
        # Convert to base64
        audio_base64 = base64.b64encode(response.content).decode('utf-8')
        return f"data:audio/mpeg;base64,{audio_base64}"
    except Exception as e:
        print(f"[Backend] TTS generation failed: {e}")
        return None


def transcribe_audio(filename):
    """
    Transcribe a sample audio file using OpenAI Whisper.
    Looks for the file in the same directory as this script.
    Returns (transcript, language_code) or (None, None) on failure.
    """
    if not OPENAI_API_KEY:
        print(f"[Backend] No API key - cannot transcribe, using fallback transcript")
        return None, None

    filepath = os.path.join(SAMPLES_DIR, filename)
    if not os.path.exists(filepath):
        print(f"[Backend] [WARN] Audio file not found: {filepath}")
        return None, None

    try:
        from openai import OpenAI
        client = OpenAI(api_key=OPENAI_API_KEY)
        print(f"[Backend] [MIC] Transcribing with Whisper: {filepath}")
        with open(filepath, 'rb') as f:
            result = client.audio.transcriptions.create(
                model="whisper-1",
                file=f,
            )
        transcript = result.text.strip()
        language = result.language if hasattr(result, 'language') else None
        print(f"[Backend] [OK] Whisper transcript: {transcript} (detected language: {language})")
        return transcript, language
    except Exception as e:
        print(f"[Backend] [ERR] Whisper transcription failed: {e}")
        return None, None


def get_ai_suggestions(transcript, language_code, target_language):
    """
    Return a fixed set of useful travel phrases for the target language.
    This keeps ConvoAssist consistent across demos and countries.
    """
    phrase_set = USEFUL_PHRASE_SETS.get(language_code, USEFUL_PHRASE_SETS['ja'])
    suggestions = [phrase["local"] for phrase in phrase_set]
    translations = [phrase["english"] for phrase in phrase_set]

    print(f"[Backend] [OK] Using {len(suggestions)} hardcoded useful phrases for {target_language}")
    for s, t in zip(suggestions, translations):
        print(f"[Backend]   {s}  ->  {t}")
    return suggestions, translations


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
    print(f"\n[Backend]  Processing translation request")
    print(f"[Backend] Filename: {filename}")

    # Determine language from filename (used as fallback if Whisper fails)
    if 'thai' in filename.lower() or 'th' in filename.lower():
        language_code = 'th'
        language_name = 'Thai'
        fallback_transcript = 'สวัสดีค่ะ คุณพูดภาษาอังกฤษได้ไหมค่ะ'
        fallback_translation = 'Hello, do you speak English?'
    elif 'indo' in filename.lower() or 'id' in filename.lower():
        language_code = 'id'
        language_name = 'Indonesian'
        fallback_transcript = 'Halo, bisakah Anda berbicara bahasa Inggris?'
        fallback_translation = 'Hello, can you speak English?'
    else:  # Japanese
        language_code = 'ja'
        language_name = 'Japanese'
        fallback_transcript = 'こんにちは、あなたはどこの出身ですか？'
        fallback_translation = 'Hi, where are you from?'

    # Try real Whisper transcription first
    whisper_transcript, _ = transcribe_audio(filename)
    if whisper_transcript:
        transcript = whisper_transcript
        # Translate the real transcript to English using GPT
        try:
            from openai import OpenAI
            client = OpenAI(api_key=OPENAI_API_KEY)
            trans_resp = client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[{"role": "user", "content": f"Translate this {language_name} text to English. Return ONLY the translation:\n{transcript}"}],
                temperature=0.3,
                max_tokens=100
            )
            translation = trans_resp.choices[0].message.content.strip()
            print(f"[Backend] [OK] Translation: {translation}")
        except Exception as e:
            print(f"[Backend] [WARN] Translation failed, using fallback: {e}")
            translation = fallback_translation
    else:
        print(f"[Backend] Using fallback transcript for demo")
        transcript = fallback_transcript
        translation = fallback_translation
    
    # Get suggestions (AI-powered or fallback)
    print(f"[Backend] Getting {language_name} suggestions...")
    suggestions, translations = get_ai_suggestions(transcript, language_code, language_name)
    print(f"[Backend] Suggestions count: {len(suggestions)}")
    print(f"[Backend] Translations count: {len(translations)}")
    
    # Generate TTS audio for each suggestion
    print(f"[Backend] Generating TTS audio for {len(suggestions)} suggestions...")
    suggestion_audios = []
    for i, suggestion in enumerate(suggestions):
        audio = generate_tts_audio(suggestion, language_code)
        if audio:
            suggestion_audios.append(audio)
            print(f"[Backend] [OK] TTS generated for suggestion {i+1}")
        else:
            suggestion_audios.append(f'data:audio/wav;base64,{MINIMAL_WAV_BASE64}')
            print(f"[Backend] [WARN] TTS failed for suggestion {i+1}, using fallback")
    
    # Create response with BOTH text suggestions AND audio AND translations
    # NOTE: Always use 'replySuggestionsJapanese' key for app compatibility (app expects this exact key)
    response = {
        'sourceLanguage': language_code,
        'transcript': transcript,
        'translationEnglish': translation,
        'replySuggestionsJapanese': suggestions,  # Use consistent key name for app
        'suggestionTranslations': translations,  # English translations for each suggestion
        'ttsAudioUrl': f'data:audio/wav;base64,{MINIMAL_WAV_BASE64}',
        'suggestionAudios': suggestion_audios  # Real TTS audio for each suggestion
    }
    
    # Store audios globally for later playback
    global LAST_SUGGESTION_AUDIOS
    LAST_SUGGESTION_AUDIOS = suggestion_audios
    
    print(f"[Backend] [OK] Response ready")
    return jsonify(response)


@app.route('/api/save-audio/<int:index>', methods=['POST'])
def save_audio(index):
    """
    Save suggestion audio to Desktop for playback.
    Called when user presses Play Audio button on watch.
    """
    global LAST_SUGGESTION_AUDIOS
    
    print(f"[Backend] [DEBUG] save_audio called with index={index}, audios count={len(LAST_SUGGESTION_AUDIOS)}")
    
    if not LAST_SUGGESTION_AUDIOS or index >= len(LAST_SUGGESTION_AUDIOS):
        print(f"[Backend] [WARN] Audio not found: index={index}, count={len(LAST_SUGGESTION_AUDIOS)}")
        return jsonify({'error': 'Audio not found', 'status': 'failed', 'debug': {'index': index, 'count': len(LAST_SUGGESTION_AUDIOS)}}), 404
    
    audio_base64_uri = LAST_SUGGESTION_AUDIOS[index]
    
    try:
        # Extract base64 data from URI
        if 'base64,' in audio_base64_uri:
            base64_data = audio_base64_uri.split('base64,')[1]
            # Determine file format
            if 'audio/mpeg' in audio_base64_uri:
                ext = 'mp3'
            else:
                ext = 'wav'
        else:
            print(f"[Backend] [WARN] Invalid audio format for index={index}")
            return jsonify({'error': 'Invalid audio format'}), 400
        
        # Ensure NewRecordings directory exists
        if not os.path.exists(RECORDINGS_PATH):
            print(f"[Backend] [WARN] Recordings path does not exist: {RECORDINGS_PATH}")
            return jsonify({'error': f'Recordings path not found: {RECORDINGS_PATH}', 'status': 'failed'}), 500
        
        # Decode and save to NewRecordings
        audio_bytes = base64.b64decode(base64_data)
        timestamp = datetime.now().strftime('%H%M%S')
        filename = f"suggestion_{index+1}_{timestamp}.{ext}"
        filepath = os.path.join(RECORDINGS_PATH, filename)
        
        print(f"[Backend] [DEBUG] Writing {len(audio_bytes)} bytes to {filepath}")
        with open(filepath, 'wb') as f:
            f.write(audio_bytes)
        
        print(f"[Backend] [OK] Audio saved to: {filepath}")
        return jsonify({
            'status': 'success',
            'file': filename,
            'path': filepath,
            'size': len(audio_bytes)
        }), 200
    
    except Exception as e:
        import traceback
        print(f"[Backend] [WARN] Failed to save audio: {e}")
        print(f"[Backend] [STACKTRACE] {traceback.format_exc()}")
        return jsonify({'error': str(e), 'status': 'failed', 'debug': {'exception': str(type(e).__name__)}}), 500


if __name__ == '__main__':
    print("[Backend] Starting server on port 5000...")
    print(f"[Backend] OpenAI Support: {OPENAI_AVAILABLE and bool(OPENAI_API_KEY)}")
    app.run(host='0.0.0.0', port=5000, debug=False)
