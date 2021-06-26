# "Virtasant Cost Optimization Analysis
# Copyright 2021 Virtasant Inc.  All Rights Reserved.

# The script is a proprietary tool for assisting customers with service account access.
# This script is the property of Virtasant Inc.  Any distribution, duplication, and reproduction of this intellectual
# property without the expressed written consent of Virtasant Inc. is strictly prohibited."

PROJECT_ID=$1

if [ -z "$PROJECT_ID" ]
then
  PROJECT_ID=$(gcloud config list | awk '{ if ( $1 == "project" ) { print $3 } } ')
fi

if [ -z "$PROJECT_ID" ]
then
  read -p "Project not found in your configuration please write the PROJECT_ID " PROJECT_ID
fi

ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")

if gcloud projects get-iam-policy "$PROJECT_ID"
then
  ROLES=$(gcloud projects get-iam-policy "$PROJECT_ID" --flatten="bindings[].members" --format='value(bindings.role)' --filter "$ACCOUNT")
  echo "User roles obtained: $ROLES"
else
  echo "Unable to obtain roles of the user please make sure gcloud user has owner role or at least resourcemanager.projects.getIamPolicy permission" ; exit ;
fi

if gcloud services list --enabled --project "$PROJECT_ID"
then
  IAM_API=$(gcloud services list --enabled --project "$PROJECT_ID"| grep "iam.googleapis.com")
else
  echo "Unable to get the service list please make sure gcloud user has owner role or at least serviceusage.services.list permission" ; exit ;
fi

if [ -z "$IAM_API" ]
then
  while true; do
      read -n 1 -p "The Identity Access Management API is disabled, please enable to work with Virtasant CO Diagnostic - y/n " yn
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

CDM_API=$(gcloud services list --enabled --project $PROJECT_ID   | grep "deploymentmanager.googleapis.com")

if [ -z "$CDM_API" ]
then
  while true; do
      read -n 1 -p "The Cloud Deployment Manager is disabled, please enable to work with Virtasant CO Diagnostic - y/n " yn
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

COMPUTE_API=$(gcloud services list --enabled --project $PROJECT_ID   | grep "compute.googleapis.com")

if [ -z "$COMPUTE_API" ]
then
  while true; do
      read -n 1 -p "The Compute Engine API is disabled, please enable to work with Virtasant CO Diagnostic - y/n " yn
      case $yn in
          [Yy]* ) printf "\nEnabling Compute Engine API may take a long time, please wait until it finishes"
          if ! gcloud services enable "compute.googleapis.com" ; then exit; fi;
          echo "Compute Engine API is now enabled"
          break;;
          [Nn]* ) echo "Exiting as Compute Engine API is required"; exit;;
          * ) echo "Please answer yes or no.";;
      esac
  done
else
  echo "Compute Engine API is already enabled"
fi

CLOUD_SQL_API=$(gcloud services list --enabled --project $PROJECT_ID   | grep "sql-component.googleapis.com")

if [ -z "$CLOUD_SQL_API" ]
then
  while true; do
      read -n 1 -p "The Cloud SQL API is disabled, please enable to work with Virtasant CO Diagnostic - y/n " yn
      case $yn in
          [Yy]* )
          if ! gcloud services enable "sql-component.googleapis.com" ; then exit; fi;
          echo "Cloud SQL API is now enabled"
          break;;
          [Nn]* ) echo "Exiting as Cloud SQL API is required"; exit;;
          * ) echo "Please answer yes or no.";;
      esac
  done
else
  echo "Cloud SQL API is already enabled"
fi


ACCOUNT_TYPE=$(echo "$ACCOUNT" | awk '{ if ($1~"gserviceaccount") { print "serviceAccount" } else { print "user" } }')

if [ -z $(echo "$ROLES" | grep owner) ]
then
  while true; do
      read -n 1 -p "The roles/owner is needed, please reply to add role to the account - y/n " yn
      case $yn in
          [Yy]* )
          if gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="$ACCOUNT_TYPE:$ACCOUNT" --role="roles/owner"
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
      read -n 1 -p "The roles/deploymentmanager.editor is needed, please reply to add role to the account - y/n " yn
      case $yn in
          [Yy]* ) gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="$ACCOUNT_TYPE:$ACCOUNT" --role="roles/deploymentmanager.editor"
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
      read -n 1 -p "The roles/iam.serviceAccountAdmin is needed, please reply to add role to the account - y/n " yn
      case $yn in
          [Yy]* ) gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="$ACCOUNT_TYPE:$ACCOUNT" --role="roles/iam.serviceAccountAdmin"
          echo "roles/iam.serviceAccountAdmin is now added to user"
          break;;
          [Nn]* ) echo "Exiting as roles/iam.serviceAccountAdmin is required"; exit;;
          * ) echo "Please answer yes or no.";;
      esac
  done
  gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="$ACCOUNT_TYPE:$ACCOUNT" --role="roles/iam.serviceAccountAdmin"
  echo "it isn't iam.serviceAccountAdmin"
else
  echo "it's iam.serviceAccountAdmin"
fi

SERVICES_ACCOUNT=$(gcloud projects get-iam-policy "$PROJECT_ID" | awk '{ if ( $2~"cloudservices" ) { split($2,a,":"); print a[2]; } }' | tail -n1)
gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:$SERVICES_ACCOUNT" --role="roles/owner"
CO_DEPLOYMENT=$(gcloud deployment-manager deployments list --project "$PROJECT_ID"| grep co-deployment)

if [ -z "$CO_DEPLOYMENT" ]
then
  if gcloud deployment-manager deployments create co-deployment --project "$PROJECT_ID" --template https://storage.googleapis.com/co-virtasant/service_account.jinja
  then
    echo "co-deployment updated"
  else
    echo "unable to update deployment make sure the project has billing enabled"
    exit
  fi
else
  if gcloud deployment-manager deployments update co-deployment --project "$PROJECT_ID" --template https://storage.googleapis.com/co-virtasant/service_account.jinja
  then
    echo "co-deployment updated"
  else
    echo "unable to update deployment make sure the project has billing enabled"
    exit
  fi
fi

gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:co-service-account@$PROJECT_ID.iam.gserviceaccount.com" --role="projects/$PROJECT_ID/roles/co_custom_role"
gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:co-service-account@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/iam.serviceAccountUser"
gcloud iam service-accounts keys create co-sa-key.json --project "$PROJECT_ID" --iam-account=co-service-account@"$PROJECT_ID".iam.gserviceaccount.com

BUCKET_PARAM=$(< co-sa-key.json base64)
echo "opening https://diag.virtasant.com/connect/cloud_gcp#$BUCKET_PARAM"
open "https://diag.virtasant.com/connect/cloud_gcp#$BUCKET_PARAM"