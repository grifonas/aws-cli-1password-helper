#!/bin/bash
# Based on https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sourcing-external.html
ONEPASS_ITEM_STRUCTURE="#########################\n1Password Item Structure \n#########################\n\nYour items must contain the following:\n\n Fields:\n - 'access key id'\n - 'secret access key.\n - 'aws-cli-profile'\n\n Tags:\n - 'aws_cred_for_sourcing'"
CLI_USAGE="Put this line under the [name of your AWS CLI profile] in your ~/.aws/credentials:\n\n   'credential_process = \"${0}\" [1Password Item name]'"
MANAGE_CRED_FILE_USAGE="To manage your ~/.aws/credentials file, run this script with the 'build_awc_cli_cred_file' argument:\n\n   ${0} build_awc_cli_cred_file\n\n   This command can be run every time you add a new AWS cred. pair to your 1Password.\n\n${ONEPASS_ITEM_STRUCTURE}"
USAGE="This script does two things.\n\n 1. Allows AWS CLI to use creds from 1Password.\n\n    ${CLI_USAGE}\n\n 2. Manages your ~/.aws/credentials file based on your 1Password items.\n\n   ${MANAGE_CRED_FILE_USAGE}\n"

AWS_CRED_ITEM_TAG="aws_cred_for_sourcing"
ONE_PASS_AWS_PROFILE_FIELD="aws-cli-profile"
ONE_PASS_AWS_REGION_FIELD="default-region"
PASS_TO_AWS_CRED_FILE="${HOME}/.aws/credentials"
PASS_TO_AWS_CONFIG_FILE="${HOME}/.aws/config"

function backup_aws_cred_file(){
  echo "Backing up ${PASS_TO_AWS_CRED_FILE}"
  cp ${PASS_TO_AWS_CRED_FILE} ${PASS_TO_AWS_CRED_FILE}-$(date +%Y-%m-%d-%H-%M-%S).bak
}
function backup_aws_config_file(){
  echo "Backing up ${PASS_TO_AWS_CONFIG_FILE}"
  cp ${PASS_TO_AWS_CONFIG_FILE} ${PASS_TO_AWS_CONFIG_FILE}-$(date +%Y-%m-%d-%H-%M-%S).bak
}
function list_aws_cred_items(){
  op item list --tags ${AWS_CRED_ITEM_TAG} | awk '{print $1}' | grep -v ID
}

function build_cred_file(){
  ITEM_ID="${1}"
  FULL_ITEM=$(op item get ${ITEM_ID} --reveal --format json)
  ITEM_TITLE=$(echo $FULL_ITEM | jq -r '.title')
  PROFILE_NAME=$(echo $FULL_ITEM | jq -r ".fields[] | select(.label == \"${ONE_PASS_AWS_PROFILE_FIELD}\") | .value" 2>&1)
  REGION_NAME=$(echo $FULL_ITEM | jq -r ".fields[] | select(.label == \"${ONE_PASS_AWS_REGION_FIELD}\") | .value" 2>&1)

  # Check the exit status
  if [ $? -ne 0 ]; then
    echo "An unexpected error occurred: ${PROFILE_NAME}"
    return 1
  fi
  if [[ -z ${PROFILE_NAME} ]]; then
    echo "The field ${ONE_PASS_AWS_PROFILE_FIELD} does not exist in the item ${ITEM_TITLE}."
    return 1
  fi

  echo "Filling ${PASS_TO_AWS_CRED_FILE} with the following:"
  echo "[$PROFILE_NAME]"
  echo "credential_process = \"${0}\" ${ITEM_ID}"
  echo "[$PROFILE_NAME]" >> ${PASS_TO_AWS_CRED_FILE}
  echo "credential_process = \"${0}\" ${ITEM_ID}" >> ${PASS_TO_AWS_CRED_FILE}
  if [[ ! -z ${REGION_NAME} ]]; then
    echo "Filling ${PASS_TO_AWS_CONFIG_FILE} with the following:"
    echo "[profile $PROFILE_NAME]"
    echo "region = $REGION_NAME"
    echo "[profile $PROFILE_NAME]" >> ${PASS_TO_AWS_CONFIG_FILE}
    echo "region = $REGION_NAME" >> ${PASS_TO_AWS_CONFIG_FILE}
  fi
}

function get_cred(){
  ONE_PASSWORD_ITEM="${1}"
  KEY_ID=$(op item get "${ONE_PASSWORD_ITEM}" --reveal --fields label='access key id')
  SECRET_KEY=$(op item get "${ONE_PASSWORD_ITEM}" --reveal --fields label='secret access key')
  echo -e {\"Version\": 1, \"AccessKeyId\": \"$KEY_ID\", \"SecretAccessKey\": \"$SECRET_KEY\"}
}
if [[ -z ${1} ]]; then
  echo -e "Usage:\n$USAGE"
  exit 1
fi

if [[ ${1} == "--help" ]] || [[ ${1} == "-h" ]]; then
  echo -e "Usage:\n$USAGE"
  exit 0
fi

if [[ "${1}" == "build_awc_cli_cred_file" ]]; then
  backup_aws_cred_file
  rm -f ${PASS_TO_AWS_CRED_FILE}
  backup_aws_config_file
  rm -f ${PASS_TO_AWS_CONFIG_FILE}
  for ITEM in $(list_aws_cred_items); do
    build_cred_file "${ITEM}"
  done
fi

if [[ "${1}" != "build_awc_cli_cred_file" ]] && [[ "${1}" != "--help" ]]; then
  get_cred "${1}"
fi
