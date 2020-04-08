REGION=$1
CLUSTER_NAME=$2
STACK_NAME=$3

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

IFS=',' read -r -a array <<< "$RESULTS_ARRAY"
SUBNETS="${array[0]} ${array[1]} ${array[2]} ${array[3]}"

aws eks create-nodegroup \
--cluster-name $CLUSTER_NAME \
--nodegroup-name $STACK_NAME \
--instance-types t3.micro \
--ami-type AL2_x86_64 \
--scaling-config minSize=1,maxSize=4,desiredSize=2 \
--node-role $GET_ROLE \
--subnets $SUBNETS

printf  "Inserir as credenciais do ECR especificadas no ficheiro credenciais.txt\n"
aws configure

aws ecr get-login-password --region eu-west-1 | sudo docker login --username AWS --password-stdin 774440115756.dkr.ecr.eu-west-1.amazonaws.com

sudo docker pull 774440115756.dkr.ecr.eu-west-1.amazonaws.com/events:v1
sudo docker pull 774440115756.dkr.ecr.eu-west-1.amazonaws.com/products:v1