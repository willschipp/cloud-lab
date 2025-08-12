# vLLM

## NOTE: Image Size

- `vllm/vllm-openai:latest` is ~10GB


## Prerequisite

- huggingface token


## Curl command

```sh
curl http://localhost/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mistralai/Mistral-7B-Instruct-v0.3",
    "prompt": "Why is the sky blue?",
    "max_tokens": 50,
    "temperature": 0.7
  }'
  ```