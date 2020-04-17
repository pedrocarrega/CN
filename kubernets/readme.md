How to run our service:

Our scripts are seperated in 3 different files due to the fact that certain components that are created must be in an active status
before continuing to the next step.

Prerequirements:
	- aws cli
	- eksctl
	- jq
	- kubectl


For the region we recommend 'eu-west-1', that being said we leave the region selection to the professor's discretion

1. Our first script deploy1.sh requires 3 arguments in the following order: 
	-the region where you want to host the stack; 
	-the name of the cluster; 
	-the name of the stack. 
	
	Both the stack name and the cluster name must be unique in order for the script to function correctly.
    	The cluster takes around 10 to 15 minutes to be active. After the cluster is activated, we can then proceed to the second script.
	To check on the status of the cluster input: 
		-  `aws eks describe-cluster --name CLUSTER_NAME`
	Change CLUSTER_NAME to the name of the cluster name entered on script initialization. 
	Run the second script after the cluster's status says `ACTIVE`.

2. The second script deploy2.sh requires the same 3 arguments inputted in the same order.
    The node group takes around 10 to 15 minutes to be active. After the node groups are ready, we proceed to the third script.
    To check the status the node groups, type `aws eks describe-nodegroup --cluster-name CLUSTER_NAME --nodegroup STACK_NAME` , replacing CLUSTER_NAME and STACK_NAME with the given argument name when executing the script.
    You will be asked to input the ECR Pull IAM credentials which can be found in the `credenciais.txt` file.

3. The third script deploy3.sh requires 2 arguments in the following order: 
	-the region where the stack is hosted
	-the name of the cluster.

	NOTE: In order for the script to execute correctly, the policy with the name `ALBIngressControllerIAMPolicyEcommerce` (if it exists), must be deleted manually in the AWS console.
	NOTE: Any repositories with the following names: `events`, `products` must be deleted.

	You will be asked to input the credentials required for pushing docker images into the personal ECR repository.
	After a couple of minutes the service should be online on the link provided.
	
	NOTE: To rerun this file due to any errors that may have eventually occurred, we first must delete any ECR repositories and the ALBIngressControllerIAMPolicyEcommerce policy created so that the script can correctly retrieve the path.
	
4.1 Before moving on to the final script deploy4.sh some changes must be made:
	Inside the `ingress/ingress-rbac.yaml` file, at the annotations, the role ARN must be written in front of  `eks.amazonaws.com/role-arn:`. This value can be checked by typing the following command in the console:
		- aws iam get-role --role-name eksServiceRole

4.2 Inside the `ingress/alb-ingress-controller.yaml` file, uncomment the `--cluster-name` line, and place the name of the cluster previously given on the other scripts. NOTE: The cluster name must be correct for the scripts to deploy correctly.

4.3 After changing said files we can finnaly execute script deploy4.sh

5. To access the services, type in the commmand line: `kubectl get ingress` and copy the address given. To access a specific service append the url (ex.:/api/events/ratio)

Deleting deployment:

1. Navigate to the AWS EKS console at `https://eu-west-1.console.aws.amazon.com/eks/home?region=eu-west-1#/clusters` depending on the region, access the cluster and delete the nodegroup.
2. After the nodegroup is deleted, we can then proceed to the deletion of the cluster itself.
3. Navigate to the EC2 console at `https://eu-west-1.console.aws.amazon.com/ec2/v2/home?region=eu-west-1#LoadBalancers` depending on the region and delete the load balancers.
4. Navigate to the Target Groups section on the EC2 console and delete any related target groups to the VPC.
4. Navigate to the VPC section at `https://eu-west-1.console.aws.amazon.com/vpc/home?region=eu-west-1#vpcs` and delete the created non-default VPC
5. Navigate to the CloudFormation stacks at `https://eu-west-1.console.aws.amazon.com/cloudformation/home?region=eu-west-1#/stacks` depending on the region and delete the created stack
