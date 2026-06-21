from fastapi import FastAPI
import pandas as pd
import mlflow
import mlflow.xgboost
from pydantic import BaseModel
from transformers import pipeline

#Le indicamos a mlflow donde esta el db

mlflow.set_tracking_uri(
    "sqlite:///C:/Users/enriq/Downloads/mlops-llmops-main/mlops-llmops-main/mlflow.db"
)
#Cargamos el modelo desde mlflow usando la id de la run 1
modelo = mlflow.xgboost.load_model(
    "runs:/e1da54b88c5c48e88c94b27a8ca44e80/model"
)


app = FastAPI()
@app.get('/')
def home():
    return {'mensaje':'Bienvenido'}

@app.get('/health')
def health():
    return {'status':'OK',
            'mensaje':'La API funciona correctamente'}
@app.get("/model-info")
def model_info():
    return {
        "model": "XGBoost Classifier",
        "framework": "XGBoost",
        "problem_type": "Multiclass Classification",
        "classes": 3,
        "features": [
            "alcohol",
            "malic_acid",
            "ash",
            "alcalinity_of_ash",
            "magnesium",
            "total_phenols",
            "flavanoids",
            "nonflavanoid_phenols",
            "proanthocyanins",
            "color_intensity",
            "hue",
            "od280_od315",
            "proline"
        ]
    }

class WineFeatures(BaseModel):
    """
    Modelo de entrada que define las características químicas del vino
    necesarias para realizar una predicción con el modelo XGBoost.
    """
    alcohol: float
    malic_acid: float
    ash: float
    alcalinity_of_ash: float
    magnesium: float
    total_phenols: float
    flavanoids: float
    nonflavanoid_phenols: float
    proanthocyanins: float
    color_intensity: float
    hue: float
    od280_od315: float
    proline: float


@app.post("/predict")
def predict(features: WineFeatures):
    data = pd.DataFrame([features.model_dump()])
    prediction = modelo.predict(data)

    return {
        "prediction": int(prediction[0])
    }

#Cargamos modelo de clasificación de sentimiento
sentiment_model = pipeline(
    "sentiment-analysis"
)
@app.get("/sentiment")
def sentiment(text: str):

    result = sentiment_model(text)

    return {
        "text": text,
        "result": result
    }
#Modelo generador de texto

generator = pipeline("text-generation")

@app.get("/generate")
def generate(prompt: str):

    result = generator(
        prompt,
        max_new_tokens=50
    )

    return result