REGION=$1
CLUSTER_NAME=$2

printf "REGION: ${REGION}\n"
printf "CLUSTER NAME: ${CLUSTER_NAME}\n"

eksctl create cluster \
--name $CLUSTER_NAME \
--region $REGION \
--nodegroup-name standard-workers \
--node-type t3.medium \
--nodes 15 \
--nodes-min 1 \
--nodes-max 20

printf  "Inserir as credenciais do ECR especificadas no ficheiro credenciais.txt\n"
aws configure

aws ecr get-login-password --region eu-west-1 | sudo docker login --username AWS --password-stdin 774440115756.dkr.ecr.eu-west-1.amazonaws.com

sudo docker pull 774440115756.dkr.ecr.eu-west-1.amazonaws.com/events:v1
sudo docker pull 774440115756.dkr.ecr.eu-west-1.amazonaws.com/products:v1
sudo docker pull 774440115756.dkr.ecr.eu-west-1.amazonaws.com/database:v1

printf  "Inserir as credenciais de acesso ao ECR ou de admin da conta pessoal de AWS:\n"
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

REPO_DATABASE=`aws ecr create-repository \
			--region $REGION \
			--repository-name "database" \
			--query "repository.repositoryUri" \
			--output text`

aws ecr get-login-password --region $REGION| sudo docker login --username AWS --password-stdin $REPO_EVENTS
sudo docker tag 774440115756.dkr.ecr.eu-west-1.amazonaws.com/events:v1 $REPO_EVENTS:v1
sudo docker push $REPO_EVENTS:v1

aws ecr get-login-password --region $REGION | sudo docker login --username AWS --password-stdin $REPO_PRODUCTS
sudo docker tag 774440115756.dkr.ecr.eu-west-1.amazonaws.com/products:v1 $REPO_PRODUCTS:v1
sudo docker push $REPO_PRODUCTS:v1


aws ecr get-login-password --region $REGION| sudo docker login --username AWS --password-stdin $REPO_DATABASE
sudo docker tag 774440115756.dkr.ecr.eu-west-1.amazonaws.com/database:v1 $REPO_DATABASE:v1
sudo docker push $REPO_DATABASE:v1

eksctl utils associate-iam-oidc-provider \
    --region $REGION \
    --cluster $CLUSTER_NAME \
    --approve

mkdir ingress

