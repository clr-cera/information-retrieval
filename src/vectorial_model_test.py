from vectorial_model import VectorialModel
from posting_list import PostingList
from document_processor import PipelineOptions

def test_vectorial_model():
    documents = {
        1: "To do is to be. To be is to do.",
        2: "To be or not to be. I am what i am.",
        3: "I think therefore i am. Do be do be do.",
        4: "Do do do, da da da. Let it be, let it be."
    }

    posting_list = PostingList(PipelineOptions.NoStopRemovalNoStemming)
    posting_list.add_documents(documents)
    vectorial_model = VectorialModel(posting_list, PipelineOptions.NoStopRemovalNoStemming)
    ranking = vectorial_model.execute_query("let's do it!", True)
    print("[Vectorial Model Test] ID's ranking: ", ranking)

test_vectorial_model()
