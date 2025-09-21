import os
import pandas as pd
from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import JSONResponse
import uvicorn

# -----------------------------
# CSV folder path
# -----------------------------
CSV_FOLDER = os.path.join(os.path.dirname(__file__), "data")

dataframes = {}
metadata_store = {}

# -----------------------------
# Helper functions
# -----------------------------
def normalize_key(file_path):
    """Convert CSV filename to dataset key."""
    fname = os.path.splitext(os.path.basename(file_path))[0]
    key = fname.lower().replace(' ', '').replace('-', '').replace('(', '').replace(')', '')
    return key

def load_csv_files_from_folder(folder_path):
    """Load all CSV files in the folder into memory."""
    global dataframes, metadata_store
    dataframes.clear()
    metadata_store.clear()

    for file_name in os.listdir(folder_path):
        if file_name.lower().endswith(".csv"):
            path = os.path.join(folder_path, file_name)
            try:
                # Read CSV
                df = pd.read_csv(path, parse_dates=["Data Time"])
                df.columns = [col.strip() for col in df.columns]
                # Keep only rows with valid data
                df = df[df["Data Time"].notna() & df["Data Value"].notna()].copy()
                df.reset_index(drop=True, inplace=True)

                # Save dataframe
                key = normalize_key(path)
                dataframes[key] = df

                # Save metadata
                meta_cols = ["Metadata", "Download Date", "Period", "Data Source"]
                meta = {}
                for col in meta_cols:
                    if col in df.columns:
                        meta[col] = str(df[col].iloc[0])
                metadata_store[key] = meta

                print(f"✅ Loaded dataset '{key}' with {len(df)} records")
            except Exception as e:
                print(f"❌ Error loading '{file_name}': {e}")

# Load all CSVs at startup
load_csv_files_from_folder(CSV_FOLDER)

# -----------------------------
# FastAPI app
# -----------------------------
app = FastAPI(title="Groundwater Data API")

@app.get("/datasets", summary="List available datasets")
def list_datasets():
    return list(dataframes.keys())

@app.get("/data/{dataset_name}", summary="Get records from dataset")
def get_data(dataset_name: str, limit: int = Query(100, ge=1, le=1000), offset: int = Query(0, ge=0)):
    key = dataset_name.lower()
    if key not in dataframes:
        raise HTTPException(status_code=404, detail=f"Dataset '{dataset_name}' not found")
    df = dataframes[key]
    slice_df = df.iloc[offset: offset + limit]
    return slice_df.to_dict(orient="records")

@app.get("/data/{dataset_name}/date/{date_str}", summary="Get records by date YYYY-MM-DD")
def get_data_by_date(dataset_name: str, date_str: str):
    key = dataset_name.lower()
    if key not in dataframes:
        raise HTTPException(status_code=404, detail=f"Dataset '{dataset_name}' not found")
    df = dataframes[key]
    try:
        date = pd.to_datetime(date_str).normalize()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD.")
    filtered = df[df["Data Time"].dt.normalize() == date]
    if filtered.empty:
        return JSONResponse(
            status_code=404,
            content={"message": f"No records found for {date_str} in dataset '{dataset_name}'"}
        )
    return filtered.to_dict(orient="records")

@app.get("/metadata/{dataset_name}", summary="Get metadata of dataset")
def get_metadata(dataset_name: str):
    key = dataset_name.lower()
    if key not in metadata_store:
        raise HTTPException(status_code=404, detail=f"Metadata for dataset '{dataset_name}' not found")
    return metadata_store[key]

# -----------------------------
# Run the server
# -----------------------------
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
