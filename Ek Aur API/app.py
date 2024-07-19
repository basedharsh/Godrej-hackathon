# from flask import Flask, request, jsonify
# from PyPDF2 import PdfReader
# from langchain.text_splitter import CharacterTextSplitter
# import os
# from langchain_google_genai import GoogleGenerativeAIEmbeddings
# import google.generativeai as genai
# from langchain.vectorstores import FAISS
# from langchain_google_genai import ChatGoogleGenerativeAI
# from langchain.memory import ConversationBufferMemory
# from langchain.chains import ConversationalRetrievalChain
# import tempfile
# import uuid
# from dotenv import load_dotenv
# import pickle
# import firebase_admin
# from firebase_admin import credentials, storage, firestore

# cred = credentials.Certificate("config/god-rage-aaca3-firebase-adminsdk-8o3uh-97a23a3858.json")
# firebase_admin.initialize_app(cred, {
#     'storageBucket': 'god-rage-aaca3.appspot.com'
# })
# db = firestore.client()
# bucket = storage.bucket()


# app = Flask(__name__)
# load_dotenv()
# os.getenv("GOOGLE_API_KEY")
# genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))

# sessions = {}

# def get_pdf_text(pdf_path):
#     text = ""
#     pdf_reader = PdfReader(pdf_path)
#     for page in pdf_reader.pages:
#         text += page.extract_text()
#     return text

# def get_text_chunks(text):
#     text_splitter = CharacterTextSplitter(
#         separator="\n",
#         chunk_size=1000,
#         chunk_overlap=200,
#         length_function=len
#     )
#     chunks = text_splitter.split_text(text)
#     return chunks

# def get_vectorstore(text_chunks):
#     embeddings = GoogleGenerativeAIEmbeddings(model="models/embedding-001")
#     vectorstore = FAISS.from_texts(texts=text_chunks, embedding=embeddings)
#     return vectorstore

# def get_conversation_chain(vectorstore):
#     llm = ChatGoogleGenerativeAI(model="gemini-1.5-pro-latest", temperature=0.5)
#     memory = ConversationBufferMemory(memory_key='chat_history', return_messages=True)
#     conversation_chain = ConversationalRetrievalChain.from_llm(
#         llm=llm,
#         retriever=vectorstore.as_retriever(),
#         memory=memory
#     )
#     return conversation_chain

# @app.route('/create_session', methods=['POST'])
# def create_session():
#     if 'pdfs' not in request.files:
#         return jsonify({"error": "No PDF files provided"}), 400

#     pdf_files = request.files.getlist('pdfs')
#     raw_text = ""
    
#     for pdf in pdf_files:
#         with tempfile.NamedTemporaryFile(delete=False) as temp_file:
#             pdf.save(temp_file.name)
#             raw_text += get_pdf_text(temp_file.name)

#     session_id = str(uuid.uuid4())
#     text_chunks = get_text_chunks(raw_text)
#     vectorstore = get_vectorstore(text_chunks)
#     conversation_chain = get_conversation_chain(vectorstore)

    
#     sessions[session_id] = {
#         "conversation_chain": conversation_chain,
#         "chat_history": []
#     }

#     chunk_size = 100  # Number of chunks per document
#     chunk_urls = []
#     for i in range(0, len(text_chunks), chunk_size):
#         chunk_part = text_chunks[i:i + chunk_size]
#         chunk_blob = bucket.blob(f'{session_id}/chunk_{i // chunk_size}.pkl')
#         chunk_blob.upload_from_string(pickle.dumps(chunk_part))
#         chunk_url = chunk_blob.public_url
#         chunk_urls.append(chunk_url)

#     # Store the chunk URLs in Firestore
#     db.collection('sessions').document(session_id).set({
#         'chunk_urls': chunk_urls,
#     })


#     # print("Randh : ",pickle.dumps(text_chunks))
    

#     return jsonify({"session_id": session_id}), 200

# @app.route('/ask_question', methods=['POST'])
# def ask_question():
#     data = request.json
#     session_id = data.get('session_id')
#     user_question = data.get('question')

#     if not session_id or not user_question:
#         return jsonify({"error": "Invalid session_id or question"}), 400

#     session_doc = db.collection('sessions').document(session_id).get()
#     if not session_doc.exists:
#         return jsonify({"error": "Session not found"}), 404

#     session_data = session_doc.to_dict()
#     chunk_urls = session_data.get('chunk_urls', [])

#     text_chunks = []
#     for url in chunk_urls:
#         chunk_blob = bucket.blob(url.split('/')[-1])
#         chunk_data = chunk_blob.download_as_string()
#         text_chunks.extend(pickle.loads(chunk_data))

