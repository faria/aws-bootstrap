#!/bin/bash

STACK_NAME=awsbootstrap
REGION=us-west-2
CLI_PROFILE=awsbootstrap

EC2_INSTANCE_TYPE=t2.micro

# Generate a personal access token with repo and admin:repo_hook
#  permissions from github
# This assumes we have created ~/.github and the files contained in it
GH_ACCESS_TOKEN=$(cat ~/.github/aws-bootstrap-access-token)
GH_OWNER=$(cat ~/.github/aws-bootstrap-owner)
GH_REPO=$(cat ~/.github/aws-bootstrap-repo)
GH_BRANCH=main

# Extract AWS Account ID from sts get-caller-identity
AWS_ACCOUNT_ID=`aws sts get-caller-identity --profile awsbootstrap --query "Account" --output text`

# S3 bucket names must be globally unique. Add AccountID to bucket name
CODEPIPELINE_BUCKET="$STACK_NAME-$REGION-codepipeline-$AWS_ACCOUNT_ID"

# Deploy setup.yml first
echo -e "\n\n======== Deploying setup.yml ========"
aws cloudformation deploy \
    --region $REGION \
    --profile $CLI_PROFILE \
    --stack-name $STACK_NAME-setup \
    --template-file setup.yml \
    --no-fail-on-empty-changeset \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
        CodePipelineBucket=$CODEPIPELINE_BUCKET

# Deploy the CloudFormation template
# Pass Github parameters to main.yml
echo -e "\n\n======== Deploying main.yml ========"
aws cloudformation deploy \
    --region $REGION \
    --profile $CLI_PROFILE \
    --stack-name $STACK_NAME \
    --template-file main.yml \
    --no-fail-on-empty-changeset \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
        EC2InstanceType=$EC2_INSTANCE_TYPE \
        GitHubOwner=$GH_OWNER \
        GitHubRepo=$GH_REPO \
        GitHubBranch=$GH_BRANCH \
        GitHubPersonalAccessToken=$GH_ACCESS_TOKEN \
        CodePipelineBucket=$CODEPIPELINE_BUCKET

# If the deploy succeeded, show the DNS name of instance
if [ $? -eq 0 ]; then
    aws cloudformation list-exports \
        --profile awsbootstrap \
        --query "Exports[?Name=='InstanceEndpoint'].Value"
fi
