from pathlib import Path

import pandas as pd
import joblib


BASE_DIR = Path(__file__).resolve().parents[2]

TOURISM_DATA_PATH = BASE_DIR / "data" / "Dataset_tourism.xlsx"
TRAINING_DATA_PATH = BASE_DIR / "data" / "package_training.xlsx"
PACKAGE_MODEL_PATH = BASE_DIR / "models" / "package_quality_model.joblib"


def load_tourism_data():
    """
    Loads the main tourism inventory dataset.
    This is the source of truth for all hotels, activities,
    restaurants, and nightlife items.
    """
    df = pd.read_excel(TOURISM_DATA_PATH)

    # Clean column names
    df.columns = df.columns.str.strip()

    # Clean text columns
    text_columns = [
        "country",
        "city",
        "type",
        "name",
        "category",
        "interest_tags",
        "item_budget_level",
    ]

    for col in text_columns:
        if col in df.columns:
            df[col] = df[col].fillna("").astype(str).str.strip()

    return df


def load_training_data():
    """
    Loads the package training dataset.
    This teaches the model what makes a package good or bad.
    """
    df = pd.read_excel(TRAINING_DATA_PATH)

    # Clean column names
    df.columns = df.columns.str.strip()

    # Clean text columns
    text_columns = [
        "country",
        "budget_level",
        "trip_style",
        "travelers",
        "interests",
        "selected_city",
        "selected_hotel",
        "selected_activities",
        "selected_restaurants",
        "reason",
    ]

    for col in text_columns:
        if col in df.columns:
            df[col] = df[col].fillna("").astype(str).str.strip()

    return df


def load_package_quality_model():
    """
    Loads the trained package quality model.
    This model predicts if a generated package is good or bad.
    """
    return joblib.load(PACKAGE_MODEL_PATH)
