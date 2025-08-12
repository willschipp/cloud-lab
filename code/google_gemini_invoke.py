from google import genai

def invoke(prompt,api_key,model="gemini-2.5-flash"):
    client = genai.Client(api_key=api_key)
    # invoke
    response = client.models.generate_content(
        model=model,
        contents=prompt
    )
    return response.text


if __name__ == "__main__":
    # set your API key here
    api_key = "YOUR GOOGLE KEY HERE"

    # enter your prompt
    prompt = "why is the sky blue?"
    
    # get the reply
    reply = invoke(prompt,api_key)

    # write it out
    print(reply)