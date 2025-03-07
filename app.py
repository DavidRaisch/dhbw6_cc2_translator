import os
from flask import Flask, render_template, request, flash
from datetime import datetime
import requests
from pymongo import MongoClient

app = Flask(__name__)
app.secret_key = 'your_secret_key'  # Replace with a secure value

# MongoDB connection string (use environment variable DATABASE_URL if set)
connection_url = os.environ.get(
    'DATABASE_URL',
    "mongodb+srv://davidraisch:2pqyRmoLzOQfqqo3@translator.lpyuz.mongodb.net/?retryWrites=true&w=majority&appName=translator"
)

# Connect to MongoDB
client = MongoClient(connection_url)
# Choose a database (change "translator" to your desired database name)
db = client["translator"]
# Use a collection named "translations"
translations_collection = db.translations

# DeepL API configuration
DEEPL_AUTH_KEY = os.environ.get("DEEPL_AUTH_KEY", "YOUR_DEEPL_AUTH_KEY")
DEEPL_API_URL = "https://api-free.deepl.com/v2/translate"

# Example list of supported languages
LANGUAGES = [
    ("auto", "Auto Detect"),
    ("BG", "Bulgarian"),
    ("CS", "Czech"),
    ("DA", "Danish"),
    ("DE", "German"),
    ("EL", "Greek"),
    ("EN-GB", "English (British)"),
    ("EN-US", "English (American)"),
    ("ES", "Spanish"),
    ("ET", "Estonian"),
    ("FI", "Finnish"),
    ("FR", "French"),
    ("HU", "Hungarian"),
    ("IT", "Italian"),
    ("JA", "Japanese"),
    ("LT", "Lithuanian"),
    ("LV", "Latvian"),
    ("NL", "Dutch"),
    ("PL", "Polish"),
    ("PT-PT", "Portuguese (European)"),
    ("PT-BR", "Portuguese (Brazilian)"),
    ("RO", "Romanian"),
    ("RU", "Russian"),
    ("SK", "Slovak"),
    ("SL", "Slovenian"),
    ("SV", "Swedish"),
    ("ZH", "Chinese")
]

def deepl_translate(text, target_lang="DE", source_lang=None):
    params = {
        "auth_key": DEEPL_AUTH_KEY,
        "text": text,
        "target_lang": target_lang,
    }
    if source_lang and source_lang.lower() != "auto":
        params["source_lang"] = source_lang
    response = requests.post(DEEPL_API_URL, data=params)
    if response.status_code != 200:
        print("Error calling DeepL API:", response.status_code, response.text)
        return None
    data = response.json()
    return data["translations"][0]["text"]

@app.route('/', methods=['GET', 'POST'])
def index():
    translation = None
    if request.method == 'POST':
        text = request.form.get('text')
        source_lang = request.form.get('source_lang')
        target_lang = request.form.get('target_lang')
        if not text:
            flash('Please enter text to translate.')
        elif not target_lang:
            flash('Please select a target language.')
        else:
            # Check if the translation already exists in the database
            existing = translations_collection.find_one({
                "text": text,
                "source_lang": source_lang,
                "target_lang": target_lang
            })
            if existing:
                translation = existing["translation"]
            else:
                translation = deepl_translate(text, target_lang, source_lang)
                if translation:
                    new_entry = {
                        "text": text,
                        "source_lang": source_lang,
                        "target_lang": target_lang,
                        "translation": translation,
                        "timestamp": datetime.utcnow()
                    }
                    translations_collection.insert_one(new_entry)
                else:
                    flash("Translation failed. Please try again later.")
    return render_template('index.html', translation=translation, languages=LANGUAGES)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
