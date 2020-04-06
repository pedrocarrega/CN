REGION=$1

VPC_STACKNAME=$2

printf "REGION: \`${REGION}\`${NC}\n"
printf "VPC STACK: \`${VPC_STACKNAME}\`${NC}\n"

#aws iam create-role --role-name eksServiceRole --assume-role-policy-document file://assume-role.json --description "Allows EKS to manage clusters on your behalf."

#aws iam attach-role-policy --role-name eksServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

#aws iam attach-role-policy --role-name eksServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSServicePolicy


QUERY=$(cat <<-EOF
[
	Stacks[0].Outputs[?OutputKey==\`SecurityGroups\`].OutputValue,
	Stacks[0].Outputs[?OutputKey==\`VpcId\`].OutputValue,
	Stacks[0].Outputs[?OutputKey==\`SubnetIds\`].OutputValue
]
EOF)


RESULTS=$(aws cloudformation describe-stacks \
	--stack-name eks-vpc \
	--region eu-west-1 \
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

printf  "\`${GET_ROLE}\`${NC}\n"

printf " subnetIds= ${RESULTS_ARRAY[2]},securityGroupIds=${RESULTS_ARRAY[0]} \n\n\n"

aws eks  create-cluster --region $REGION \
   --name cn_group --kubernetes-version 1.15 \
   --role-arn \
      $GET_ROLE \
   --resources-vpc-config subnetIds=${RESULTS_ARRAY[2]},securityGroupIds=${RESULTS_ARRAY[0]}