#     vector = get_vectorstore(pickle.loads(text_chunks))
#     conversation_chain = get_conversation_chain(vector)
#     response = conversation_chain({'question': user_question})
#     chat_history = response['chat_history']

#     messages = []
#     for i, message in enumerate(chat_history):
#         messages.append({"role": "user" if i % 2 == 0 else "bot", "content": message.content})

#     # Update session chat history
#     # session['chat_history'] = messages
#     # sessions[session_id] = session

#     return jsonify({"chat_history": messages}), 200

# @app.route('/get_chat_history', methods=['POST'])
# def get_chat_history():
#     data = request.json
#     session_id = data.get('session_id')

#     if not session_id:
#         return jsonify({"error": "Invalid session_id"}), 400

#     session = sessions.get(session_id)

#     if not session:
#         return jsonify({"error": "Session not found"}), 404

#     return jsonify({"chat_history": session['chat_history']}), 200

# if __name__ == '__main__':
#     app.run(debug=True)

# ######################################################################################################################################

# # import firebase_admin
# # from firebase_admin import credentials, storage
# # import pickle
# # import os
# # import tempfile
# # import uuid
# # from flask import Flask, request, jsonify
# # from PyPDF2 import PdfReader
# # from langchain.text_splitter import CharacterTextSplitter
# # from langchain_google_genai import GoogleGenerativeAIEmbeddings
# # import google.generativeai as genai
# # from langchain.vectorstores import FAISS
# # from langchain_google_genai import ChatGoogleGenerativeAI
# # from langchain.memory import ConversationBufferMemory
# # from langchain.chains import ConversationalRetrievalChain
# # from dotenv import load_dotenv
# # import tarfile

# # app = Flask(__name__)
# # load_dotenv()

# # # Initialize Firebase
# # cred = credentials.Certificate("config/god-rage-aaca3-firebase-adminsdk-8o3uh-97a23a3858.json")
# # firebase_admin.initialize_app(cred, {
# #     'storageBucket': 'god-rage-aaca3.appspot.com'
# # })
# # bucket = storage.bucket()

# # genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))

# # def get_pdf_text(pdf_path):
# #     text = ""
# #     pdf_reader = PdfReader(pdf_path)
# #     for page in pdf_reader.pages:
# #         text += page.extract_text()
# #     return text

# # def get_text_chunks(text):
# #     text_splitter = CharacterTextSplitter(
# #         separator="\n",
# #         chunk_size=1000,
# #         chunk_overlap=200,
# #         length_function=len
# #     )
# #     chunks = text_splitter.split_text(text)
# #     return chunks

# # def get_vectorstore(text_chunks):
# #     embeddings = GoogleGenerativeAIEmbeddings(model="models/embedding-001")
# #     vectorstore = FAISS.from_texts(texts=text_chunks, embedding=embeddings)
# #     return vectorstore

# # def get_conversation_chain(vectorstore):
# #     llm = ChatGoogleGenerativeAI(model="gemini-1.5-pro-latest", temperature=0.5)
# #     memory = ConversationBufferMemory(memory_key='chat_history', return_messages=True)
# #     conversation_chain = ConversationalRetrievalChain.from_llm(
# #         llm=llm,
# #         retriever=vectorstore.as_retriever(),
# #         memory=memory
# #     )
# #     return conversation_chain

# # def save_to_firebase_storage(session_id, obj):
# #     """
# #     Serializes and saves the session to Firebase Storage.
    
# #     Args:
# #         session_id (str): The session ID.
# #         obj (dict): The session data to be serialized and saved.
# #     """
# #     with tempfile.TemporaryDirectory() as temp_dir:
# #         vectorstore_path = os.path.join(temp_dir, f'{session_id}_vectorstore')
# #         obj["vectorstore"].save_local(vectorstore_path)
        
# #         # Create a tarball of the vectorstore directory
# #         tarball_path = os.path.join(temp_dir, f'{session_id}_vectorstore.tar.gz')
# #         with tarfile.open(tarball_path, "w:gz") as tar:
# #             tar.add(vectorstore_path, arcname=os.path.basename(vectorstore_path))
        
# #         serialized_obj = {
# #             "vectorstore_tarball": tarball_path,
# #             "chat_history": obj["chat_history"]
# #         }
        
# #         temp_file_path = os.path.join(temp_dir, f'{session_id}.pkl')
# #         with open(temp_file_path, 'wb') as temp_file:
# #             pickle.dump(serialized_obj, temp_file)
        
