REGION=$1
CLUSTER_NAME=$2

printf  "Inserir as credenciais de acesso ao ECR ou de admin da conta de AWS:\n"
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

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/aws/service-l4.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/aws/patch-configmap-l4.yaml


eksctl utils associate-iam-oidc-provider \
    --region $REGION \
    --cluster $CLUSTER_NAME \
    --approve

GET_ROLE=$(aws iam create-policy \
    --policy-name ALBIngressControllerIAMPolicy \
    --policy-document file://ingress/ingress-role.json | jq '.Policy.Arn' -r);

kubectl apply -f ingress/ingress-controller.yaml

kubectl annotate serviceaccount -n kube-system alb-ingress-controller $GET_ROLE

kubectl apply -f ingress/ingress-deploy.yaml

curl -sS "https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/alb-ingress-controller.yaml" \
     | sed "s/# - --cluster-name=devCluster/- --cluster-name=$CLUSTER_NAME/g" \
     | kubectl apply -f -

kubectl apply -f ingress/api-ingress.yaml

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
    targetPort: 3000" > events/events-service.yml

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: events-deployment
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
      - name: events
        image: $REPO_EVENTS:v1
        ports:
        - containerPort: 3000" > events/events-deployment.yml

kubectl apply -f events/events-pod.yml
kubectl apply -f events/events-service.yml
kubectl apply -f events/events-deployment.yml
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
    targetPort: 3000" > products/products-service.yml

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: products-deployment
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
      - name: products
        image: $REPO_PRODUCTS:v1
        ports:
        - containerPort: 3000" > products/products-deployment.yml

kubectl apply -f products/products-pod.yml
kubectl apply -f products/products-service.yml
kubectl apply -f products/products-deployment.yml
kubectl expose deployment products-deployment --type=LoadBalancer --port=3000