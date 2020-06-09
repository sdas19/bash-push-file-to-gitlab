# your gitlab private PRIVATE_TOKEN
PRIVATE_TOKEN=$GITLAB_PRIVATE_TOKEN
echo "printing private token --> ${PRIVATE_TOKEN}"

# pass arguments while running this script
# argument 1 : Name of the file you want to push to gitlab
# argument 2 : commit message
# argument 3 : File path along with folder structure where you want to keep the file in gitlab

FILE_NAME=$1
COMMIT_MESSAGE=$2
GITLAB_FILE_PATH=$3
echo $FILE_NAME
echo $COMMIT_MESSAGE
echo $GITLAB_FILE_PATH

# gitlab project definitions
GITLAB_PROJECT_URL="<---PROJECT URL---->"
GITLAB_API_BASE_URL="<---BASE URL---->"
GITLAB_PROJECT_ID="<---PROJECT ID---->"
GITLAB_PROJECT_FINAL_URL="$GITLAB_API_BASE_URL/projects/$GITLAB_PROJECT_ID/repository/commits"

# gitlab actions and error message
CREATE_ACTION="create"
UPDATE_ACTION="update"
ERROR_MESSAGE="A file with this name already exists"

# variable to store the Base 64 encoding of the file
FILE_CONTENT=""

# function to commit the file
# argument is gitlab action, whether create the file in repository or update the same file
# create the payload with Gitlab COMMIT API POST body
# generate payload.json file with the created payload
# payload.json file is deleted post completion of the process
# called from line no 69 and 71
function commitWithFile() {
  API_ACTION=$1
  PAYLOAD='{
  "branch": "develop",
  "commit_message": "'"$COMMIT_MESSAGE"'",
  "actions": [
    {
      "action": "'"$API_ACTION"'",
      "file_path": "'"$GITLAB_FILE_PATH"'",
      "encoding": "base64",
      "content": "'"$FILE_CONTENT"'"
    }
  ]
}'
cat <<EOF > payload.json
$PAYLOAD
EOF
RESULT=$(curl --http1.1 --request POST --silent --header "PRIVATE-TOKEN: ${PRIVATE_TOKEN}" --header "Content-Type: application/json" -d @payload.json $GITLAB_PROJECT_FINAL_URL | grep -o '"message":"[^"]*' | cut -d'"' -f4)
echo $RESULT
}

if [ "$PRIVATE_TOKEN" == "" ]; then
  echo
  printf "\n Please set GITLAB_PRIVATE_TOKEN first...\n"
  printf "\n Get your token with scope api at.."
  printf "\n https://source.golabs.io/profile/personal_access_tokens \n"
  printf "\n And run below"
  printf "\n export GITLAB_PRIVATE_TOKEN=YOUR_PRIVATE_TOKEN_GOES_HERE\n\n"
  printf "\n add GITLAB_PRIVATE_TOKEN to your bash profile for further usage\n\n"

else

  FILE_CONTENT=$( base64 $FILE_NAME)
  RESPONSE=$(commitWithFile $CREATE_ACTION)
  if [ "$RESPONSE" == "$ERROR_MESSAGE" ]; then
    RESPONSE=$(commitWithFile $UPDATE_ACTION)
  fi

  echo $RESPONSE

rm -f payload.json
fi
