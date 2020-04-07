printf  "Inserir as credenciais do ECR especificadas no ficheiro credenciais.txt\n"
aws configure

aws ecr get-login-password --region eu-west-1 | sudo docker login --username AWS --password-stdin 774440115756.dkr.ecr.eu-west-1.amazonaws.com

sudo docker pull 774440115756.dkr.ecr.eu-west-1.amazonaws.com/events:v1
sudo docker pull 774440115756.dkr.ecr.eu-west-1.amazonaws.com/products:v1