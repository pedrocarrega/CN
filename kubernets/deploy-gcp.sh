PROJECT_NAME='cn-deploy'
ACCOUNT_NAME="test-account"
BUCKET_NAME="cn-bucket-test-20202020"
INITIAL_NODES="1"
CLUSTER_NAME="ecommerce-cluster27"
MACHINE_TYPE="n1-standard-1"
NODE_POOL_COUNT="1"
COMPUTE_ZONE="europe-west1-b"

#Authenticates user
gcloud auth login
#Define which project to work on
gcloud config set project $PROJECT_NAME

#Hardcoded zone (can be given by input but minimizes errors)
gcloud config set compute/zone $COMPUTE_ZONE

#Enable the kubernetes API
gcloud services enable container.googleapis.com
gcloud services enable dataproc.googleapis.com
gcloud services enable cloudbuild.googleapis.com

#creates a new owner account and the respective keyfile for authorization purposes
#gcloud iam service-accounts create $ACCOUNT_NAME
#gcloud projects add-iam-policy-binding $PROJECT_NAME --member "serviceAccount:${ACCOUNT_NAME}@${PROJECT_NAME}.iam.gserviceaccount.com" --role "roles/owner"
#gcloud iam service-accounts keys create creds.json --iam-account $ACCOUNT_NAME@$PROJECT_NAME.iam.gserviceaccount.com
#Variable used by terraform (inside terraform dir) to access the credentials
export GOOGLE_APPLICATION_CREDENTIALS="../creds.json"



mkdir terraform

echo "resource \"google_container_cluster\" \"default\" {
  name        = var.name
  project     = var.project
  description = \"Demo GKE Cluster\"
  location    = var.location

  remove_default_node_pool = true
  initial_node_count       = var.initial_node_count
  master_auth {
    username = \"\"
    password = \"\"
    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource \"google_container_node_pool\" \"default\" {
  name       = \"\${var.name}-node-pool\"
  project    = var.project
  location   = var.location
  cluster    = google_container_cluster.default.name
  node_count = ${NODE_POOL_COUNT}

  node_config {
    preemptible  = true
    machine_type = var.machine_type
    service_account = \"${ACCOUNT_NAME}@${PROJECT_NAME}.iam.gserviceaccount.com\"
    metadata = {
      disable-legacy-endpoints = \"true\"
    }

    oauth_scopes = [
      \"https://www.googleapis.com/auth/logging.write\",
      \"https://www.googleapis.com/auth/monitoring\",
      \"https://www.googleapis.com/auth/compute\",
      \"https://www.googleapis.com/auth/devstorage.read_only\"
    ]
  }
}

resource \"google_storage_bucket\" \"REGIONAL\" {
  name = \"${BUCKET_NAME}\"
  storage_class = \"REGIONAL\"
  force_destroy = true
  project = var.project
  location = var.bucket_location
}" > terraform/main.tf


echo "output \"endpoint\" {
  value = google_container_cluster.default.endpoint
}

output \"master_version\" {
  value = google_container_cluster.default.master_version
}
" > terraform/outputs.tf

echo "variable \"name\" {
  default = \"${CLUSTER_NAME}\"
}

variable \"project\" {
  default = \"${PROJECT_NAME}\"
}

variable \"location\" {
  default = \"${COMPUTE_ZONE}\"
}

variable \"bucket_location\" {
  default = \"europe-west1\"
}

variable \"initial_node_count\" {
  default = ${INITIAL_NODES}
}

variable \"machine_type\" {
  default = \"${MACHINE_TYPE}\"
}" > terraform/variables.tf

echo "terraform {
  required_version = \">= 0.12\"
}" > terraform/versions.tf

cd terraform

terraform init
terraform apply

cd ..

#create bucket
#gsutil mb -p ${PROJECT_NAME} -l europe-west1 gs://$BUCKET_NAME/

