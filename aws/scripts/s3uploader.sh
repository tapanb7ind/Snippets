#!/bin/bash

#s3 and default Parameters
S3_BUCKET_NAME="performanceengineering"
S3_FOLDER_PATH="/${ENV_STAGE}/TestResults/${TESTIDENTIFIER}"
S3STORAGETYPE="STANDARD" #REDUCED_REDUNDANCY or STANDARD etc.
ENV_STAGE="dev" # or "integration" or "preprod"
MAX_FILE_SIZE=262144000 # 250 mb
RESULTS_BASE_DIR="/Archive"

# Parameters must be passed while executing script
TESTIDENTIFIER=""
UPLOADTYPE=""
S3KEY=""
S3SECRET=""

#./scripts/aws/s3uploader.sh testidentifier="0AB5A8EB-B68A-459B-9B30-2BC2A5C467E3" stage="dev" type="testresults" s3bucket="performanceengineering" s3key="${AWS_ACCESS_KEY_ID}" s3secret="${AWS_SECRET_ACCESS_KEY}"
#./scripts/aws/s3uploader.sh
        # testidentifier="0AB5A8EB-B68A-459B-9B30-2BC2A5C467E3"
        # stage="dev"
        # type="testresults"
        # s3bucket="performanceengineering"
        # s3key="${AWS_ACCESS_KEY_ID}"
        # s3secret="${AWS_SECRET_ACCESS_KEY}"


# region Argument reader
for ARGUMENT in "$@"
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)

    case "$KEY" in
            testidentifier)             testidentifier=${VALUE} ;;    # all files will be uploaded under a folder with testidentifier name within the s3dir
            stage)                      stage=${VALUE} ;;
            uploadtype)                 uploadtype=${VALUE} ;;      # testresults or something else
            s3bucket)                   s3bucket=${VALUE} ;;
            s3key)                      s3key=${VALUE} ;;
            s3secret)                   s3secret=${VALUE} ;;
            resultsbasedir)             resultsbasedir=${VALUE} ;;
            *)
    esac
done

# endregion

echo ""
echo ""
echo "STARTING S3 Upload"
echo ""


if [[ ! $testidentifier ]]; then
    echo "[WARN] testidentifier is empty"
#    exit 1
else
  TESTIDENTIFIER=$testidentifier
fi;

if [[ ! $ENV_STAGE ]]; then
    echo "[WARN] stage is empty. File(s) will be uploaded in 'dev'"
#    exit 1
  ENV_STAGE="dev"
else
  ENV_STAGE=$stage
fi;

if [[ ! $s3bucket ]]; then
    S3_BUCKET_NAME="performanceengineering"
    echo "[INFO] s3bucket is empty, using default s3-bucket [${S3_BUCKET_NAME}]"
else
  echo "[WARN] new bucket name [${s3bucket}] provided, overwriting default"
  S3_BUCKET_NAME=$s3bucket
fi;

if [[ ! $uploadtype ]]; then
    echo "[WARN] uploadtype is empty. File(s) will be uploaded in s3://${S3_BUCKET_NAME}/${ENV_STAGE}/TestResults"
#    exit 1
  UPLOADTYPE="TestResults"
else
  UPLOADTYPE=$uploadtype
fi;

S3_FOLDER_PATH="/${ENV_STAGE}/${UPLOADTYPE}/${TESTIDENTIFIER}/"

if [[ ! $s3key ]]; then
    echo "[ERROR] s3key is empty"
    exit 1
else
  S3KEY=$s3key
fi;

if [[ ! $s3secret ]]; then
    echo "[ERROR] s3secret is empty"
    exit 1
else
  S3SECRET=$s3secret
fi;

if [[ ! $resultsbasedir ]]; then
    RESULTS_BASE_DIR="${WORKSPACE}/Archive"
    echo "[INFO] Using default directory path for results [${RESULTS_BASE_DIR}]"
else
    RESULTS_BASE_DIR=$resultsbasedir
fi;

fileUploadList=()

function getFilesInDirectory
{
  current_dir=$1
  for tbdUploadItem in $current_dir/*;
  do
#    echo "[DEBUG] File: ${tbdUploadItem}"
    if [[ -f ${tbdUploadItem} ]]; then
#      echo "[DEBUG] Current item is a FILE"
      fileUploadList+=("${tbdUploadItem}")
    else
#      echo "[DEBUG] Current item is a DIRECTORY"
      getFilesInDirectory "$tbdUploadItem"
    fi;
  done;
}

function putS3
{
  filePathWithExtension=$1
  aws_path=$2
  filename=$(basename "$1")

  lookupstring="//"
  replacewith="/"
  aws_path=${aws_path//${lookupstring}/"${replacewith}"}

  echo "[DEBUG] From: $filePathWithExtension"
  echo "[DEBUG] To: s3://$S3_BUCKET_NAME$S3_FOLDER_PATH"
  echo "[DEBUG] Trying to upload file to [$S3_BUCKET_NAME$aws_path$filename]"


  date=$(date +"%a, %d %b %Y %T %z")
  content_type='application/x-compressed-tar'
  string="PUT\n\n$content_type\n$date\n/$S3_BUCKET_NAME$aws_path$filename"

  signature=$(echo -en "$string" | openssl sha1 -hmac "$S3SECRET" -binary | base64)

  response_code=$(curl -X PUT -T "$filePathWithExtension" \
    -H "Host: $S3_BUCKET_NAME.s3.amazonaws.com" \
    -H "Content-Type: $content_type" \
    -H "Date: $date" \
    -H "Authorization: AWS $S3KEY:$signature" \
    "https://$S3_BUCKET_NAME.s3.amazonaws.com$aws_path$filename" \
    --write-out "%{http_code}" --silent \
    )

  if [[ "$response_code" -ne 200 ]] ; then
    echo "[WARN] Upload not successful [Status-Code: $response_code]"
  else
    echo "[INFO] Upload successful [$S3_BUCKET_NAME$aws_path$filename]"
  fi
}

echo ""
echo "[INFO] Trying to upload all files @[$RESULTS_BASE_DIR/$TESTIDENTIFIER]"
echo ""
ls -ltr "$RESULTS_BASE_DIR/$TESTIDENTIFIER/"
echo ""
BASE_DIR="$RESULTS_BASE_DIR/$TESTIDENTIFIER"
echo "[DEBUG] Building list of files to upload"
getFilesInDirectory "$BASE_DIR/"

filesToUpload=${#fileUploadList[@]}
echo "[INFO] There are [${filesToUpload}] files to upload to S3"
echo ""

for currentFilePath in "${fileUploadList[@]}"
do
#   :
   filename="$(basename $currentFilePath)"
   echo "[INFO] Initiating File Upload [Name:$filename, Path:${currentFilePath}]"
  new_s3_path=${currentFilePath//${BASE_DIR}/""}
  new_s3_path=${new_s3_path//${filename}/""}

#  echo "[DEBUG] S3 Folder Path: ${S3_FOLDER_PATH}${new_s3_path}"
  putS3 "$currentFilePath" "${S3_FOLDER_PATH}${new_s3_path}"
  echo ""
done


echo ""
echo ""
echo "[INFO] COMPLETED file/folder upload to S3"
echo ""
echo ""

# ./scripts/aws/s3uploader.sh testidentifier="0AB5A8EB-B68A-459B-9B30-2BC2A5C467E3" stage="dev"
      # type="testresults" s3bucket="performanceengineering"
      # s3key="${AWS_ACCESS_KEY_ID}" s3secret="${AWS_SECRET_ACCESS_KEY}"
