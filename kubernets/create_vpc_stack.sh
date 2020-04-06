REGION=$1

aws cloudformation deploy --template-file amazon-eks-vpc-private-subnets.yaml --region $1 --stack-name eks-vpc --capabilities CAPABILITY_NAMED_IAM