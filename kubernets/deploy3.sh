REGION=$1
CLUSTER_NAME=$2


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

aws ecr get-login-password --region $REGION| sudo docker login --username AWS --password-stdin $REPO_EVENTS
sudo docker tag 774440115756.dkr.ecr.eu-west-1.amazonaws.com/events:v1 $REPO_EVENTS:v1
sudo docker push $REPO_EVENTS:v1

aws ecr get-login-password --region $REGION | sudo docker login --username AWS --password-stdin $REPO_PRODUCTS
sudo docker tag 774440115756.dkr.ecr.eu-west-1.amazonaws.com/products:v1 $REPO_PRODUCTS:v1
sudo docker push $REPO_PRODUCTS:v1

printf "Inserir dados presentes no ficheiro credenciais_mongo.txt\n"
aws configure

aws ecr get-login-password --region $REGION| sudo docker login --username AWS --password-stdin 982606647141.dkr.ecr.eu-west-1.amazonaws.com/database
sudo docker pull 982606647141.dkr.ecr.eu-west-1.amazonaws.com/database:v1

printf "Insira as suas credenciais de admin aws\n"
aws configure

REPO_DATABASE=`aws ecr create-repository \
			--region $REGION \
			--repository-name "database" \
			--query "repository.repositoryUri" \
			--output text`

aws ecr get-login-password --region $REGION| sudo docker login --username AWS --password-stdin $REPO_DATABASE
sudo docker tag 982606647141.dkr.ecr.eu-west-1.amazonaws.com/database:v1 $REPO_DATABASE:v1
sudo docker push $REPO_DATABASE:v1

GET_ROLE=$(aws iam create-policy \
    --policy-name ALBIngressControllerIAMPolicyEcommerce \
    --policy-document file://ingress/ingress-role.json | jq '.Policy.Arn' -r);

aws iam attach-role-policy \
    --policy-arn $GET_ROLE \
    --role-name eksServiceRole

printf $GET_ROLE

mkdir events
mkdir products

echo "apiVersion: v1
kind: Pod
metadata:
  name: events
  labels:
    name: events
spec:
  containers:
  - name: events
    image: $REPO_EVENTS:v1
    ports:
    - containerPort: 3000" > events/events-pod.yml

echo "apiVersion: v1
kind: Service
metadata:
  name: events
spec:
  selector:
    app: ecommerce-api
  ports:
  - protocol: TCP
    port: 3000
    targetPort: 3000
  type: NodePort" > events/events-service.yml

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: events-deployment
  labels:
    app: ecommerce-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ecommerce-api
  template:
    metadata:
      labels:
        app: ecommerce-api
    spec:
      containers:
      - name: events
        image: $REPO_EVENTS:v1
        ports:
        - containerPort: 3000" > events/events-deployment.yml

echo "apiVersion: v1
kind: Pod
metadata:
  name: products
  labels:
    name: products
spec:
  containers:
  - name: products
    image: $REPO_PRODUCTS:v1
    ports:
    - containerPort: 3000" > products/products-pod.yml

echo "apiVersion: v1
kind: Service
metadata:
  name: products
spec:
  selector:
    app: ecommerce-api
  ports:
  - protocol: TCP
    port: 3000
    targetPort: 3000
  type: NodePort" > products/products-service.yml

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: products-deployment
  labels:
    app: ecommerce-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ecommerce-api
  template:
    metadata:
      labels:
        app: ecommerce-api
    spec:
      containers:
      - name: products
        image: $REPO_PRODUCTS:v1
        ports:
        - containerPort: 3000" > products/products-deployment.yml

mkdir database

echo "apiVersion: v1
kind: Pod
metadata:
  name: database
  labels:
    name: database
spec:
  containers:
  - name: database
    image:  $REPO_DATABASE:v1
    ports:
    - containerPort: 27017" > database/database-pod.yml

echo "apiVersion: v1
kind: Service
metadata:
  name: database
spec:
  selector:
    app: ecommerce-api
  ports:
  - protocol: TCP
    port: 27017
    targetPort: 27017
  type: NodePort" > database/database-service.yml

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: database-deployment
  labels:
    app: ecommerce-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ecommerce-api
  template:
    metadata:
      labels:
        app: ecommerce-api
    spec:
      containers:
      - name: database
        image:  $REPO_DATABASE:v1
        ports:
        - containerPort: 27017" > database/database-deployment.yml