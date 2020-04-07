REGION=$1
NODES_EVT_NAME=$2
NODES_PRO_NAME=$3

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

aws ecr get-login-password --region eu-west-1 | sudo docker login --username AWS --password-stdin $REPO_EVENTS
sudo docker tag 774440115756.dkr.ecr.eu-west-1.amazonaws.com/events:v1 $REPO_EVENTS:v1
sudo docker push $REPO_EVENTS:v1

aws ecr get-login-password --region eu-west-1 | sudo docker login --username AWS --password-stdin $REPO_PRODUCTS
sudo docker tag 774440115756.dkr.ecr.eu-west-1.amazonaws.com/products:v1 $REPO_PRODUCTS:v1
sudo docker push $REPO_PRODUCTS:v1

kubectl run $NODES_EVT_NAME --image=$REPO_EVENTS:v1 --port=3000
kubectl run $NODES_PRO_NAME --image=$REPO_PRODUCTS:v1 --port=3000