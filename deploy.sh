#!/bin/bash
sudo yum install git docker nodejs kubectl
sudo npm install -g aws-cdk
git clone https://github.com/aws-samples/aws-fault-injection-simulator-workshop-v2
sudo service docker start
cd aws-fault-injection-simulator-workshop-v2/PetAdoptions/cdk/pet_stack || exit
npm install
sudo cdk bootstrap




export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 3600")
AWS_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
EKS_ADMIN_ARN=arn:aws:iam::$ACCOUNT_ID:role/Admin
#update the EKS ADMIN role to studio participant
CONSOLE_ROLE_ARN=$EKS_ADMIN_ARN

sudo cdk deploy --context admin_role="$EKS_ADMIN_ARN" Services --context dashboard_role_arn="$CONSOLE_ROLE_ARN" --require-approval never
export NO_PREBUILT_LAMBDA=1  && sudo cdk deploy Applications --require-approval never


#create cross account role
export IAM_ROLE=$(aws iam create-role --role-name fis-multiaccount-role --assume-role-policy-document file://config/fis-iam-trustpolicy.json)
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --role-name fis-multiaccount-role
export IAM_ROLE=$(aws iam create-role --role-name ec2-multiaccount-role --assume-role-policy-document file://config/ec2-iam-trustpolicy.json)
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --role-name ec2-multiaccount-role


aws eks update-kubeconfig --name PetSite --region $AWS_REGION

kubectl apply -f config/eks-rbac.yaml
eksctl create iamidentitymapping --arn arn:aws:iam::$ACCOUNT_ID:role/fis-multiaccount --username fis-experiment --cluster PetSite --region=$AWS_REGION

#TODO add permissions to restrict access to various services
