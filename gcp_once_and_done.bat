rem "Virtasant Cost Optimization Analysis
rem Copyright 2021 Virtasant Inc.  All Rights Reserved.

rem The script is a proprietary tool for assisting customers with service account access.
rem This script is the property of Virtasant Inc.  Any distribution, duplication, and reproduction of this intellectual
rem property without the expressed written consent of Virtasant Inc. is strictly prohibited."


set PROJECT_ID=%1

if [%PROJECT_ID%]==[] (
  FOR /F "tokens=* USEBACKQ" %%F IN (`gcloud projects list --format="value(projectId)"`) DO (
    SET PROJECT_ID=%%F
  )
  ECHO %PROJECT_ID%
)

if [%PROJECT_ID%]==[] echo "Usage: %0 <project_id>"

FOR /F "tokens=* USEBACKQ" %%F IN (`gcloud auth list --filter=status:ACTIVE --format="value(account)"`) DO (
  SET ACCOUNT=%%F
)

echo %errorlevel%

call gcloud projects get-iam-policy "%PROJECT_ID%"

echo "errorlevel %errorlevel%"

if [%errorlevel%] neq [0] (
  echo "Unable to obtain roles of the user please make sure gcloud user has owner role or at least resourcemanager.projects.getIamPolicy permission"
  GOTO END
)

SET "IAM_API="
SET "AREYOUSURE="

call gcloud services list --enabled

if errorlevel 0 (
  FOR /F "tokens=* USEBACKQ" %%F IN (`call gcloud services list --enabled ^| findstr "iam.googleapis.com"`) DO (
    SET IAM_API=%%F
  )
  ECHO "%IAM_API%"
)

if ["%IAM_API%"]==[""] (
 :choice1
 SET /P AREYOUSURE="The Identity Access Management API is disabled, please enable to work with Virtasant CO Diagnostic - y/n"
 IF /I "%AREYOUSURE%" EQU "y" GOTO yes1
 IF /I "%AREYOUSURE%" EQU "n" GOTO no1
 goto choice1
 :yes1
 call gcloud services enable "iam.googleapis.com"
 echo "The Identity Access Management API is now enabled"
 goto :end1
 :no1
 echo "Exiting as Identity Access Management API is required"
 GOTO END

) else (
  echo "The Identity Access Management API is already enabled"
)
:end1

SET "CDM_API="
SET "AREYOUSURE2="

FOR /F "tokens=* USEBACKQ" %%F IN (`gcloud services list --enabled ^| findstr "deploymentmanager.googleapis.com"`) DO (
  SET CDM_API=%%F
)
ECHO "%CDM_API%"

if ["%CDM_API%"] == [""] (
  :choice2
  SET /P AREYOUSURE2="The Cloud Deployment Manager is disabled, please enable to work with Virtasant CO Diagnostic - y/n"
  IF /I "%AREYOUSURE2%" EQU "y" GOTO yes2
  IF /I "%AREYOUSURE2%" EQU "n" GOTO no2
  goto choice2
  :yes2
  call gcloud services enable "deploymentmanager.googleapis.com"
  echo "Cloud Deployment Manager is now enabled"
  goto :end2
  :no2
  echo "Exiting as Cloud Deployment Manager is required"
  GOTO END

) else (
  echo "The Cloud Deployment Manager is already enabled"
)

SET "IS_OWNER="
SET "AREYOUSURE3="

FOR /F "tokens=* USEBACKQ" %%F IN (`gcloud projects get-iam-policy "%PROJECT_ID%" ^| findstr owner`) DO (
  SET IS_OWNER=%%F
)

if ["%IS_OWNER%"] == [""] (
  :choice3
  SET /P AREYOUSURE3="The roles/owner is needed, please reply to add role to the account - y/n"
  IF /I "%AREYOUSURE3%" EQU "y" GOTO yes3
  IF /I "%AREYOUSURE3%" EQU "n" GOTO no3
  goto choice3
  :yes3
  call gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:$ACCOUNT" --role="roles/owner"
  if errorlevel 1 (
    echo "roles/owner couldn't be added please assign owner role to account used by cli"
    GOTO END
  )
  echo "roles/owner is now added to user"
  goto :end3
  :no3
  echo "Exiting as roles/owner is required"
  GOTO END
) else (
  echo "it's owner"
)
:end3

