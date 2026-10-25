from document_processor import PipelineOptions, get_processed
from fastapi import FastAPI
from probabilistic_model import ProbabilisticModel
from posting_list import PostingList
import kagglehub
from pathlib import Path
import pandas as pd

# To run: uv add fastapi uvicorn
# uv run uvicorn main:app --reload

app = FastAPI(title="Lyrics Retriever")
#BASE_DIR = Path(__file__).resolve().parent

# ------------- INIT -------------
# download dataset
path = kagglehub.dataset_download("deepshah16/song-lyrics-dataset", output_dir="./data")
# get pandas dataframe
df = None
files = list(Path("./data/csv").glob("*.csv"))
for file in files:
    single_df = pd.read_csv(file)
    df = pd.concat([single_df,df], ignore_index=True)
df = df.dropna()
del df['Unnamed: 0']
df = df.rename(columns={
    "Artist":"artist",
    "Title":"title",
    "Album":"album",
    "Year":"year",
    "Date":"date",
    "Lyric":"lyric",
})
df["year"] = df.apply(
    lambda row: int(row["year"]),
    axis=1
)
df["lyrics_processed"] = df.apply(
    lambda row: " ".join(get_processed(row["lyric"])),
    axis=1
)
# create posting list
posting_list = PostingList(PipelineOptions.WithStopRemovalWithStemming)
posting_list.add_documents(documents=df["lyric"].to_dict())

model = ProbabilisticModel(posting_list, PipelineOptions.WithStopRemovalWithStemming)

# ------------- API -------------
#@app.get("/", response_class=HTMLResponse)
#def home():
#    return (BASE_DIR / "index.html").read_text(encoding="utf-8")
#@app.get("")

@app.get("/lyrics/{lyric_id}")
async def get_lyric(lyric_id: int):
    return {"lyrics": df.loc[lyric_id]}

@app.get("/search/{query}")
async def get_ranking(query: str):
    limit = 10
    query_results = model.execute_query(query, return_scores=True)[:limit]
    query_response = [{"id": id, **df.loc[id].to_dict(), "metric": scores[0], "relevant_terms": scores[1]} for id, scores in query_results]
    return{"musics": query_response, "query_processed": get_processed(query)}
