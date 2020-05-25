PROJECT_NAME='logical-codex-275717'
ACCOUNT_NAME="test-account43521112"
BUCKET_NAME="cn-ecomm-test987"

#Authenticates user
gcloud auth login
#Define which project to work on
gcloud config set project $PROJECT_NAME

#Shouldnt be needed as project will be created manually
#gcloud beta billing projects link $PROJECT_NAME --billing-account=$BILLING_ACCOUNT_ID

#Hardcoded zone (can be given by input but minimizes errors)
gcloud config set compute/zone europe-west1-b

#Enable the kubernetes API
gcloud services enable container.googleapis.com
gcloud services enable dataproc.googleapis.com
gcloud services enable cloudbuild.googleapis.com

#TODO UNCOMMENT THIS AFTER TESTING
#creates a new owner account and the respective keyfile for authorization purposes
gcloud iam service-accounts create $ACCOUNT_NAME
gcloud projects add-iam-policy-binding $PROJECT_NAME --member "serviceAccount:${ACCOUNT_NAME}@${PROJECT_NAME}.iam.gserviceaccount.com" --role "roles/owner"
gcloud iam service-accounts keys create creds.json --iam-account $ACCOUNT_NAME@$PROJECT_NAME.iam.gserviceaccount.com

#create bucket
gsutil mb -p ${PROJECT_NAME} -l europe-west1 gs://$BUCKET_NAME/

#These scripts generate the query files with the bucket name.
#The file names will be Query1-3.py
./write-spark2.sh $BUCKET_NAME
#./write-spark1.sh $BUCKET_NAME
#./write-spark3.sh $BUCKET_NAME

#push pyspark queries to bucket
#gsutil cp ./Query1.py gs://$BUCKET_NAME/
gsutil cp ./Query2.py gs://$BUCKET_NAME/
#gsutil cp ./Query3.py gs://$BUCKET_NAME/


#create cluster
#TODO change num nodes when quota is higher
gcloud container clusters create ecommerce-cluster --num-nodes=1 --machine-type=n1-standard-1 #--scopes=storage-rw
gcloud config set container/cluster ecommerce-cluster
gcloud container clusters get-credentials ecommerce-cluster

#TODO place the zip files inside the public bucket
gsutil cp gs://cn-ecommerce-container/spark-svc2.zip .
#gsutil cp gs://cn-ecommerce-container/spark-svc1.zip .
#gsutil cp gs://cn-ecommerce-container/spark-svc3.zip .

#TODO uncomment spark related lines
unzip spark-svc2.zip
#unzip spark-svc1.zip
#unzip spark-svc3.zip
cp creds.json spark-svc2
#cp creds.json spark-svc1
#cp creds.json spark-svc3
#rm -f creds.json

rm -f spark-svc2.zip
#rm -f spark-svc1.zip
#rm -f spark-svc3.zip

#Writes the backend file for the query with the given project and bucket names
./write-backend2.sh $PROJECT_NAME $BUCKET_NAME
#./write-backend1.sh $PROJECT_NAME $BUCKET_NAME
#./write-backend3.sh $PROJECT_NAME $BUCKET_NAME

cd spark-svc2 
#sudo docker build -t gcr.io/$PROJECT_NAME/spark-svc2:v1 .
docker build -t gcr.io/$PROJECT_NAME/spark-svc2:v1 .
cd ..
rm -rf spark-svc2

#Pus sudo nestes dois comandos, o resto segui o que foi indicado
sudo gcloud auth configure-docker

sudo docker push gcr.io/$PROJECT_NAME/spark-svc2:v1

mkdir spark-svc2-kubernetes
mkdir ingress-kubernetes

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
      - image: gcr.io/$PROJECT_NAME/spark-svc2:v1
        imagePullPolicy: IfNotPresent
        name: svc2
        readinessProbe:
          httpGet:
            path: /
            port: 3000
        ports:
        - containerPort: 3000
          protocol: TCP" > spark-svc2-kubernetes/svc2-deployment.yaml


echo "apiVersion: v1
kind: Service
metadata:
  name: svc2
  namespace: default
  annotations:
    beta.cloud.google.com/backend-config: '{\"ports\": {\"3000\":\"my-bsc-backendconfig\"}}'
spec:
  ports:
  - protocol: TCP
    port: 3000
    targetPort: 3000
  selector:
    run: svc2
  type: NodePort" > spark-svc2-kubernetes/svc2-service.yaml

echo "apiVersion: cloud.google.com/v1beta1
kind: BackendConfig
metadata:
  name: my-bsc-backendconfig
spec:
  timeoutSec: 600
" > timeout-config.yaml

echo "apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: fanout-ingress
spec:
  rules:
  - http:
      paths:
      - path: /api/spark/svc2/*
        backend:
          serviceName: svc2
          servicePort: 3000" > ingress-kubernetes/fanout-ingress.yaml

kubectl apply -f timeout-config.yaml
kubectl apply -f spark-svc2-kubernetes/svc2-deployment.yaml
kubectl apply -f spark-svc2-kubernetes/svc2-service.yaml

kubectl apply -f ingress-kubernetes/fanout-ingress.yaml