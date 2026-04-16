#!/usr/bin/env python3
"""
Translation Backend - Supports both OpenAI-based and fallback suggestions
Uses OpenAI Whisper to transcribe sample audio files in real time.
"""
import os
import base64
from flask import Flask, request, jsonify
from dotenv import load_dotenv
from pathlib import Path
from datetime import datetime

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)

# Store last suggestion audio for playback
LAST_SUGGESTION_AUDIOS = []

# Sample audio files live in the same folder as this script
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
print(f"[Backend] Looking for sample audio files in: {SCRIPT_DIR}")

# Get NewRecordings folder path - save to C:\NewRecordings (outside OneDrive)
RECORDINGS_PATH = r"C:\NewRecordings"
if not os.path.exists(RECORDINGS_PATH):
    os.makedirs(RECORDINGS_PATH, exist_ok=True)
print(f"[Backend] Using recordings folder: {RECORDINGS_PATH}")

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

    filepath = os.path.join(SCRIPT_DIR, filename)
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
    Generate AI-powered suggestions using OpenAI or return fallback.
    """
    if not OPENAI_API_KEY:
        print(f"[Backend] No API key - using fallback")
        return SUGGESTION_REPLIES.get(language_code, SUGGESTION_REPLIES['ja']), ['I am from Japan', 'America', 'India']
    
    try:
        print(f"[Backend] [AI] Calling OpenAI for {target_language}...")
        from openai import OpenAI
        
        client = OpenAI(api_key=OPENAI_API_KEY)
        
        # Generate suggestions RELEVANT to what the user asked
        prompt = f"A traveler said in {target_language}: \"{transcript}\"\n\nGenerate 3 polite and relevant {target_language} responses to this. Return ONLY a JSON array like [\"response1\", \"response2\", \"response3\"]"
        
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
            print(f"[Backend] [OK] Using AI suggestions: {suggestions[:3]}")
            
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
        print(f"[Backend] [ERR] OpenAI error: {type(e).__name__}: {str(e)}")
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
    print(f"[Backend] Suggestions: {suggestions}")
    print(f"[Backend] Translations: {translations}")
    
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