#These scripts generate the query files with the bucket name.
#The file names will be Query1-3.py
./spark-deploy/write-spark1.sh $BUCKET_NAME
./spark-deploy/write-spark2.sh $BUCKET_NAME
./spark-deploy/write-spark3.sh $BUCKET_NAME

#push pyspark queries to bucket
gsutil cp ./Query1.py gs://$BUCKET_NAME/
gsutil cp ./Query2.py gs://$BUCKET_NAME/
gsutil cp ./Query3.py gs://$BUCKET_NAME/

#create cluster

#gcloud container clusters create ecommerce-cluster --num-nodes=1 --machine-type=n1-standard-1
gcloud config set container/cluster ${CLUSTER_NAME}
gcloud container clusters get-credentials ${CLUSTER_NAME}

gsutil cp gs://cn-ecommerce-container/spark-svc.zip .
gsutil cp gs://cn-ecommerce-container/events.zip .
gsutil cp gs://cn-ecommerce-container/products.zip .
gsutil cp gs://cn-ecommerce-container/database.zip .
gsutil cp  gs://cn-ecommerce-container/dataset.csv gs://$BUCKET_NAME/

unzip events.zip
unzip products.zip
unzip database.zip
unzip spark-svc.zip

cp creds.json spark-svc

rm -f spark-svc.zip
rm -f events.zip
rm -f products.zip
rm -f database.zip

./write-backend.sh $PROJECT_NAME $BUCKET_NAME

cd events
docker build -t gcr.io/$PROJECT_NAME/events:v1 .
cd ../products
docker build -t gcr.io/$PROJECT_NAME/products:v1 .
cd ../database

sudo docker push gcr.io/$PROJECT_NAME/events:v1
sudo docker push gcr.io/$PROJECT_NAME/products:v1
sudo docker rmi gcr.io/$PROJECT_NAME/events:v1
sudo docker rmi gcr.io/$PROJECT_NAME/products:v1

docker build -t gcr.io/$PROJECT_NAME/database:v1 .
sudo docker push gcr.io/$PROJECT_NAME/database:v1
sudo docker rmi gcr.io/$PROJECT_NAME/database:v1
cd ../spark-svc 
rm -rf events products database
docker build -t gcr.io/$PROJECT_NAME/spark-svc:v1 .
sudo docker push gcr.io/$PROJECT_NAME/spark-svc:v1
sudo docker rmi gcr.io/$PROJECT_NAME/spark-svc:v1
cd ..
rm -rf spark-svc

sudo gcloud auth configure-docker

mkdir events-kubernetes
mkdir products-kubernetes
mkdir ingress-kubernetes
mkdir database-kubernetes
mkdir spark-svc-kubernetes

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: svc
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
      - path: /api/spark/*
        backend:
          serviceName: svc
          servicePort: 3000" > ingress-kubernetes/fanout-ingress.yaml
          
echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
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
spec:
  ports:
  - protocol: TCP
    port: 27017
    targetPort: 27017
  selector:
    run: database
  type: NodePort" > database-kubernetes/database-service.yaml

#kubectl apply -f events-kubernetes/events-service.yaml
#kubectl apply -f events-kubernetes/events-deployment.yaml

#kubectl apply -f products-kubernetes/products-service.yaml
#kubectl apply -f products-kubernetes/products-deployment.yaml

#kubectl apply -f database-kubernetes/database-deployment.yaml
#kubectl apply -f database-kubernetes/database-service.yaml

kubectl apply -f timeout-config.yaml
kubectl apply -f spark-svc-kubernetes/svc-deployment.yaml
kubectl apply -f spark-svc-kubernetes/svc-service.yaml

kubectl apply -f ingress-kubernetes/fanout-ingress.yaml

rm -f Query1.py
rm -f Query2.py
rm -f Query3.py
rm -f timeout-config.yaml
rm -rf ingress-kubernetes events-kubernetes products-kubernetes database-kubernetes spark-svc-kubernetes