REGION=$1
CLUSTER_NAME=$2
STACK_NAME=$3

aws iam add-role-to-instance-profile --role-name Test-Role --instance-profile-name Webserver

ENDPOINT=$(aws eks --region $REGION describe-cluster --name $CLUSTER_NAME  --query "cluster.endpoint" --output text)

CERTIFICATE=$(aws eks --region $REGION describe-cluster --name $CLUSTER_NAME  --query "cluster.certificateAuthority.data" --output text)

aws eks --region $REGION update-kubeconfig --name $CLUSTER_NAME

GET_ROLE=$(aws iam get-role --role-name eksServiceRole | jq '.Role.Arn' -r);

QUERY=$(cat <<-EOF
[
	Stacks[0].Outputs[?OutputKey==\`SubnetIds\`].OutputValue
]
EOF)

RESULTS=$(aws cloudformation describe-stacks \
	--stack-name $STACK_NAME \
	--region $REGION \
	--query "$QUERY" \
	--output text);
RESULTS_ARRAY=($RESULTS)

IFS=', ' \'${RESULTS_ARRAY[0]}\' -r -a array <<< "$string"
SUBNETS=${string[0]} ${string[1]} ${string[2]} ${string[3]}

printf  "\`${array[0]}\`${NC}\n"

aws eks create-nodegroup \
--cluster-name $CLUSTER_NAME \
--nodegroup-name $STACK_NAME \
--instance-types t2.micro \
--ami-type AL2_x86_64 \
--scaling-config minSize=1,maxSize=4,desiredSize=3 \
--node-role $GET_ROLE \
--subnets $SUBNETS