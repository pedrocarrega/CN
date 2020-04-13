REGION=$1
CLUSTER_NAME=$2

kubectl apply -f ingress-test/ingress-rbac.yaml

kubectl apply -f ingress-test/alb-ingress-controller.yaml

kubectl apply -f ingress/api-ingress.yaml