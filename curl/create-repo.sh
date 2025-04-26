#!/usr/bin/env bash

repo_name="$1"
user_name="$2"
user_token="$3"
repo_description="${4:-New Repo}"
privacy="${5:-false}"

curl -u "${user_name}:${user_token}" \
     -X POST \
     -H "Content-Type: application/json" \
     -d "{\"name\":\"${repo_name}\",\"description\":\"${repo_description}\",\"private\":${privacy}}" \
     https://api.github.com/user/repos

