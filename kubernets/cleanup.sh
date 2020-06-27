PROJECT_NAME='logical-codex-275717'
ACCOUNT_NAME="terraform"

cd terraform
export GOOGLE_APPLICATION_CREDENTIALS="../creds.json"
terraform destroy
cd ..

gcloud iam service-accounts delete $ACCOUNT_NAME@$PROJECT_NAME.iam.gserviceaccount.com
gcloud container images delete gcr.io/$PROJECT_NAME/events:v1
gcloud container images delete gcr.io/$PROJECT_NAME/products:v1
gcloud container images delete gcr.io/$PROJECT_NAME/database:v1
gcloud container images delete gcr.io/$PROJECT_NAME/spark-svc:v1