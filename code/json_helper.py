import json

###################################################
#  
#  JSON Prompts
# 
#  When using prompts that "respond only with json",
#  results are frequently returned with ```json{}```
#
#  The following is a helper function to clean up and
#  return a 'proper' json object
#
###################################################
def get_clean_json(response):
    # clean up
    response = response.strip() # get rid of whitespaces
    starting_block = "```json"
    ending_block = "```"
    # strip off the prefix
    if response.startswith(starting_block):
        code_block = response[len(starting_block):]
    
    if code_block.endswith(ending_block):
        code_block = code_block[:-(len(ending_block))]
    
    code_block = code_block.strip() #last clean up
    # return as a json object
    return json.loads(code_block)  