echo "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [
    {
      \"Effect\": \"Allow\",
      \"Action\": [
        \"acm:DescribeCertificate\",
        \"acm:ListCertificates\",
        \"acm:GetCertificate\"
      ],
      \"Resource\": \"*\"
    },
    {
      \"Effect\": \"Allow\",
      \"Action\": [
        \"ec2:AuthorizeSecurityGroupIngress\",
        \"ec2:CreateSecurityGroup\",
        \"ec2:CreateTags\",
        \"ec2:DeleteTags\",
        \"ec2:DeleteSecurityGroup\",
        \"ec2:DescribeAccountAttributes\",
        \"ec2:DescribeAddresses\",
        \"ec2:DescribeInstances\",
        \"ec2:DescribeInstanceStatus\",
        \"ec2:DescribeInternetGateways\",
        \"ec2:DescribeNetworkInterfaces\",
        \"ec2:DescribeSecurityGroups\",
        \"ec2:DescribeSubnets\",
        \"ec2:DescribeTags\",
        \"ec2:DescribeVpcs\",
        \"ec2:ModifyInstanceAttribute\",
        \"ec2:ModifyNetworkInterfaceAttribute\",
        \"ec2:RevokeSecurityGroupIngress\"
      ],
      \"Resource\": \"*\"
    },
    {
      \"Effect\": \"Allow\",
      \"Action\": [
        \"elasticloadbalancing:AddListenerCertificates\",
        \"elasticloadbalancing:AddTags\",
        \"elasticloadbalancing:CreateListener\",
        \"elasticloadbalancing:CreateLoadBalancer\",
        \"elasticloadbalancing:CreateRule\",
        \"elasticloadbalancing:CreateTargetGroup\",
        \"elasticloadbalancing:DeleteListener\",
        \"elasticloadbalancing:DeleteLoadBalancer\",
        \"elasticloadbalancing:DeleteRule\",
        \"elasticloadbalancing:DeleteTargetGroup\",
        \"elasticloadbalancing:DeregisterTargets\",
        \"elasticloadbalancing:DescribeListenerCertificates\",
        \"elasticloadbalancing:DescribeListeners\",
        \"elasticloadbalancing:DescribeLoadBalancers\",
        \"elasticloadbalancing:DescribeLoadBalancerAttributes\",
        \"elasticloadbalancing:DescribeRules\",
        \"elasticloadbalancing:DescribeSSLPolicies\",
        \"elasticloadbalancing:DescribeTags\",
        \"elasticloadbalancing:DescribeTargetGroups\",
        \"elasticloadbalancing:DescribeTargetGroupAttributes\",
        \"elasticloadbalancing:DescribeTargetHealth\",
        \"elasticloadbalancing:ModifyListener\",
        \"elasticloadbalancing:ModifyLoadBalancerAttributes\",
        \"elasticloadbalancing:ModifyRule\",
        \"elasticloadbalancing:ModifyTargetGroup\",
        \"elasticloadbalancing:ModifyTargetGroupAttributes\",
        \"elasticloadbalancing:RegisterTargets\",
        \"elasticloadbalancing:RemoveListenerCertificates\",
        \"elasticloadbalancing:RemoveTags\",
        \"elasticloadbalancing:SetIpAddressType\",
        \"elasticloadbalancing:SetSecurityGroups\",
        \"elasticloadbalancing:SetSubnets\",
        \"elasticloadbalancing:SetWebACL\"
      ],
      \"Resource\": \"*\"
    },
    {
      \"Effect\": \"Allow\",
      \"Action\": [
        \"iam:CreateServiceLinkedRole\",
        \"iam:GetServerCertificate\",
        \"iam:ListServerCertificates\"
      ],
      \"Resource\": \"*\"
    },
    {
      \"Effect\": \"Allow\",
      \"Action\": [
        \"cognito-idp:DescribeUserPoolClient\"
      ],
      \"Resource\": \"*\"
    },
    {
      \"Effect\": \"Allow\",
      \"Action\": [
        \"waf-regional:GetWebACLForResource\",
        \"waf-regional:GetWebACL\",
        \"waf-regional:AssociateWebACL\",
        \"waf-regional:DisassociateWebACL\"
      ],
      \"Resource\": \"*\"
    },
    {
      \"Effect\": \"Allow\",
      \"Action\": [
        \"tag:GetResources\",
        \"tag:TagResources\"
      ],
      \"Resource\": \"*\"
    },
    {
      \"Effect\": \"Allow\",
      \"Action\": [
        \"waf:GetWebACL\"
      ],
      \"Resource\": \"*\"
    },
    {
      \"Effect\": \"Allow\",
      \"Action\": [
        \"shield:DescribeProtection\",
        \"shield:GetSubscriptionState\",
        \"shield:DeleteProtection\",
        \"shield:CreateProtection\",
        \"shield:DescribeSubscription\",
        \"shield:ListProtections\"
      ],
      \"Resource\": \"*\"
    }
  ]
}" > ingress/ingress-role.json

