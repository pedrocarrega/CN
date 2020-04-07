aws iam create-role --role-name eksServiceRole --assume-role-policy-document file://eks-service-role/assume-role.json --description "Allows EKS to manage clusters on your behalf."

aws iam attach-role-policy --role-name eksServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam attach-role-policy --role-name eksServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSServicePolicy
aws iam attach-role-policy --role-name eksServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
aws iam attach-role-policy --role-name eksServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
aws iam attach-role-policy --role-name eksServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly