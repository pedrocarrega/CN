REGION=$1
CLUSTER_NAME=$2

GET_ROLE=$(aws iam create-policy \
    --policy-name ALBIngressControllerIAMPolicyEcommerce \
    --policy-document file://ingress-test/ingress-role.json | jq '.Policy.Arn' -r);

aws iam attach-role-policy \
    --policy-arn $GET_ROLE \
    --role-name eksServiceRole



printf $GET_ROLE