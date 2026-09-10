from vectorial_model import VectorialModel
from probabilistic_model import ProbabilisticModel
from posting_list import PostingList
from document_processor import PipelineOptions

documents = {
        1: "To do is to be. To be is to do.",
        2: "To be or not to be. I am what i am.",
        3: "I think therefore i am. Do be do be do.",
        4: "Do do do, da da da. Let it be, let it be."
    }

posting_list = PostingList(PipelineOptions.NoStopRemovalNoStemming)
posting_list.add_documents(documents)

def test_vectorial_model():
    vectorial_model = VectorialModel(posting_list, PipelineOptions.NoStopRemovalNoStemming)
    ranking = vectorial_model.execute_query("to do", show_sim_score=True)
    print("[Vectorial Model Test] ID's ranking: ", ranking)

def test_probabilistic_model():
    probabilistic_model = ProbabilisticModel(posting_list, PipelineOptions.NoStopRemovalNoStemming)
    ranking = probabilistic_model.execute_query("to do", show_sim_score=True)
    print("[Probabilistic Model Test] ID's ranking: ", ranking)

test_vectorial_model()
test_probabilistic_model()
