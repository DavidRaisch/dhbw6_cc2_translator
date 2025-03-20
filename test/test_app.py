import sys
import os

# Add the project root to sys.path.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from dotenv import load_dotenv
# Load env variables from the testenv file in the project root.
load_dotenv(os.path.join(os.path.dirname(__file__), '..', 'testenv'))

import pytest
from datetime import datetime
from app import app, get_source_languages, get_target_languages, deepl_translate, translations_collection


# A fake translations collection to simulate database operations.
class FakeTranslationsCollection:
    def __init__(self):
        self.data = []

    def find_one(self, query):
        for doc in self.data:
            if (doc.get("text") == query.get("text") and 
                doc.get("source_lang") == query.get("source_lang") and 
                doc.get("target_lang") == query.get("target_lang")):
                return doc
        return None

    def insert_one(self, document):
        self.data.append(document)

# A fake response class to simulate requests responses.
class FakeResponse:
    def __init__(self, status_code, json_data=None, text=""):
        self.status_code = status_code
        self._json = json_data
        self.text = text

    def json(self):
        return self._json

# Test class for the DeepL Translator App.
class TestDeepLTranslatorApp:

    @pytest.fixture(autouse=True)
    def setup_environment(self, monkeypatch):
        # Replace the real translations_collection with our fake version.
        fake_collection = FakeTranslationsCollection()
        monkeypatch.setattr("app.translations_collection", fake_collection)
        self.fake_db = fake_collection

        # Patch the language retrieval functions to return static values.
        monkeypatch.setattr("app.get_source_languages", lambda: [{"language": "EN", "name": "English"}])
        monkeypatch.setattr("app.get_target_languages", lambda: [{"language": "DE", "name": "German"}])

        # Enable testing mode and create a test client.
        app.config["TESTING"] = True
        self.client = app.test_client()

    def test_get_index(self):
        response = self.client.get("/")
        assert response.status_code == 200
        data = response.get_data(as_text=True)
        # Check for key content and language options (note that "Auto Detect" is prepended)
        assert "DeepL Translator App" in data
        assert "Auto Detect" in data
        assert "English" in data
        assert "German" in data

    def test_post_no_text(self):
        response = self.client.post(
            "/",
            data={"text": "", "source_lang": "auto", "target_lang": "DE"},
            follow_redirects=True
        )
        data = response.get_data(as_text=True)
        assert "Bitte geben Sie einen Text zum Übersetzen ein." in data

    def test_post_missing_target(self):
        response = self.client.post(
            "/",
            data={"text": "Hello", "source_lang": "auto", "target_lang": ""},
            follow_redirects=True
        )
        data = response.get_data(as_text=True)
        assert "Bitte wählen Sie eine Zielsprache." in data

    def test_post_translation_new(self, monkeypatch):
        # Simulate a successful call to deepl_translate (translation not cached)
        monkeypatch.setattr("app.deepl_translate", lambda text, target_lang="DE", source_lang=None: "Hallo")
        response = self.client.post(
            "/",
            data={"text": "Hello", "source_lang": "auto", "target_lang": "DE"},
            follow_redirects=True
        )
        data = response.get_data(as_text=True)
        # The translated text should appear in the response.
        assert "Hallo" in data
        # Verify that the translation was stored in the fake DB.
        cached = self.fake_db.find_one({"text": "Hello", "source_lang": "auto", "target_lang": "DE"})
        assert cached is not None
        assert cached["translation"] == "Hallo"

    def test_post_translation_cached(self, monkeypatch):
        # Pre-populate the fake DB with a cached translation.
        cached_translation = {
            "text": "Hello",
            "source_lang": "auto",
            "target_lang": "DE",
            "translation": "Hallo Cached",
            "timestamp": datetime.utcnow()
        }
        self.fake_db.insert_one(cached_translation)
        # Patch deepl_translate to raise an exception if called (it should not be called for cached input).
        monkeypatch.setattr(
            "app.deepl_translate",
            lambda text, target_lang="DE", source_lang=None: (_ for _ in ()).throw(Exception("deepl_translate should not be called"))
        )
        response = self.client.post(
            "/",
            data={"text": "Hello", "source_lang": "auto", "target_lang": "DE"},
            follow_redirects=True
        )
        data = response.get_data(as_text=True)
        assert "Hallo Cached" in data

    def test_post_translation_fail(self, monkeypatch):
        # Simulate a failure in deepl_translate (returns None).
        def fake_translate_fail(text, target_lang="DE", source_lang=None):
            return None
        monkeypatch.setattr("app.deepl_translate", fake_translate_fail)
        response = self.client.post(
            "/",
            data={"text": "Hello", "source_lang": "auto", "target_lang": "DE"},
            follow_redirects=True
        )
        data = response.get_data(as_text=True)
        # Check that the proper error flash message is shown.
        assert "Übersetzung fehlgeschlagen. Bitte versuchen Sie es später erneut." in data

    def test_get_source_languages_success(self, monkeypatch):
        # Simulate a successful GET request for source languages.
        def fake_get(url, params):
            return FakeResponse(200, json_data=[{"language": "EN", "name": "English"}])
        monkeypatch.setattr("app.requests.get", fake_get)
        langs = get_source_languages()
        assert langs == [{"language": "EN", "name": "English"}]

    def test_get_source_languages_error(self, monkeypatch):
        # Simulate an error when calling the source languages API.
        def fake_get(url, params):
            return FakeResponse(400, text="error")
        monkeypatch.setattr("app.requests.get", fake_get)
        langs = get_source_languages()
        assert langs == []

    def test_get_target_languages_success(self, monkeypatch):
        # Simulate a successful GET request for target languages.
        def fake_get(url, params):
            return FakeResponse(200, json_data=[{"language": "DE", "name": "German"}])
        monkeypatch.setattr("app.requests.get", fake_get)
        langs = get_target_languages()
        assert langs == [{"language": "DE", "name": "German"}]

    def test_get_target_languages_error(self, monkeypatch):
        # Simulate an error when calling the target languages API.
        def fake_get(url, params):
            return FakeResponse(400, text="error")
        monkeypatch.setattr("app.requests.get", fake_get)
        langs = get_target_languages()
        assert langs == []

    def test_deepl_translate_success(self, monkeypatch):
        # Simulate a successful POST request to the DeepL translate API.
        def fake_post(url, data):
            return FakeResponse(200, json_data={"translations": [{"text": "Hallo"}]})
        monkeypatch.setattr("app.requests.post", fake_post)
        result = deepl_translate("Hello", "DE", "auto")
        assert result == "Hallo"

    def test_deepl_translate_error(self, monkeypatch):
        # Simulate an error response from the DeepL translate API.
        def fake_post(url, data):
            return FakeResponse(400, text="error")
        monkeypatch.setattr("app.requests.post", fake_post)
        result = deepl_translate("Hello", "DE", "auto")
        assert result is None
