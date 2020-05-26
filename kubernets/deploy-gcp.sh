PROJECT_NAME='new-test-project-277912'
ACCOUNT_NAME="test-account"
BUCKET_NAME="cn-ecomm-test"

#Authenticates user
gcloud auth login
#Define which project to work on
gcloud config set project $PROJECT_NAME

#Hardcoded zone (can be given by input but minimizes errors)
gcloud config set compute/zone europe-west1-b

#Enable the kubernetes API
gcloud services enable container.googleapis.com
gcloud services enable dataproc.googleapis.com
gcloud services enbale cloudbuild.googleapis.com

#creates a new owner account and the respective keyfile for authorization purposes
gcloud iam service-accounts create $ACCOUNT_NAME
gcloud projects add-iam-policy-binding $PROJECT_NAME--member "serviceAccount:${ACCOUNT_NAME}@${PROJECT_NAME}.iam.gserviceaccount.com" --role "roles/owner"
gcloud iam service-accounts keys create creds.json --iam-account $ACCOUNT_NAME@$PROJECT_NAME.iam.gserviceaccount.com

#create bucket
gsutil mb -p ${PROJECT_NAME} -l europe-west1 gs://$BUCKET_NAME/

#These scripts generate the query files with the bucket name.
#The file names will be Query1-3.py
./write-spark2.sh $BUCKET_NAME
./write-spark1.sh $BUCKET_NAME
./write-spark3.sh $BUCKET_NAME

#push pyspark queries to bucket
gsutil cp ./Query1.py gs://$BUCKET_NAME/
gsutil cp ./Query2.py gs://$BUCKET_NAME/
gsutil cp ./Query3.py gs://$BUCKET_NAME/

#create cluster
gcloud container clusters create ecommerce-cluster --num-nodes=1 --machine-type=n1-standard-1 #--scopes=storage-rw
gcloud config set container/cluster ecommerce-cluster
gcloud container clusters get-credentials ecommerce-cluster

gsutil cp gs://cn-ecommerce-container/spark-svc.zip .
gsutil cp gs://cn-ecommerce-container/events.zip .
gsutil cp gs://cn-ecommerce-container/products.zip .
gsutil cp gs://cn-ecommerce-container/database.zip .
gsutil cp  gs://cn-ecommerce-container/database.zip .
gsutil cp  gs://cn-ecommerce-container/database.csv gs://$BUCKET_NAME/

unzip spark-svc.zip
cp creds.json spark-svc
rm -f creds.json

rm -f spark-svc.zip

cd events
docker build -t gcr.io/$PROJECT_NAME/events:v1 .
cd ../products
docker build -t gcr.io/$PROJECT_NAME/products:v1 .
cd ../database
docker build -t gcr.io/$PROJECT_NAME/database:v1 .
cd ../spark-svc 
docker build -t gcr.io/$PROJECT_NAME/spark-svc:v1 .
cd ..
rm -rf events products database spark-svc

gcloud auth configure-docker

docker push gcr.io/$PROJECT_NAME/events:v1
docker push gcr.io/$PROJECT_NAME/products:v1
docker push gcr.io/$PROJECT_NAME/database:v1
docker push gcr.io/$PROJECT_NAME/spark-svc:v1

mkdir events-kubernetes
mkdir products-kubernetes
mkdir ingress-kubernetes
mkdir database-kubernetes
mkdir spark-svc-kubernetes

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: svc
  namespace: default
spec:
  selector:
    matchLabels:
      run: svc
  template:
    metadata:
      labels:
        run: svc
    spec:
      containers:
      - image: gcr.io/$PROJECT_NAME/spark-svc:v1
        imagePullPolicy: IfNotPresent
        name: svc
        readinessProbe:
          httpGet:
            path: /
            port: 3000
        ports:
        - containerPort: 3000
          protocol: TCP" > spark-svc-kubernetes/svc-deployment.yaml

echo "apiVersion: v1
kind: Service
metadata:
  name: svc
  namespace: default
  annotations:
    beta.cloud.google.com/backend-config: '{\"ports\": {\"3000\":\"my-bsc-backendconfig\"}}'
spec:
  ports:
  - protocol: TCP
    port: 3000
    targetPort: 3000
  selector:
    run: svc
  type: NodePort" > spark-svc-kubernetes/svc-service.yaml

echo "apiVersion: cloud.google.com/v1beta1
kind: BackendConfig
metadata:
  name: my-bsc-backendconfig
spec:
  timeoutSec: 1200
" > timeout-config.yaml


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
          servicePort: 3000
      - path: /api/spark/*
        backend:
          serviceName: svc
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

kubectl apply -f timeout-config.yaml
kubectl apply -f spark-svc-kubernetes/svc-deployment.yaml
kubectl apply -f spark-svc-kubernetes/svc-service.yaml