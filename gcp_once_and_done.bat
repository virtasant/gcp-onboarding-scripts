rem "Virtasant Cost Optimization Analysis
rem Copyright 2021 Virtasant Inc.  All Rights Reserved.

rem The script is a proprietary tool for assisting customers with service account access.
rem This script is the property of Virtasant Inc.  Any distribution, duplication, and reproduction of this intellectual
rem property without the expressed written consent of Virtasant Inc. is strictly prohibited."


set PROJECT_ID=%1

if [%PROJECT_ID%]==[] (
  FOR /F "tokens=* USEBACKQ" %%F IN (`gcloud config get-value project`) DO (
    SET PROJECT_ID=%%F
  )
  ECHO %PROJECT_ID%
)

if [%PROJECT_ID%]==[] (
  SET /P PROJECT_ID="Project not found in your configuration please write the PROJECT_ID "
)

echo "project id: %PROJECT_ID%"

FOR /F "tokens=* USEBACKQ" %%F IN (`gcloud auth list --filter=status:ACTIVE --format="value(account)"`) DO (
  SET ACCOUNT=%%F
)

call gcloud projects get-iam-policy "%PROJECT_ID%"

echo "errorlevel %errorlevel%"

if [%errorlevel%] neq [0] (
  echo "Unable to obtain roles of the user please make sure gcloud user has owner role or at least resourcemanager.projects.getIamPolicy permission"
  GOTO END
)

SET "IAM_API="
SET "AREYOUSURE="

call gcloud services list --enabled --project "%PROJECT_ID%"

if errorlevel 0 (
  FOR /F "tokens=* USEBACKQ" %%F IN (`call gcloud services list --enabled --project "%PROJECT_ID%" ^| findstr "iam.googleapis.com"`) DO (
    SET IAM_API=%%F
  )
  ECHO "%IAM_API%"
)

if ["%IAM_API%"]==[""] (
  GOTO choice1
) else (
  echo "The Identity Access Management API is already enabled"
  GOTO end1
)
:choice1
SET /P AREYOUSURE="The Identity Access Management API is disabled, please enable to work with Virtasant CO Diagnostic - y/n "
IF /I "%AREYOUSURE%" EQU "y" GOTO yes1
IF /I "%AREYOUSURE%" EQU "n" GOTO no1
goto choice1
:yes1
call gcloud services enable "iam.googleapis.com" --project "%PROJECT_ID%"
echo "The Identity Access Management API is now enabled"
goto :end1
:no1
echo "Exiting as Identity Access Management API is required"
GOTO END
:end1

SET "CDM_API="
SET "AREYOUSURE2="

FOR /F "tokens=* USEBACKQ" %%F IN (`gcloud services list --enabled --project "%PROJECT_ID%" ^| findstr "deploymentmanager.googleapis.com"`) DO (
  SET CDM_API=%%F
)
ECHO "%CDM_API%"

if ["%CDM_API%"] == [""] (
  GOTO choice2
) else (
  echo "The Cloud Deployment Manager is already enabled"
  GOTO end2
)
:choice2
SET /P AREYOUSURE2="The Cloud Deployment Manager is disabled, please enable to work with Virtasant CO Diagnostic - y/n "
IF /I "%AREYOUSURE2%" EQU "y" GOTO yes2
IF /I "%AREYOUSURE2%" EQU "n" GOTO no2
goto choice2
:yes2
call gcloud services enable "deploymentmanager.googleapis.com" --project "%PROJECT_ID%"
echo "Cloud Deployment Manager is now enabled"
goto :end2
:no2
echo "Exiting as Cloud Deployment Manager is required"
GOTO END
:end2

SET "COMPUTE_API="
SET "AREYOUSURE10="

FOR /F "tokens=* USEBACKQ" %%F IN (`gcloud services list --enabled --project "%PROJECT_ID%" ^| findstr "compute.googleapis.com"`) DO (
  SET COMPUTE_API=%%F
)
ECHO "%COMPUTE_API%"

