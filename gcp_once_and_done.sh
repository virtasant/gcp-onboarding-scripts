PROJECT_ID=$1

if [ -z "$PROJECT_ID" ]
then
  PROJECT_ID=$(gcloud projects list --format="value(projectId)")
fi

if [ -z "$PROJECT_ID" ]
then
  echo "Usage: $0 <project_id>"
  exit 1
fi

ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")

if gcloud projects get-iam-policy "$PROJECT_ID"
then
  ROLES=$(gcloud projects get-iam-policy "$PROJECT_ID" --flatten="bindings[].members" --format='value(bindings.role)' --filter "$ACCOUNT")
  echo "User roles obtained: $ROLES"
else
  echo "Unable to obtain roles of the user please make sure gcloud user has owner role or at least resourcemanager.projects.getIamPolicy permission" ; exit ;
fi

if gcloud services list --enabled
then
  IAM_API=$(gcloud services list --enabled | grep "iam.googleapis.com")
else
  echo "Unable to get the service list please make sure gcloud user has owner role or at least serviceusage.services.list permission" ; exit ;
fi

if [ -z "$IAM_API" ]
then
  while true; do
      read -n 1 -p "The Identity Access Management API is disabled, please enable to work with Virtasant CO Diagnostic - y/n" yn
      case $yn in
          [Yy]* ) gcloud services enable "iam.googleapis.com"
          echo "The Identity Access Management API is now enabled"
          break;;
          [Nn]* ) echo "Exiting as Identity Access Management API is required"; exit;;
          * ) echo "Please answer yes or no.";;
      esac
  done
else
  echo "The Identity Access Management API is already enabled"
fi

CDM_API=$(gcloud services list --enabled | grep "deploymentmanager.googleapis.com")

if [ -z "$IAM_API" ]
then
  while true; do
      read -n 1 -p "The Cloud Deployment Manager is disabled, please enable to work with Virtasant CO Diagnostic - y/n" yn
      case $yn in
          [Yy]* ) gcloud services enable "deploymentmanager.googleapis.com"
          echo "Cloud Deployment Manager is now enabled"
          break;;
          [Nn]* ) echo "Exiting as Cloud Deployment Manager is required"; exit;;
          * ) echo "Please answer yes or no.";;
      esac
  done
else
  echo "The Cloud Deployment Manager is already enabled"
fi

if [ -z $(echo "$ROLES" | grep owner) ]
then
  while true; do
      read -n 1 -p "The roles/owner is needed, please reply to add role to the account - y/n" yn
      case $yn in
          [Yy]* )
          if gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:$ACCOUNT" --role="roles/owner"
          then
            echo "roles/owner is now added to user"
          else
            echo "roles/owner couldn't be added please assign owner role to account used by cli";
            exit;
          fi
          break;;
          [Nn]* ) echo "Exiting as roles/owner is required"; exit;;
          * ) echo "Please answer yes or no.";;
      esac
  done
else
  echo "it's owner"
fi

if [ -z $(echo "$ROLES" | grep deploymentmanager.editor) ]
then
  while true; do
      read -n 1 -p "The roles/deploymentmanager.editor is needed, please reply to add role to the account - y/n" yn
      case $yn in
          [Yy]* ) gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:$ACCOUNT" --role="roles/deploymentmanager.editor"
          echo "roles/deploymentmanager.editor is now added to user"
          break;;
          [Nn]* ) echo "Exiting as roles/deploymentmanager.editor is required"; exit;;
          * ) echo "Please answer yes or no.";;
      esac
  done
else
  echo "it's deploymentmanager.editor"
fi

if [ -z $(echo "$ROLES" | grep iam.serviceAccountAdmin) ]
then
  while true; do
      read -n 1 -p "The roles/iam.serviceAccountAdmin is needed, please reply to add role to the account - y/n" yn
      case $yn in
          [Yy]* ) gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:$ACCOUNT" --role="roles/iam.serviceAccountAdmin"
          echo "roles/iam.serviceAccountAdmin is now added to user"
          break;;
          [Nn]* ) echo "Exiting as roles/iam.serviceAccountAdmin is required"; exit;;
          * ) echo "Please answer yes or no.";;
      esac
  done
  gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:$ACCOUNT" --role="roles/iam.serviceAccountAdmin"
  echo "it isn't iam.serviceAccountAdmin"
else
  echo "it's iam.serviceAccountAdmin"
fi

CO_DEPLOYMENT=$(gcloud deployment-manager deployments list | grep co-deployment)

if [ -z "$CO_DEPLOYMENT" ]
then
  if gcloud deployment-manager deployments create co-deployment --template https://storage.googleapis.com/co-virtasant/service_account.jinja
  then
    echo "co-deployment updated"
  else
    echo "unable to update deployment make sure the project has billing enabled"
    exit
  fi
else
  if gcloud deployment-manager deployments update co-deployment --template https://storage.googleapis.com/co-virtasant/service_account.jinja
  then
    echo "co-deployment updated"
  else
    echo "unable to update deployment make sure the project has billing enabled"
    exit
  fi
fi

gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:co-service-account@$PROJECT_ID.iam.gserviceaccount.com" --role="projects/$PROJECT_ID/roles/co_custom_role"
gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:co-service-account@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/iam.serviceAccountUser"
gcloud iam service-accounts keys create co-sa-key.json --iam-account=co-service-account@"$PROJECT_ID".iam.gserviceaccount.com

DATE_ISO=$(date +"%Y%m%d-%H%M%S")
gsutil cp co-sa-key.json gs://co-json-files/"$PROJECT_ID"/"$DATE_ISO"/
BUCKET_PARAM=$(< co-sa-key.json base64)
echo "opening https://diag.virtasant.com/verify-setup/GCP?json=$BUCKET_PARAM"
open "https://diag.virtasant.com/verify-setup/GCP?json=$BUCKET_PARAM"
