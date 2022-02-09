# Automatically clones a github repository given credentials in secrets manager
# Installs a git helper function which retrieves the password or developer token from Secrets Manager 
# directly for cloning a repository from a private git repo or pushing back changes upstream. 
# Storing passwords and tokens in Secrets Manager eliminates the need to store any sensitive information on EFS.

# Steps:
# 1. Add your password or personal developer token to Secret Manager
# 2. Set the secret name and key in the script below, along with the repository url

#!/bin/bash

set -eux

## Parameters 
# your git provider, e.g. github.com
GIT_PROVIDER="github.com"
GIT_USERNAME="<username>"
GIT_EMAIL="<email>"
AWS_REGION="us-east-1"
# Secret name stored in AWS Secrets Manager
AWS_SECRET_NAME="<secret-name>"
# Secret key names inside the secret
# Secret is stored with two key-value pairs, keys username and password
# Replace these values if your secrets are stored as different keys
AWS_SECRET_NAME_KEY="username"
AWS_SECRET_PASS_KEY="password"
REPOSITORY_URL="<repo-https-url>"
FOLDER="<folder-name>"
HOME="/home/ec2-user"

## Script Body

PYTHON_EXEC=$(command -v python)
cat > ~/.aws-credential-helper.py <<EOL
#!$PYTHON_EXEC
import sys
import json
import boto3
import botocore
# GIT_PROVIDER='$GIT_PROVIDER'
GIT_USERNAME='$GIT_USERNAME'
AWS_REGION='$AWS_REGION'
AWS_SECRET_NAME='$AWS_SECRET_NAME'
AWS_SECRET_NAME_KEY='$AWS_SECRET_NAME_KEY'
AWS_SECRET_PASS_KEY='$AWS_SECRET_PASS_KEY'
client = boto3.client("secretsmanager", region_name=AWS_REGION)
credentials = {}
try:
    response = client.get_secret_value(SecretId=AWS_SECRET_NAME)
except botocore.exceptions.ClientError as e:
    print("Error reading secret")
    print(e)
    exit(1)
if 'SecretString' in response:
    secret = response['SecretString']
    secret_dict = json.loads(secret)
    if AWS_SECRET_PASS_KEY in secret_dict:
        credentials['password'] = secret_dict[AWS_SECRET_PASS_KEY]
    if AWS_SECRET_NAME_KEY in secret_dict:
        credentials['username'] = secret_dict[AWS_SECRET_NAME_KEY]
for key, value in credentials.items():
    print('{}={}'.format(key, value))
EOL

chmod +x ~/.aws-credential-helper.py

sudo -u ec2-user -i <<EOF

git config --global credential.helper ~/.aws-credential-helper.py
git config --global user.name "$GIT_USERNAME"
git config --global user.email "$GIT_EMAIL"

EOF

# check if folder exists and clone
if [ ! -d "/home/ec2-user/SageMaker/$FOLDER" ] ; then
    git -C /home/ec2-user/SageMaker clone $REPOSITORY_URL
# if you want to pull latest when restarting, uncomment lines below
# else
#     cd "$FOLDER"
#     git pull $REPOSITORY_URL
fi