if ["%COMPUTE_API%"] == [""] (
  GOTO choice10
) else (
  echo "Compute Engine API is already enabled"
  GOTO end10
)
:choice10
SET /P AREYOUSURE10="The Compute Engine API is disabled, please enable to work with Virtasant CO Diagnostic - y/n "
IF /I "%AREYOUSURE10%" EQU "y" GOTO yes10
IF /I "%AREYOUSURE10%" EQU "n" GOTO no10
goto choice10
:yes10
call gcloud services enable "compute.googleapis.com" --project "%PROJECT_ID%"
echo "Compute Engine API is now enabled"
goto :end10
:no10
echo "Exiting as Compute Engine API is required"
GOTO END
:end10

SET "CLOUD_SQL_API="
SET "AREYOUSURE11="

FOR /F "tokens=* USEBACKQ" %%F IN (`gcloud services list --enabled --project "%PROJECT_ID%" ^| findstr "sql-component.googleapis.com"`) DO (
  SET CLOUD_SQL_API=%%F
)
ECHO "%CLOUD_SQL_API%"

if ["%CLOUD_SQL_API%"] == [""] (
  GOTO choice11
) else (
  echo "Cloud SQL API is already enabled"
  GOTO end11
)
:choice11
SET /P AREYOUSURE11="The Cloud SQL API is disabled, please enable to work with Virtasant CO Diagnostic - y/n "
IF /I "%AREYOUSURE11%" EQU "y" GOTO yes11
IF /I "%AREYOUSURE11%" EQU "n" GOTO no11
goto choice11
:yes11
call gcloud services enable "sql-component.googleapis.com" --project "%PROJECT_ID%"
echo "Cloud SQL API is now enabled"
goto :end11
:no11
echo "Exiting as Cloud SQL API is required"
GOTO END
:end11

SET "SERVICE_ACCOUNT="
SET "ACCOUNT_TYPE="

FOR /F "tokens=* USEBACKQ" %%F IN (`echo %ACCOUNT% ^| findstr gserviceaccount`) DO (
  SET SERVICE_ACCOUNT=%%F
)

echo "Service Account: %SERVICE_ACCOUNT%"

if ["%SERVICE_ACCOUNT%"] == [""] (
  SET ACCOUNT_TYPE=user
) else (
  SET ACCOUNT_TYPE=serviceAccount
)

SET "IS_OWNER="
SET "AREYOUSURE3="

FOR /F "tokens=* USEBACKQ" %%F IN (`gcloud projects get-iam-policy "%PROJECT_ID%" ^| findstr owner`) DO (
  SET IS_OWNER=%%F
)

if ["%IS_OWNER%"] == [""] (
  GOTO choice3
) else (
  echo "it's owner"
)
:choice3
SET /P AREYOUSURE3="The roles/owner is needed, please reply to add role to the account - y/n "
IF /I "%AREYOUSURE3%" EQU "y" GOTO yes3
IF /I "%AREYOUSURE3%" EQU "n" GOTO no3
goto choice3
:yes3
call gcloud projects add-iam-policy-binding "%PROJECT_ID%" --member="%ACCOUNT_TYPE%:%ACCOUNT%" --role="roles/owner"
if errorlevel 1 (
  echo "roles/owner couldn't be added please assign owner role to account used by cli"
  GOTO END
)
echo "roles/owner is now added to user"
goto :end3
:no3
echo "Exiting as roles/owner is required"
GOTO END
:end3

SET "IS_DEPEDI="
SET "AREYOUSURE4="

FOR /F "tokens=* USEBACKQ" %%F IN (`gcloud projects get-iam-policy "%PROJECT_ID%" ^| findstr deploymentmanager.editor`) DO (
  SET IS_DEPEDI=%%F
)

echo "Account Type %ACCOUNT_TYPE%"

if ["%IS_DEPEDI%"] == [""] (
  GOTO choice4
) else (
  echo "it's roles/deploymentmanager.editor"
  GOTO end4
)
:choice4
SET /P AREYOUSURE4="The roles/deploymentmanager.editor is needed, please reply to add role to the account - y/n "
IF /I "%AREYOUSURE4%" EQU "y" GOTO yes4
IF /I "%AREYOUSURE4%" EQU "n" GOTO no4
goto choice4
:yes4
call gcloud projects add-iam-policy-binding "%PROJECT_ID%" --member="%ACCOUNT_TYPE%:%ACCOUNT%" --role="roles/deploymentmanager.editor"
if errorlevel 1 (
  echo "roles/deploymentmanager.editor couldn't be added please assign roles/deploymentmanager.editor to account used by cli"
  GOTO END
)
echo "roles/deploymentmanager.editor is now added to user"
goto :end4
:no4
echo "Exiting as roles/deploymentmanager.editor is required"
GOTO END
:end4


SET "IS_SERADM="
SET "AREYOUSURE5="

FOR /F "tokens=* USEBACKQ" %%F IN (`gcloud projects get-iam-policy "%PROJECT_ID%" ^| findstr iam.serviceAccountAdmin`) DO (
  SET IS_SERADM=%%F
)

if ["%IS_SERADM%"] == [""] (
  GOTO choice5
) else (
  echo "it's roles/iam.serviceAccountAdmin"
  GOTO end5
)
:choice5
SET /P AREYOUSURE5="The roles/iam.serviceAccountAdmin is needed, please reply to add role to the account - y/n "
IF /I "%AREYOUSURE5%" EQU "y" GOTO yes5
IF /I "%AREYOUSURE5%" EQU "n" GOTO no5
goto choice5
:yes5
call gcloud projects add-iam-policy-binding "%PROJECT_ID%" --member="%ACCOUNT_TYPE%:%ACCOUNT%" --role="roles/iam.serviceAccountAdmin"
if errorlevel 1 (
  echo "roles/iam.serviceAccountAdmin couldn't be added please assign roles/iam.serviceAccountAdmin to account used by cli"
  GOTO END
)
echo "roles/iam.serviceAccountAdmin is now added to user"
goto :end5
:no5
echo "Exiting as roles/iam.serviceAccountAdmin is required"
GOTO END
:end5

SET "SERVICES_ACCOUNT_FULL="
SET "SERVICES_ACCOUNT="
FOR /F "tokens=* USEBACKQ" %%F IN (`gcloud projects get-iam-policy %PROJECT_ID% ^| findstr cloudservices`) DO (
  SET SERVICES_ACCOUNT_FULL=%%F
)

set "string1=%SERVICES_ACCOUNT_FULL:serviceAccount:=" & set "SERVICES_ACCOUNT=%"
call gcloud projects add-iam-policy-binding "%PROJECT_ID%" --member="serviceAccount:%SERVICES_ACCOUNT%" --role="roles/owner"

SET "CO_DEPLOY="

FOR /F "tokens=* USEBACKQ" %%F IN (`gcloud deployment-manager deployments list --project "%PROJECT_ID%" ^| findstr co-deployment`) DO (
  SET CO_DEPLOY=%%F
)

if ["%IS_SERADM%"] == [""] (
  call gcloud deployment-manager deployments create co-deployment --project "%PROJECT_ID%" --template https://storage.googleapis.com/co-virtasant/service_account.jinja
  if errorlevel 1 (
    echo "unable to create deployment make sure the project has billing enabled"
    GOTO END
  )
  echo "co-deployment created"
) else (
  call gcloud deployment-manager deployments update co-deployment --project "%PROJECT_ID%" --template https://storage.googleapis.com/co-virtasant/service_account.jinja
  if errorlevel 1 (
    echo "unable to create deployment make sure the project has billing enabled"
    GOTO END
  )
  echo "co-deployment created"
)

call gcloud projects add-iam-policy-binding "%PROJECT_ID%" --member="serviceAccount:co-service-account@%PROJECT_ID%.iam.gserviceaccount.com" --role="projects/%PROJECT_ID%/roles/co_custom_role"
call gcloud projects add-iam-policy-binding "%PROJECT_ID%" --member="serviceAccount:co-service-account@%PROJECT_ID%.iam.gserviceaccount.com" --role="roles/iam.serviceAccountUser"
call gcloud iam service-accounts keys create co-sa-key.json --iam-account=co-service-account@"%PROJECT_ID%".iam.gserviceaccount.com

call certutil -encodehex -f co-sa-key.json co-sa-key-base64.json 0x40000001

for /F %%i in (co-sa-key-base64.json) do @echo "https://diag.virtasant.com/connect/cloud_gcp#%%i"

for /F %%i in (co-sa-key-base64.json) do @start "" "https://diag.virtasant.com/connect/cloud_gcp#%%i"

:END
