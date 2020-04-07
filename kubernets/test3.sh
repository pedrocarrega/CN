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
    - containerPort: 3000" > events-pod.yml

echo "apiVersion: v1
kind: Service
metadata:
  name: events
spec:
  selector:
    app: events
  ports:
  - protocol: TCP
    port: 3000
    targetPort: 3000" > events-service.yml

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: events-deployment
  labels:
    app: events
spec:
  replicas: 1
  selector:
    matchLabels:
      app: events
  template:
    metadata:
      labels:
        app: events
    spec:
      containers:
      - name: events
        image: $REPO_EVENTS:v1
        ports:
        - containerPort: 3000" > events-deployment.yml

kubectl apply -f events-pod.yml
kubectl apply -f events-service.yml
kubectl apply -f events-deploy.yml
kubectl expose deployment events-deployment --type=LoadBalancer --port=3000

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
    - containerPort: 3000" > products-pod.yml

echo "apiVersion: v1
kind: Service
metadata:
  name: products
spec:
  selector:
    app: products
  ports:
  - protocol: TCP
    port: 3000
    targetPort: 3000" > products-service.yml

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: products-deployment
  labels:
    app: products
spec:
  replicas: 1
  selector:
    matchLabels:
      app: products
  template:
    metadata:
      labels:
        app: products
    spec:
      containers:
      - name: products
        image: $REPO_PRODUCTS:v1
        ports:
        - containerPort: 3000" > events-deployment.yml

kubectl apply -f products-pod.yml
kubectl apply -f products-service.yml
kubectl apply -f products-deploy.yml
kubectl expose deployment products-deployment --type=LoadBalancer --port=3000