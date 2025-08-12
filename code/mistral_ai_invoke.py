from mistralai import Mistral

def invoke(prompt,api_key,model="mistral-medium"):
    client = Mistral(api_key=api_key)
    
    chat_response = client.chat.complete(
        model= model,
        messages = [
            {
                "role": "user",
                "content": prompt,
            },
        ]
    )
    
    return chat_response.choices[0].message.content


if __name__ == "__main__":
    # set your API key here
    api_key = "YOUR MISTRAL KEY HERE"

    # enter your prompt
    prompt = "why is the sky blue?"
    
    # get the reply
    reply = invoke(prompt,api_key)

    # write it out
    print(reply)