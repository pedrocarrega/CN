How to run our service:

1. Our first script requires 3 arguments in the following order: the region where you want to host the stack; the name of the cluster; the name of the stack.
    The cluster takes around 10 to 15 minutes to be active. After the cluster is activated, we can then proceed to the second script.

2. The second script requires the same 3 arguments inputted in the same order.
    The node group takes around 10 to 15 minutes to be active. After the node groups are ready, we proceed to the third script.
    You will be asked to input the ECRPull IAM credentials which can be found in the credentials.csv file.

3. The third and final script requires 2 arguments in the following order: the region where you want to host the stack; the name of the cluster.
    You will be asked to input the credentials required for pushing docker images into the ECR repository.
    After a couple of minutes the service should be online on the link provided.

For the region we recommend 'eu-west-1', that being said we leave the region selection to the professor discretion