ARN=$(aws iam create-policy \
    --policy-name ALBIngressControllerIAMPolicyEcommerce \
    --policy-document file://ingress/ingress-role.json | jq '.Policy.Arn' -r);

printf $ARN

mkdir events
mkdir products

echo "apiVersion: v1
kind: Pod
metadata:
  name: events
  namespace: kube-system
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
  namespace: kube-system
spec:
  selector:
    app: alb-ingress-controller
  ports:
  - protocol: TCP
    port: 3000
    targetPort: 3000
  type: NodePort" > events/events-service.yml

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: events-deployment
  namespace: kube-system
  labels:
    app: alb-ingress-controller
spec:
  replicas: 1
  selector:
    matchLabels:
      app: alb-ingress-controller
  template:
    metadata:
      labels:
        app: alb-ingress-controller
    spec:
      containers:
      - name: events
        image: $REPO_EVENTS:v1
        ports:
        - containerPort: 3000" > events/events-deployment.yml

echo "apiVersion: v1
kind: Pod
metadata:
  name: products
  namespace: kube-system
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
  namespace: kube-system
spec:
  selector:
    app: alb-ingress-controller
  ports:
  - protocol: TCP
    port: 3000
    targetPort: 3000
  type: NodePort" > products/products-service.yml

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: products-deployment
  namespace: kube-system
  labels:
    app: alb-ingress-controller
spec:
  replicas: 1
  selector:
    matchLabels:
      app: alb-ingress-controller
  template:
    metadata:
      labels:
        app: alb-ingress-controller
    spec:
      containers:
      - name: products
        image: $REPO_PRODUCTS:v1
        ports:
        - containerPort: 3000" > products/products-deployment.yml

mkdir database

echo "apiVersion: v1
kind: Pod
metadata:
  name: database
  namespace: kube-system
  labels:
    name: database
spec:
  containers:
  - name: database
    image:  $REPO_DATABASE:v1
    ports:
    - containerPort: 27017" > database/database-pod.yml

echo "apiVersion: v1
kind: Service
metadata:
  name: database
  namespace: kube-system
spec:
  selector:
    app: alb-ingress-controller
  ports:
  - protocol: TCP
    port: 27017
    targetPort: 27017
  type: NodePort" > database/database-service.yml

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: database-deployment
  namespace: kube-system
  labels:
    app: alb-ingress-controller
spec:
  replicas: 1
  selector:
    matchLabels:
      app: alb-ingress-controller
  template:
    metadata:
      labels:
        app: alb-ingress-controller
    spec:
      containers:
      - name: database
        image:  $REPO_DATABASE:v1
        ports:
        - containerPort: 27017" > database/database-deployment.yml

echo "---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    app.kubernetes.io/name: alb-ingress-controller
  annotations:
    eks.amazonaws.com/role-arn: $ARN
  name: alb-ingress-controller
rules:
  - apiGroups:
      - \"\"
      - extensions
    resources:
      - configmaps
      - endpoints
      - events
      - ingresses
      - ingresses/status
      - services
      - pods/status
    verbs:
      - create
      - get
      - list
      - update
      - watch
      - patch
  - apiGroups:
      - \"\"
      - extensions
    resources:
      - nodes
      - pods
      - secrets
      - services
      - namespaces
    verbs:
      - get
      - list
      - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    app.kubernetes.io/name: alb-ingress-controller
  name: alb-ingress-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: alb-ingress-controller
subjects:
  - kind: ServiceAccount
    name: alb-ingress-controller
    namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/name: alb-ingress-controller
  name: alb-ingress-controller
  namespace: kube-system
..." > ingress/ingress-rbac.yaml

kubectl apply -f ingress/ingress-rbac.yaml

eksctl create iamserviceaccount \
    --region $REGION \
    --name alb-ingress-controller \
    --namespace kube-system \
    --cluster $CLUSTER_NAME \
    --attach-policy-arn $ARN \
    --override-existing-serviceaccounts \
    --approve

QUERY=$(cat <<-EOF
[
	Stacks[0].Outputs[?OutputKey==\`VpcId\`].OutputValue
]
EOF)

TEMP=eksctl-$CLUSTER_NAME-cluster

RESULTS=$(aws cloudformation describe-stacks \
	--stack-name $TEMP \
	--region $REGION \
	--query "$QUERY" \
	--output text);
RESULTS_ARRAY=($RESULTS)

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: alb-ingress-controller
  name: alb-ingress-controller
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: alb-ingress-controller
  template:
    metadata:
      labels:
        app.kubernetes.io/name: alb-ingress-controller
    spec:
      containers:
        - name: alb-ingress-controller
          args:
            - --ingress-class=alb
            - --cluster-name=$CLUSTER_NAME
            - --aws-vpc-id=${RESULTS_ARRAY[0]}
            - --aws-region=$REGION

          image: docker.io/amazon/aws-alb-ingress-controller:v1.1.6
      serviceAccountName: alb-ingress-controller" > ingress/alb-ingress-controller.yaml

echo "apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: \"ecommerce-ingress\"
  namespace: "kube-system"
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
  labels:
    app: ecommerce-api
spec:
  rules:
    - http:
        paths:
          - path: /api/events*
            backend:
              serviceName: \"events\"
              servicePort: 3000
          - path: /api/products*
            backend:
              serviceName: \"products\"
              servicePort: 3000" > ingress/ingress-deploy.yaml

kubectl apply -f ingress/alb-ingress-controller.yaml
kubectl apply -f ingress/ingress-deploy.yaml


kubectl apply -f events/events-pod.yml
kubectl apply -f events/events-service.yml
kubectl apply -f events/events-deployment.yml

kubectl apply -f products/products-pod.yml
kubectl apply -f products/products-service.yml
kubectl apply -f products/products-deployment.yml

kubectl apply -f database/database-pod.yml
kubectl apply -f database/database-service.yml 
kubectl apply -f database/database-deployment.yml