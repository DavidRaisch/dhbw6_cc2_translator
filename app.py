import os
from flask import Flask, render_template, request, flash
from datetime import datetime
import requests
from pymongo import MongoClient

app = Flask(__name__)
# Preferably set FLASK_SECRET_KEY in your environment; otherwise, default to a placeholder (not recommended for production)
app.secret_key = os.environ.get("FLASK_SECRET_KEY", "your_secret_key")

# Get the MongoDB connection string from environment variables.
connection_url = os.environ.get("MONGODB_CONNECTION_STRING")
if not connection_url:
    raise Exception("MONGODB_CONNECTION_STRING is not set!")

# Connect to MongoDB. If a default database is configured in the connection string, use that.
client = MongoClient(connection_url)
db = client.get_default_database()  # Alternatively, specify a database name explicitly.
translations_collection = db.translations

# Get the DeepL API key from environment variables.
DEEPL_AUTH_KEY = os.environ.get("DEEPL_AUTH_KEY")
if not DEEPL_AUTH_KEY:
    raise Exception("DEEPL_AUTH_KEY is not set!")

DEEPL_API_URL = "https://api-free.deepl.com/v2/translate"

LANGUAGES = [
    ("auto", "Auto Detect"), ("BG", "Bulgarian"), ("CS", "Czech"), ("DA", "Danish"),
    ("DE", "German"), ("EL", "Greek"), ("EN", "English"),
    ("ES", "Spanish"), ("ET", "Estonian"), ("FI", "Finnish"), ("FR", "French"),
    ("HU", "Hungarian"), ("IT", "Italian"), ("JA", "Japanese"), ("LT", "Lithuanian"),
    ("LV", "Latvian"), ("NL", "Dutch"), ("PL", "Polish"),
    ("PT", "Portuguese"), ("RO", "Romanian"), ("RU", "Russian"), ("SK", "Slovak"),
    ("SL", "Slovenian"), ("SV", "Swedish"), ("ZH", "Chinese")
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
            # Check if a translation already exists in the database
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
                    translations_collection.insert_one({
                        "text": text,
                        "source_lang": source_lang,
                        "target_lang": target_lang,
                        "translation": translation,
                        "timestamp": datetime.utcnow()
                    })
                else:
                    flash("Translation failed. Please try again later.")
    return render_template('index.html', translation=translation, languages=LANGUAGES)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')



#TODO: make app nicer => two boxes for translation
#TODO: translation should stay until deleted => add Bootstrap-X to delete input
#TODO: write comments to the entire project
#TODO: use wsgi