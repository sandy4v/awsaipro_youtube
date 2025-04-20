# Importing required libraries

import streamlit as st  # Streamlit is used to create the web interface
from langchain.document_loaders import PyPDFLoader  # Loads PDF documents
from langchain.text_splitter import RecursiveCharacterTextSplitter  # Splits text into smaller chunks
from langchain.vectorstores import FAISS  # Vector store for fast similarity search
import os
import boto3  # For AWS services (used indirectly here for Bedrock)
from langchain.embeddings import BedrockEmbeddings  # Embedding model from AWS Bedrock
from langchain.chains import RetrievalQA  # Retrieval-based QA chain from LangChain
from langchain.llms import Bedrock  # Bedrock LLM integration from LangChain

# ------------------------------------------------------
# UI SECTION (Streamlit)
# ------------------------------------------------------

# Set the title of the web app
st.title("Life Science Ethics QA")  # This is the app heading users will see

# URL of the PDF we want to process
pdf_url = "https://www.regeneron.com/downloads/regeneron-position-ethics-clinical-studies.pdf"

# ------------------------------------------------------
# Step 1: Initialize session state variables
# ------------------------------------------------------
# These session variables help cache data so we don’t reload or recompute on every user input

if 'chunks' not in st.session_state:
    st.session_state['chunks'] = None
if 'embeddings' not in st.session_state:
    st.session_state['embeddings'] = None
if 'db' not in st.session_state:
    st.session_state['db'] = None

# ------------------------------------------------------
# Step 2: Load and split the PDF into chunks
# ------------------------------------------------------
# We load the PDF, extract its text, and split it into manageable chunks for embedding and search.

if st.session_state['chunks'] is None:
    print("Loading PDF and creating chunks...")
    loader = PyPDFLoader(pdf_url)  # Load the PDF from the URL
    documents = loader.load()  # Extract the document content
    text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100)  # Split into 1,000-character chunks with 100 overlap
    st.session_state['chunks'] = text_splitter.split_documents(documents)  # Save the chunks
    print(f"Split into {len(st.session_state['chunks'])} chunks")
else:
    print("Using cached chunks.")  # Skip reprocessing if already done

# ------------------------------------------------------
# Step 3: Generate text embeddings using Bedrock
# ------------------------------------------------------
# We use embeddings to convert text into vector format for similarity search.

if st.session_state['embeddings'] is None:
    print("Creating Bedrock embeddings...")
    st.session_state['embeddings'] = BedrockEmbeddings(
        credentials_profile_name="default",  # Use AWS CLI's default credentials
        model_id="amazon.titan-embed-text-v1"  # Use Titan embedding model from AWS Bedrock
    )
    print("Bedrock embeddings created.")
else:
    print("Using cached embeddings.")

# ------------------------------------------------------
# Step 4: Create a FAISS vector store
# ------------------------------------------------------
# We store the vectorized chunks into FAISS to enable fast similarity searches during Q&A.

if st.session_state['db'] is None:
    print("Creating FAISS vector store...")
    st.session_state['db'] = FAISS.from_documents(
        st.session_state['chunks'],
        st.session_state['embeddings']
    )
    print("FAISS vector store created.")
else:
    print("Using cached FAISS index.")

# ------------------------------------------------------
# Step 5: Take user input for a question
# ------------------------------------------------------
# This is the main user interaction point — user types a question about the document.

query = st.text_input("Enter your question about Regeneron's ethics policy:")

if query:
    st.write("You asked:", query)

    # ------------------------------------------------------
    # Step 6: Initialize the Bedrock LLM (Claude v2)
    # ------------------------------------------------------
    # This large language model will generate responses to user queries.

    bedrock_llm = Bedrock(
        model_id="anthropic.claude-v2",  # We’re using Claude v2 from Anthropic
        credentials_profile_name="default"
    )

    # ------------------------------------------------------
    # Step 7: Create a RetrievalQA chain
    # ------------------------------------------------------
    # This chain uses the FAISS retriever and the LLM to answer the question.

    qa_chain = RetrievalQA.from_chain_type(
        llm=bedrock_llm,
        chain_type="stuff",  # Basic chain type that feeds all relevant chunks to the LLM
        retriever=st.session_state['db'].as_retriever(search_kwargs={'k': 3})  # Retrieve top 3 relevant chunks
    )

    # ------------------------------------------------------
    # Step 8: Run the query and display the result
    # ------------------------------------------------------
    # We send the user's question through the chain and display the generated answer.

    answer = qa_chain.run(query)
    st.write("Answer:", answer)

    # how to run on terminal / command prompt
    # streamlit run url-faiss.py