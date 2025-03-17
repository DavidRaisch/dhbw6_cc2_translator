import os
from flask import Flask, render_template, request, flash
from datetime import datetime
import requests
from pymongo import MongoClient

app = Flask(__name__)
# Sicherer Schlüssel (idealerweise per Umgebungsvariable FLASK_SECRET_KEY setzen)
app.secret_key = os.environ.get("FLASK_SECRET_KEY", "your_secret_key")

# MongoDB-Verbindung
connection_url = os.environ.get("MONGODB_CONNECTION_STRING")
if not connection_url:
    raise Exception("MONGODB_CONNECTION_STRING is not set!")
client = MongoClient(connection_url)
db = client.get_default_database()
translations_collection = db.translations

# DeepL API-Key
DEEPL_AUTH_KEY = os.environ.get("DEEPL_AUTH_KEY")
if not DEEPL_AUTH_KEY:
    raise Exception("DEEPL_AUTH_KEY is not set!")

DEEPL_API_URL = "https://api-free.deepl.com/v2"

def get_source_languages():
    """
    Ruft die von DeepL unterstützten Quellsprachen ab.
    """
    url = f"{DEEPL_API_URL}/languages"
    params = {
        "auth_key": DEEPL_AUTH_KEY,
        "type": "source"
    }
    response = requests.get(url, params=params)
    if response.status_code != 200:
        print("Fehler beim Abrufen der Quellsprachen:", response.status_code, response.text)
        return []
    return response.json()

def get_target_languages():
    """
    Ruft die von DeepL unterstützten Zielsprachen ab.
    """
    url = f"{DEEPL_API_URL}/languages"
    params = {
        "auth_key": DEEPL_AUTH_KEY,
        "type": "target"
    }
    response = requests.get(url, params=params)
    if response.status_code != 200:
        print("Fehler beim Abrufen der Zielsprachen:", response.status_code, response.text)
        return []
    return response.json()

def deepl_translate(text, target_lang="DE", source_lang=None):
    """
    Übersetzt den Text mithilfe der DeepL API.
    """
    url = f"{DEEPL_API_URL}/translate"
    params = {
        "auth_key": DEEPL_AUTH_KEY,
        "text": text,
        "target_lang": target_lang,
    }
    if source_lang and source_lang.lower() != "auto":
        params["source_lang"] = source_lang
    response = requests.post(url, data=params)
    if response.status_code != 200:
        print("Fehler beim Aufruf der DeepL API:", response.status_code, response.text)
        return None
    data = response.json()
    return data["translations"][0]["text"]

@app.route('/', methods=['GET', 'POST'])
def index():
    translation = None

    # Dynamisch abfragen: Quell- und Zielsprachen
    source_languages = [{"language": "auto", "name": "Auto Detect"}] + get_source_languages()
    target_languages = get_target_languages()

    # Aktuelle Auswahl (Standard: Quelle = "auto", Ziel = "DE")
    current_source_lang = request.form.get('source_lang', 'auto')
    current_target_lang = request.form.get('target_lang', 'DE')
    
    if request.method == 'POST':
        text = request.form.get('text')
        source_lang = current_source_lang
        target_lang = current_target_lang
        if not text:
            flash('Bitte geben Sie einen Text zum Übersetzen ein.')
        elif not target_lang:
            flash('Bitte wählen Sie eine Zielsprache.')
        else:
            # Überprüfe, ob bereits eine Übersetzung in der Datenbank vorliegt
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
                    flash("Übersetzung fehlgeschlagen. Bitte versuchen Sie es später erneut.")

    return render_template('index.html',
                           translation=translation,
                           source_languages=source_languages,
                           target_languages=target_languages,
                           current_source_lang=current_source_lang,
                           current_target_lang=current_target_lang)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')




#TODO: write comments to the entire project