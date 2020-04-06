REGION=$1
CLUSTER_NAME=$2

printf  "Inserir as credenciais do ECR de admin da sua conta\n"
aws configure

REPO_EVENTS=`aws ecr create-repository \
			--region $REGION \
			--repository-name "events" \
			--query "repository.repositoryUri" \
			--output text`

REPO_PRODUCTS=`aws ecr create-repository \
			--region $REGION \
			--repository-name "products" \
			--query "repository.repositoryUri" \
			--output text`

sudo docker tag 774440115756.dkr.ecr.eu-west-1.amazonaws.com/events:v1 $REPO_EVENTS:v1
sudo docker tag 774440115756.dkr.ecr.eu-west-1.amazonaws.com/products:v1 $REPO_PRODUCTS:v1

sudo push $REPO_EVENTS:v1
sudo push $REPO_PRODUCTS:v1

kubectl run $CLUSTER_NAME --image=$REPO_EVENTS:v1 --port=3000
kubectl run $CLUSTER_NAME --image=$REPO_PRODUCTS:v1 --port=3000