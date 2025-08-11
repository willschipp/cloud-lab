# Curl command

```sh
curl http://mistral-7b.default.svc.cluster.local/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mistralai/Mistral-7B-Instruct-v0.3",
    "prompt": "Why is the sky blue?",
    "max_tokens": 50,
    "temperature": 0.7
  }'
  ```