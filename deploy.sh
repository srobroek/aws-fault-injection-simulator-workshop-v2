#!/bin/bash

#prechecks

test -n "$AWS_ACCESS_KEY_ID" || echo "AWS_ACCESS_KEY_ID is not set"
test -n "$AWS_SECRET_ACCESS_KEY" || echo "AWS_SECRET_ACCESS_KEY is not set"
test -n "$AWS_SESSION_TOKEN" || echo "AWS_SESSION_TOKEN is not set"

sudo yum install git docker nodejs -y
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo chmod +x kubectl
sudo mv kubectl /usr/local/bin

sudo usermod -aG docker ec2-user

sudo npm install -g aws-cdk
git clone https://github.com/srobroek/aws-fault-injection-simulator-workshop-v2
sudo service docker start
cd aws-fault-injection-simulator-workshop-v2/PetAdoptions/cdk/pet_stack || exit
npm install




newgrp docker
rm -vf ${HOME}/.aws/credentials
rm -vf ${HOME}/.aws/config
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 3600")
AWS_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)

test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || exit

export CDK_DEFAULT_ACCOUNT=$ACCOUNT_ID
export CDK_DEFAULT_REGION=$AWS_REGION

EKS_ADMIN_ARN=arn:aws:iam::$ACCOUNT_ID:role/Admin
#update the EKS ADMIN role to studio participant
CONSOLE_ROLE_ARN=$EKS_ADMIN_ARN


cdk bootstrap
cdk deploy --context admin_role="$EKS_ADMIN_ARN" Services --context dashboard_role_arn="$CONSOLE_ROLE_ARN" --require-approval never
export NO_PREBUILT_LAMBDA=1  && sudo cdk deploy Applications --require-approval never

cd ~/aws-fault-injection-simulator-workshop-v2 || exit
#create cross account role
export IAM_ROLE=$(aws iam create-role --role-name fis-multiaccount-role --assume-role-policy-document file://fis-iam-trustpolicy.json)
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --role-name fis-multiaccount-role

export TF_ROLE=$(aws iam create-role --role-name terraform-role --assume-role-policy-document file://tf-iam-trustpolicy.json)

aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --role-name terraform-role

#remove admin permissions from participant
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --role-name WSParticipantRole
aws iam detach-role-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --role-name WSParticipantRole

aws eks update-kubeconfig --name PetSite --region $AWS_REGION


kubectl apply -f eks-rbac.yaml
eksctl create iamidentitymapping --arn arn:aws:iam::$ACCOUNT_ID:role/fis-multiaccount --username fis-experiment --cluster PetSite --region=$AWS_REGION

#TODO add permissions to restrict access to various services
