PROJECT_NAME="new-test-project-277912"
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
gcloud services enable cloudbuild.googleapis.com

#TODO UNCOMMENT THIS AFTER TESTING
#creates a new owner account and the respective keyfile for authorization purposes
#gcloud iam service-accounts create $ACCOUNT_NAME
#gcloud projects add-iam-policy-binding $PROJECT_NAME --member "serviceAccount:${ACCOUNT_NAME}@${PROJECT_NAME}.iam.gserviceaccount.com" --role "roles/owner"
#gcloud iam service-accounts keys create creds.json --iam-account $ACCOUNT_NAME@$PROJECT_NAME.iam.gserviceaccount.com

#create bucket
#gsutil mb -p ${PROJECT_NAME} -l europe-west1 gs://$BUCKET_NAME/

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
#TODO change num nodes when quota is higher
gcloud container clusters create ecommerce-cluster --num-nodes=1 --machine-type=n1-standard-1 #--scopes=storage-rw
gcloud config set container/cluster ecommerce-cluster
gcloud container clusters get-credentials ecommerce-cluster

gsutil cp gs://cn-ecommerce-container/spark-svc.zip .

#TODO uncomment spark related lines
unzip spark-svc.zip
#cp creds.json spark-svc
#rm -f creds.json

rm -f spark-svc.zip

#Writes the backend file for the query with the given project and bucket names
./write-backend.sh $PROJECT_NAME $BUCKET_NAME

cd spark-svc 
#sudo docker build -t gcr.io/$PROJECT_NAME/spark-svc:v1 .
docker build -t gcr.io/$PROJECT_NAME/spark-svc:v1 .
cd ..
rm -rf spark-svc

#Pus sudo nestes dois comandos, o resto segui o que foi indicado
gcloud auth configure-docker
docker push gcr.io/$PROJECT_NAME/spark-svc:v1

mkdir spark-svc-kubernetes
mkdir ingress-kubernetes

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

echo "apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: fanout-ingress
spec:
  rules:
  - http:
      paths:
      - path: /api/spark/*
        backend:
          serviceName: svc
          servicePort: 3000" > ingress-kubernetes/fanout-ingress.yaml

kubectl apply -f timeout-config.yaml
kubectl apply -f spark-svc-kubernetes/svc-deployment.yaml
kubectl apply -f spark-svc-kubernetes/svc-service.yaml

kubectl apply -f ingress-kubernetes/fanout-ingress.yaml