# #         blob = bucket.blob(f'sessions/{session_id}.pkl')
# #         blob.upload_from_filename(temp_file_path)

# # def load_from_firebase_storage(session_id):
# #     """
# #     Loads and deserializes the session from Firebase Storage.
    
# #     Args:
# #         session_id (str): The session ID.
    
# #     Returns:
# #         dict: The deserialized session data or None if the session does not exist.
# #     """
# #     blob = bucket.blob(f'sessions/{session_id}.pkl')
# #     if not blob.exists():
# #         return None
# #     with tempfile.TemporaryDirectory() as temp_dir:
# #         temp_file_path = os.path.join(temp_dir, f'{session_id}.pkl')
# #         blob.download_to_filename(temp_file_path)
# #         with open(temp_file_path, 'rb') as file:
# #             serialized_obj = pickle.load(file)
        
# #         tarball_path = serialized_obj["vectorstore_tarball"]
        
# #         # Extract the tarball
# #         with tarfile.open(tarball_path, "r:gz") as tar:
# #             tar.extractall(path=temp_dir)
        
# #         vectorstore_path = os.path.join(temp_dir, f'{session_id}_vectorstore')
# #         vectorstore = FAISS.load_local(vectorstore_path, GoogleGenerativeAIEmbeddings(model="models/embedding-001"))
# #         conversation_chain = get_conversation_chain(vectorstore)
        
# #         return {
# #             "conversation_chain": conversation_chain,
# #             "chat_history": serialized_obj["chat_history"]
# #         }

# # @app.route('/create_session', methods=['POST'])
# # def create_session():
# #     if 'pdfs' not in request.files:
# #         return jsonify({"error": "No PDF files provided"}), 400

# #     pdf_files = request.files.getlist('pdfs')
# #     raw_text = ""
    
# #     for pdf in pdf_files:
# #         with tempfile.NamedTemporaryFile(delete=False) as temp_file:
# #             pdf.save(temp_file.name)
# #             raw_text += get_pdf_text(temp_file.name)
# #             temp_file.close()

# #     text_chunks = get_text_chunks(raw_text)
# #     vectorstore = get_vectorstore(text_chunks)
# #     conversation_chain = get_conversation_chain(vectorstore)

# #     session_id = str(uuid.uuid4())
# #     session_data = {
# #         "vectorstore": vectorstore,
# #         "chat_history": []
# #     }

# #     save_to_firebase_storage(session_id, session_data)

# #     return jsonify({"session_id": session_id}), 200

# # @app.route('/ask_question', methods=['POST'])
# # def ask_question():
# #     data = request.json
# #     session_id = data.get('session_id')
# #     user_question = data.get('question')

# #     if not session_id or not user_question:
# #         return jsonify({"error": "Invalid session_id or question"}), 400

# #     session_data = load_from_firebase_storage(session_id)

# #     if not session_data:
# #         return jsonify({"error": "Session not found"}), 404

# #     conversation_chain = session_data['conversation_chain']
# #     response = conversation_chain({'question': user_question})
# #     chat_history = response['chat_history']

# #     messages = []
# #     for i, message in enumerate(chat_history):
# #         messages.append({"role": "user" if i % 2 == 0 else "bot", "content": message.content})

# #     # Update session chat history
# #     session_data['chat_history'] = messages
# #     save_to_firebase_storage(session_id, session_data)

# #     return jsonify({"chat_history": messages}), 200

# # @app.route('/get_chat_history', methods=['POST'])
# # def get_chat_history():
# #     data = request.json
# #     session_id = data.get('session_id')

# #     if not session_id:
# #         return jsonify({"error": "Invalid session_id"}), 400

# #     session_data = load_from_firebase_storage(session_id)

# #     if not session_data:
# #         return jsonify({"error": "Session not found"}), 404

# #     return jsonify({"chat_history": session_data['chat_history']}), 200

# # if __name__ == '__main__':
# #     app.run(debug=True)



from flask import Flask, request, jsonify
from PyPDF2 import PdfReader
from langchain.text_splitter import CharacterTextSplitter
import os
from langchain_google_genai import GoogleGenerativeAIEmbeddings
import google.generativeai as genai
from langchain.vectorstores import FAISS
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain.memory import ConversationBufferMemory
from langchain.chains import ConversationalRetrievalChain
import tempfile
import uuid
from dotenv import load_dotenv
import pickle
import firebase_admin
from firebase_admin import credentials, storage, firestore
from flask_cors import CORS

