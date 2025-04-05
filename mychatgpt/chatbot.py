# #python3 -m venv chatbot-env  # Create a virtual environment named 'chatbot-env'
# #source chatbot-env/bin/activate  # Activate the virtual environment
# # pip install -r requirements.txt 

# Import required libraries
from langchain.chains import LLMChain  # Importing LLMChain for chaining language models with a prompt
from langchain.llms.bedrock import Bedrock  # Importing the Bedrock model from LangChain
from langchain.prompts import PromptTemplate  # Importing PromptTemplate to define templates for prompts
import boto3  # AWS SDK to interact with AWS services
import os  # For working with environment variables
import streamlit as st  # Streamlit for creating the web UI for the chatbot

# Initialize Bedrock client using Boto3 to interact with AWS services
bedrock_client = boto3.client(
    service_name="bedrock-runtime",  # This is to access AWS Bedrock API
    region_name="us-east-1"  # The region where the service is available
)

# Specify the model ID to be used for chatbot responses (e.g., Claude-v2)
modelID = "anthropic.claude-v2"

# Initialize the Bedrock model with the specified model ID and client configuration
llm = Bedrock(
    model_id=modelID,  # The model you want to use (Claude-v2 in this case)
    client=bedrock_client,  # The Bedrock client to interact with the AWS API
    model_kwargs={"max_tokens_to_sample": 1000, "temperature": 0.9}  # Custom settings for the model
)

# Define the function to create a chatbot interaction
def my_chatbot(language, freeform_text):
    # Create a prompt template to format the input for the model
    prompt = PromptTemplate(
        input_variables=["language", "freeform_text"],  # Defining the variables to use in the template
        template="You are a chatbot. You are in {language}.\n\n{freeform_text}"  # The structure of the prompt
    )

    # Create an LLMChain, linking the model and the prompt template
    bedrock_chain = LLMChain(llm=llm, prompt=prompt)

    # Get the response by passing the variables (language, freeform_text) into the chain
    response = bedrock_chain({'language': language, 'freeform_text': freeform_text})
    
    # Return the response from the model
    return response

# Streamlit app UI
st.title("My ChatGPT")  # Setting the title of the web application

# Create a language selector (dropdown) in the sidebar
language = st.sidebar.selectbox("Language", ["english", "spanish"])  # Dropdown for selecting the language

# If a language is selected, ask for a freeform text input
if language:
    freeform_text = st.sidebar.text_area(label="What is your question?", max_chars=100)  # Text input box for the user's question

# If the user has entered a question, process the input using the chatbot function
if freeform_text:
    response = my_chatbot(language, freeform_text)  # Call the chatbot function with the selected language and question
    
    # Display the response from the chatbot on the webpage
    st.write(response['text'])  # Showing the chatbot's answer