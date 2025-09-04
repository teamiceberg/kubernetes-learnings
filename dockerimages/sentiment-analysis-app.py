from flask import Flask, request, jsonify
from transformers import pipeline

app = Flask(__name__)
nlp = pipeline("sentiment-analysis", model="distilbert-base-uncased", device=-1)

@app.route("/infer", methods=["POST"])
def infer():
    text = request.json["text"]
    result = nlp(text)
    return jsonify(result)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5080)