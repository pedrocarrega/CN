PROJECT_NAME="ecommerce-teste4"
BILLING_ACCOUNT_ID=$1

#Authenticates user
gcloud auth login
gcloud projects create $PROJECT_NAME

#Define which project to work on
gcloud config set project $PROJECT_NAME

gcloud beta billing projects link $PROJECT_NAME --billing-account=$BILLING_ACCOUNT_ID

#Hardcoded zone (can be given by input but minimizes errors)
gcloud config set compute/zone europe-west1

#Enable the kubernetes API
gcloud services enable container.googleapis.com

#create cluster
gcloud container clusters create ecommerce-cluster --num-nodes=1 #--scopes=storage-rw
gcloud config set container/cluster ecommerce-cluster
gcloud container clusters get-credentials ecommerce-cluster

gsutil cp gs://cn-ecommerce-container/events.zip .
gsutil cp gs://cn-ecommerce-container/products.zip .
gsutil cp gs://cn-ecommerce-container/database.zip .

unzip events.zip
unzip products.zip
unzip database.zip

cd events
sudo docker build -t gcr.io/$PROJECT_NAME/events:v1 .
cd ../products
sudo docker build -t gcr.io/$PROJECT_NAME/products:v1 .
cd ../database
sudo docker build -t gcr.io/$PROJECT_NAME/database:v1 .
cd ..

gcloud auth configure-docker

sudo docker push gcr.io/$PROJECT_NAME/events:v1
sudo docker push gcr.io/$PROJECT_NAME/products:v1
sudo docker push gcr.io/$PROJECT_NAME/database:v1

mkdir events-kubernetes
mkdir products-kubernetes
mkdir ingress-kubernetes
mkdir database-kubernetes

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: events
  namespace: default
spec:
  selector:
    matchLabels:
      run: events
  template:
    metadata:
      labels:
        run: events
    spec:
      containers:
      - image: gcr.io/$PROJECT_NAME/events:v1
        imagePullPolicy: IfNotPresent
        name: events
        ports:
        - containerPort: 3000
          protocol: TCP" > events-kubernetes/events-deployment.yaml
          
echo "apiVersion: v1
kind: Service
metadata:
  name: events
  namespace: default
spec:
  ports:
  - protocol: TCP
    port: 3000
    targetPort: 3000
  selector:
    run: events
  type: NodePort" > events-kubernetes/events-service.yaml
  
echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: products
  namespace: default
spec:
  selector:
    matchLabels:
      run: products
  template:
    metadata:
      labels:
        run: products
    spec:
      containers:
      - image: gcr.io/$PROJECT_NAME/products:v1
        imagePullPolicy: IfNotPresent
        name: products
        ports:
        - containerPort: 3000
          protocol: TCP" > products-kubernetes/products-deployment.yaml
          
echo "apiVersion: v1
kind: Service
metadata:
  name: products
  namespace: default
spec:
  ports:
  - protocol: TCP
    port: 3000
    targetPort: 3000
  selector:
    run: products
  type: NodePort" > products-kubernetes/products-service.yaml
  
echo "apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: fanout-ingress
spec:
  rules:
  - http:
      paths:
      - path: /api/events/*
        backend:
          serviceName: events
          servicePort: 3000
      - path: /api/products/*
        backend:
          serviceName: products
          servicePort: 3000" > ingress-kubernetes/fanout-ingress.yaml
          
echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: default
spec:
  selector:
    matchLabels:
      run: database
  template:
    metadata:
      labels:
        run: database
    spec:
      containers:
      - image: gcr.io/$PROJECT_NAME/database:v1
        imagePullPolicy: IfNotPresent
        name: database
        ports:
        - containerPort: 27017" > database-kubernetes/database-deployment.yaml
        
echo "apiVersion: v1
kind: Service
metadata:
  name: database
  namespace: default
spec:
  ports:
  - protocol: TCP
    port: 27017
    targetPort: 27017
  selector:
    run: database
  type: NodePort" > database-kubernetes/database-service.yaml
  
kubectl apply -f ingress-kubernetes/fanout-ingress.yaml

kubectl apply -f events-kubernetes/events-service.yaml
kubectl apply -f events-kubernetes/events-deployment.yaml

kubectl apply -f products-kubernetes/products-service.yaml
kubectl apply -f products-kubernetes/products-deployment.yaml

kubectl apply -f database-kubernetes/database-deployment.yaml
kubectl apply -f database-kubernetes/database-service.yaml
