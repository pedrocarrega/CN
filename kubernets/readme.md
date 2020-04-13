How to run our service:

Our scripts are seperated in 3 different files due to the fact that certain components that are created must be in an active status
before continuing to the next step.

Prerequirements:
	- aws cli
	- eksctl
	- jq
	- kubectl


For the region we recommend 'eu-west-1', that being said we leave the region selection to the professor discretion

1. Our first script requires 3 arguments in the following order: 
	-the region where you want to host the stack; 
	-the name of the cluster; 
	-the name of the stack. 
	
	Both the stack name and the cluster name must be unique in order for the script to function correctly.
    	The cluster takes around 10 to 15 minutes to be active. After the cluster is activated, we can then proceed to the second script.
	To check on the status of the cluster, type: aws eks describe-cluster --name CLUSTER_NAME
	Change CLUSTER_NAME to the name of the cluster name entered on script initialization. 
	Run the second script after the cluster's status says ACTIVE.

2. The second script requires the same 3 arguments inputted in the same order.
    The node group takes around 10 to 15 minutes to be active. After the node groups are ready, we proceed to the third script.
    You will be asked to input the ECRPull IAM credentials which can be found in the credentials.csv file.

3. The third and final script requires 2 arguments in the following order: 
	-the region where you want to host the stack
	-the name of the cluster.

	NOTE: In order for the script to execute correctly, the policy with the name ALBIngressControllerIAMPolicy (if it exists), must be
deleted manually in the AWS console.
	NOTE: Any repositories with the following names: events, products.

	You will be asked to input the credentials required for pushing docker images into the ECR repository.
	After a couple of minutes the service should be online on the link provided.
	NOTE: To rerun this file due to any errors that may have eventually occurred, we first must delete any ECR repositories created
so that the script can correctly retrieve the path.
	
	Due to the non deployment of the Ingress load balancer, we had to resort to exposing the services as lone services:
		-kubectl get svc
		-To access the services input <address>:3000/api/events/ratio
