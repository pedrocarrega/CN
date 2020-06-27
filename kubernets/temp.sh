PROJECT_NAME='cn-deploy'
ACCOUNT_NAME="terraform"
BUCKET_NAME="cn-bucket-test-20202020"
INITIAL_NODES="1"
CLUSTER_NAME="ecommerce-cluster"
MACHINE_TYPE="n1-standard-1"
NODE_POOL_COUNT="1"
COMPUTE_ZONE="europe-west1"

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: svc
spec:
  selector:
    matchLabels:
      run: svc
  timeoutSec: 1200
" > timeout-config.yaml
  
echo "apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: fanout-ingress
spec:
  rules:
  template:
    metadata:
      labels:
        run: svc
    spec:
      containers:
      - image: gcr.io/$PROJECT_NAME/spark-svc:v1
        imagePullPolicy: IfNotPresent
        name: svc
  timeoutSec: 1200
" > timeout-config.yaml
  
echo "apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: fanout-ingress
spec:
  rules:
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