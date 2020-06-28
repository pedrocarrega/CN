PROJECT_NAME='projeto-cn-2806'
ACCOUNT_NAME="terraform"

cd terraform
export GOOGLE_APPLICATION_CREDENTIALS="../creds.json"
terraform destroy
cd ..

rm -rf terraform creds.json

gcloud iam service-accounts delete $ACCOUNT_NAME@$PROJECT_NAME.iam.gserviceaccount.com
gcloud projects remove-iam-policy-binding $PROJECT_NAME --member "serviceAccount:${ACCOUNT_NAME}@${PROJECT_NAME}.iam.gserviceaccount.com" --role "roles/owner"
gcloud container images delete gcr.io/$PROJECT_NAME/events:v1
gcloud container images delete gcr.io/$PROJECT_NAME/products:v1
gcloud container images delete gcr.io/$PROJECT_NAME/database:v1
gcloud container images delete gcr.io/$PROJECT_NAME/spark-svc:v1