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
import json

import faiss
import pickle

def load_vectorstore(file_path):
    index = faiss.read_index(f"{file_path}.index")
    with open(f"{file_path}.pkl", 'rb') as f:
        docstore = pickle.load(f)
    vectorstore = FAISS(index=index, docstore=docstore)
    return vectorstore

vector = load_vectorstore('vectorstore')

llm = ChatGoogleGenerativeAI(model="gemini-1.5-pro-latest", temperature=0.5)
memory = ConversationBufferMemory(memory_key='chat_history', return_messages=True)
conversation_chain = ConversationalRetrievalChain.from_llm(
    llm=llm,
    retriever=vector.as_retriever(),
    memory=memory
)

print(conversation_chain)