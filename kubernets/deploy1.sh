REGION=$1
CLUSTER_NAME=$2
STACK_NAME=$3

printf "REGION: ${REGION}\n"
printf "CLUSTER NAME: ${CLUSTER_NAME}\n"
printf "VPC STACK: ${STACK_NAME}\n"


aws iam create-role --role-name eksServiceRole --assume-role-policy-document file://eks-service-role/assume-role.json --description "Allows EKS to manage clusters on your behalf."

aws iam attach-role-policy --role-name eksServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam attach-role-policy --role-name eksServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSServicePolicy
aws iam attach-role-policy --role-name eksServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
aws iam attach-role-policy --role-name eksServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
aws iam attach-role-policy --role-name eksServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

aws cloudformation deploy --template-file amazon-eks-vpc-private-subnets.yaml --region $REGION --stack-name $STACK_NAME --capabilities CAPABILITY_NAMED_IAM


QUERY=$(cat <<-EOF
[
	Stacks[0].Outputs[?OutputKey==\`SecurityGroups\`].OutputValue,
	Stacks[0].Outputs[?OutputKey==\`VpcId\`].OutputValue,
	Stacks[0].Outputs[?OutputKey==\`SubnetIds\`].OutputValue
]
EOF)


RESULTS=$(aws cloudformation describe-stacks \
	--stack-name $STACK_NAME \
	--region $REGION \
	--query "$QUERY" \
	--output text);
RESULTS_ARRAY=($RESULTS)

printf "Security Groups: \`${RESULTS_ARRAY[0]}\`${NC}\n"
printf "VPC_ID: \`${RESULTS_ARRAY[1]}\`${NC}\n"
printf "Subnets: \`${RESULTS_ARRAY[2]}\`${NC}\n"



QUERY2=$(cat <<-EOF
[
	Stacks[1].Outputs[?OutputKey==\`arn*\`].OutputValue
]
EOF)

GET_ROLE=$(aws iam get-role --role-name eksServiceRole | jq '.Role.Arn' -r);

aws eks  create-cluster --region $REGION \
   --name $CLUSTER_NAME --kubernetes-version 1.15 \
   --role-arn \
      $GET_ROLE \
   --resources-vpc-config subnetIds=${RESULTS_ARRAY[2]},securityGroupIds=${RESULTS_ARRAY[0]}