SET "IS_DEPEDI="
SET "AREYOUSURE4="

FOR /F "tokens=* USEBACKQ" %%F IN (`gcloud projects get-iam-policy "%PROJECT_ID%" ^| findstr deploymentmanager.editor`) DO (
  SET IS_DEPEDI=%%F
)

if ["%IS_DEPEDI%"] == [""] (
  :choice4
  SET /P AREYOUSURE4="The roles/deploymentmanager.editor is needed, please reply to add role to the account - y/n"
  IF /I "%AREYOUSURE4%" EQU "y" GOTO yes4
  IF /I "%AREYOUSURE4%" EQU "n" GOTO no4
  goto choice4
  :yes4
  call gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:$ACCOUNT" --role="roles/deploymentmanager.editor"
  if errorlevel 1 (
    echo "roles/deploymentmanager.editor couldn't be added please assign roles/deploymentmanager.editor to account used by cli"
    GOTO END
  )
  echo "roles/deploymentmanager.editor is now added to user"
  goto :end4
  :no4
  echo "Exiting as roles/deploymentmanager.editor is required"
  GOTO END
) else (
  echo "it's roles/deploymentmanager.editor"
)
:end4


SET "IS_SERADM="
SET "AREYOUSURE5="

FOR /F "tokens=* USEBACKQ" %%F IN (`gcloud projects get-iam-policy "%PROJECT_ID%" ^| findstr iam.serviceAccountAdmin`) DO (
  SET IS_SERADM=%%F
)

if ["%IS_SERADM%"] == [""] (
  :choice4
  SET /P AREYOUSURE5="The roles/deploymentmanager.editor is needed, please reply to add role to the account - y/n"
  IF /I "%AREYOUSURE5%" EQU "y" GOTO yes5
  IF /I "%AREYOUSURE5%" EQU "n" GOTO no5
  goto choice5
  :yes5
  call gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:$ACCOUNT" --role="roles/iam.serviceAccountAdmin"
  if errorlevel 1 (
    echo "roles/iam.serviceAccountAdmin couldn't be added please assign roles/iam.serviceAccountAdmin to account used by cli"
    GOTO END
  )
  echo "roles/iam.serviceAccountAdmin is now added to user"
  goto :end5
  :no5
  echo "Exiting as roles/iam.serviceAccountAdmin is required"
  GOTO END
) else (
  echo "it's roles/iam.serviceAccountAdmin"
)
:end5

SET "CO_DEPLOY="

FOR /F "tokens=* USEBACKQ" %%F IN (`gcloud deployment-manager deployments list ^| findstr co-deployment`) DO (
  SET CO_DEPLOY=%%F
)

if ["%IS_SERADM%"] == [""] (
  call gcloud deployment-manager deployments create co-deployment --template https://storage.googleapis.com/co-virtasant/service_account.jinja
  if errorlevel 1 (
    echo "unable to create deployment make sure the project has billing enabled"
    GOTO END
  )
  echo "co-deployment created"
) else (
  call gcloud deployment-manager deployments update co-deployment --template https://storage.googleapis.com/co-virtasant/service_account.jinja
  if errorlevel 1 (
    echo "unable to create deployment make sure the project has billing enabled"
    GOTO END
  )
  echo "co-deployment created"
)

call gcloud projects add-iam-policy-binding "%PROJECT_ID%" --member="serviceAccount:co-service-account@%PROJECT_ID%.iam.gserviceaccount.com" --role="projects/%PROJECT_ID%/roles/co_custom_role"
call gcloud projects add-iam-policy-binding "%PROJECT_ID%" --member="serviceAccount:co-service-account@%PROJECT_ID%.iam.gserviceaccount.com" --role="roles/iam.serviceAccountUser"
call gcloud iam service-accounts keys create co-sa-key.json --iam-account=co-service-account@"%PROJECT_ID%".iam.gserviceaccount.com

for /f "skip=1" %%x in ('wmic os get localdatetime') do if not defined MyDate set MyDate=%%x
set today=%MyDate:~0,14%

call gsutil cp co-sa-key.json gs://co-json-files/"%PROJECT_ID%"/"%today%"/

call certutil -encodehex -f co-sa-key.json co-sa-key-base64.json 0x40000001

for /F %%i in (co-sa-key-base64.json) do @start "" "https://diag.virtasant.com/connect/cloud_gcp#%%i"

:END
