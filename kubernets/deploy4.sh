kubectl apply -f ingress/ingress-rbac.yaml
kubectl apply -f ingress/alb-ingress-controller.yaml
kubectl apply -f ingress/ingress-deploy.yaml


kubectl apply -f events/events-pod.yml
kubectl apply -f events/events-service.yml
kubectl apply -f events/events-deployment.yml

kubectl apply -f products/products-pod.yml
kubectl apply -f products/products-service.yml
kubectl apply -f products/products-deployment.yml