PROJECT_NAME='new-test-project-277912'
ACCOUNT_NAME="test-account"
BUCKET_NAME="cn-ecomm-test"

#Authenticates user
#gcloud auth login

#Define which project to work on
gcloud config set project $PROJECT_NAME

#Shouldnt be needed as project will be created manually
#gcloud beta billing projects link $PROJECT_NAME --billing-account=$BILLING_ACCOUNT_ID

#Hardcoded zone (can be given by input but minimizes errors)
gcloud config set compute/zone europe-west1-b

#Enable the kubernetes API
gcloud services enable container.googleapis.com
gcloud services enable dataproc.googleapis.com

#TODO UNCOMMENT THIS AFTER TESTING
#creates a new owner account and the respective keyfile for authorization purposes
#gcloud iam service-accounts create $ACCOUNT_NAME
#gcloud projects add-iam-policy-binding $PROJECT_NAME--member "serviceAccount:${ACCOUNT_NAME}@${PROJECT_NAME}.iam.gserviceaccount.com" --role "roles/owner"
#gcloud iam service-accounts keys create creds.json --iam-account $ACCOUNT_NAME@$PROJECT_NAME.iam.gserviceaccount.com
#TODO move creds.json inside every spark service folder

#create bucket
#gsutil mb -p ${PROJECT_NAME} -l europe-west1 gs://$BUCKET_NAME/
#push pyspark queries to bucket
#Change the name of the files
#gsutil cp ./query1.py gs://$BUCKET_NAME/
#gsutil cp ./Query2.py gs://$BUCKET_NAME/
#gsutil cp ./query3.py gs://$BUCKET_NAME/


#create cluster
#TODO change num nodes when quota is higher
gcloud container clusters create ecommerce-cluster --num-nodes=1 --machine-type=n1-standard-1 #--scopes=storage-rw
gcloud config set container/cluster ecommerce-cluster
gcloud container clusters get-credentials ecommerce-cluster

gsutil cp gs://cn-ecommerce-container/events.zip .
gsutil cp gs://cn-ecommerce-container/products.zip .
gsutil cp gs://cn-ecommerce-container/database.zip .
#TODO place the zip in the bucket
gsutil cp gs://cn-ecommerce-container/spark-svc2.zip .

#TODO uncomment spark related lines
unzip events.zip
unzip products.zip
unzip database.zip
unzip spark-svc2.zip
#cp creds.json spark-svc2
#cp creds.json spark-svc1
#cp creds.json spark-svc3

rm -f events.zip
rm -f products.zip
rm -f database.zip
rm -f spark-svc2.zip
#rm -f spark-svc1.zip
#rm -f spark-svc3.zip

#TODO adicionar ficheiros relativos aos restantes serviços
cd events
sudo docker build -t gcr.io/$PROJECT_NAME/events:v1 .
cd ../products
sudo docker build -t gcr.io/$PROJECT_NAME/products:v1 .
cd ../database
sudo docker build -t gcr.io/$PROJECT_NAME/database:v1 .
cd ../spark-svc2 
sudo docker build -t gcr.io/$PROJECT_NAME/spark-svc2:v1
cd ..
rm -rf events products database spark-svc2

sudo gcloud auth configure-docker

#TODO Sudo nao funciona com o usermod (falta de perms)
#sudo docker push gcr.io/$PROJECT_NAME/events:v1
#sudo docker push gcr.io/$PROJECT_NAME/products:v1
#sudo docker push gcr.io/$PROJECT_NAME/database:v1
#sudo docker push gcr.io/$PROJECT_NAME/spark-svc2:v1


docker push gcr.io/$PROJECT_NAME/events:v1
docker push gcr.io/$PROJECT_NAME/products:v1
docker push gcr.io/$PROJECT_NAME/database:v1
docker push gcr.io/$PROJECT_NAME/spark-svc2:v1

mkdir events-kubernetes
mkdir products-kubernetes
mkdir ingress-kubernetes
mkdir database-kubernetes
mkdir spark-svc1-kubernetes
mkdir spark-svc2-kubernetes
mkdir spark-svc3-kubernetes

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: svc2
  namespace: default
spec:
  selector:
    matchLabels:
      run: svc2
  template:
    metadata:
      labels:
        run: svc2
    spec:
      containers:
      - image: gcr.io/$PROJECT_NAME/svc2:v1
        imagePullPolicy: IfNotPresent
        name: svc2
        ports:
        - containerPort: 3000
          protocol: TCP" > spark-svc2-kubernetes/svc2-deployment.yaml


echo "apiVersion: v1
kind: Service
metadata:
  name: svc2
  namespace: default
spec:
  ports:
  - protocol: TCP
    port: 3000
    targetPort: 3000
  selector:
    run: svc2
  type: NodePort" > spark-svc2-kubernetes/svc2-service.yaml


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
      - path: /api/spark/svc2/*
        backend:
          serviceName: svc2
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

kubectl apply -f spark-svc2-kubernetes/svc2-deployment.yaml
kubectl apply -f spark-svc2-kubernetes/svc2-service.yaml