cred = credentials.Certificate("config/god-rage-aaca3-firebase-adminsdk-8o3uh-97a23a3858.json")
firebase_admin.initialize_app(cred, {
    'storageBucket': 'god-rage-aaca3.appspot.com'
})
db = firestore.client()
bucket = storage.bucket()

app = Flask(__name__)
CORS(app)
load_dotenv()
os.getenv("GOOGLE_API_KEY")
genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))

sessions = {}

def get_pdf_text(pdf_path):
    text = ""
    pdf_reader = PdfReader(pdf_path)
    for page in pdf_reader.pages:
        text += page.extract_text()
    return text

def get_text_chunks(text):
    text_splitter = CharacterTextSplitter(
        separator="\n",
        chunk_size=1000,
        chunk_overlap=200,
        length_function=len
    )
    chunks = text_splitter.split_text(text)
    return chunks

def get_vectorstore(text_chunks):
    embeddings = GoogleGenerativeAIEmbeddings(model="models/embedding-001")
    vectorstore = FAISS.from_texts(texts=text_chunks, embedding=embeddings)
    return vectorstore

def get_conversation_chain(vectorstore):
    llm = ChatGoogleGenerativeAI(model="gemini-1.5-pro-latest", temperature=0.5)
    memory = ConversationBufferMemory(memory_key='chat_history', return_messages=True)
    conversation_chain = ConversationalRetrievalChain.from_llm(
        llm=llm,
        retriever=vectorstore.as_retriever(),
        memory=memory
    )
    return conversation_chain

@app.route('/create_session', methods=['POST'])
def create_session():
    if 'pdfs' not in request.files:
        return jsonify({"error": "No PDF files provided"}), 400

    pdf_files = request.files.getlist('pdfs')
    raw_text = ""
    
    for pdf in pdf_files:
        with tempfile.NamedTemporaryFile(delete=False) as temp_file:
            pdf.save(temp_file.name)
            raw_text += get_pdf_text(temp_file.name)

    session_id = str(uuid.uuid4())
    text_chunks = get_text_chunks(raw_text)
    vectorstore = get_vectorstore(text_chunks)
    conversation_chain = get_conversation_chain(vectorstore)

    sessions[session_id] = {
        "conversation_chain": conversation_chain,
        "chat_history": []
    }

    chunk_size = 100  # Number of chunks per document
    chunk_urls = []
    for i in range(0, len(text_chunks), chunk_size):
        chunk_part = text_chunks[i:i + chunk_size]
        chunk_blob_name = f'{session_id}/chunk_{i // chunk_size}.pkl'
        chunk_blob = bucket.blob(chunk_blob_name)
        chunk_blob.upload_from_string(pickle.dumps(chunk_part))
        chunk_url = chunk_blob.public_url
        chunk_urls.append(chunk_blob_name)

    # Store the chunk URLs in Firestore
    db.collection('sessions').document(session_id).set({
        'id': session_id,
        'chunk_urls': chunk_urls,
        'chat_history': [],
        'created_at': firestore.SERVER_TIMESTAMP
    })
    print("Done")
    return jsonify({"session_id": session_id}), 200

@app.route('/ask_question', methods=['POST'])
def ask_question():
    data = request.json
    session_id = data.get('session_id')
    user_question = data.get('question')

    if not session_id or not user_question:
        return jsonify({"error": "Invalid session_id or question"}), 400

    session_doc = db.collection('sessions').document(session_id).get()
    if not session_doc.exists:
        return jsonify({"error": "Session not found"}), 404

    session_data = session_doc.to_dict()
    chunk_urls = session_data.get('chunk_urls', [])

    text_chunks = []
    for chunk_blob_name in chunk_urls:
        chunk_blob = bucket.blob(chunk_blob_name)
        chunk_data = chunk_blob.download_as_string()
        text_chunks.extend(pickle.loads(chunk_data))

    vectorstore = get_vectorstore(text_chunks)
    conversation_chain = get_conversation_chain(vectorstore)

    response = conversation_chain({'question': user_question})
    chat_history = response['chat_history']

    messages = []
    for i, message in enumerate(chat_history):
        messages.append({"role": "user" if i % 2 == 0 else "bot", "content": message.content})

    return jsonify({"chat_history": messages}), 200

@app.route('/get_chat_history', methods=['POST'])
def get_chat_history():
    data = request.json
    session_id = data.get('session_id')

    if not session_id:
        return jsonify({"error": "Invalid session_id"}), 400

    session = sessions.get(session_id)

    if not session:
        return jsonify({"error": "Session not found"}), 404

    return jsonify({"chat_history": session['chat_history']}), 200

if __name__ == '__main__':
    app.run(debug=True)
