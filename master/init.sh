#!/bin/bash
set -e

DEFAULT_REGION='us-east-1'

function usage {
    echo "DESCRIPTION:"
    echo "  Script for initializing an AWS account structure. See README for more details."
    echo "  *** MUST BE RUN WITH ADMIN CREDENTIALS FOR terraform-init USER IN THE MASTER ACCOUNT ***"
    echo ""
    echo "USAGE:"
    echo "  init.sh -a terraform_init_access_key -s terraform_init_secret_key -k keybase_profile"
    echo "  [-r default_region] [-l] [-u user_name]"
    echo ""
    echo "OPTIONS"
    echo "  -l   skip using local state, can be used after the inital run"
    echo "  -u   generate a password for a specified user - will only work if the user does not already have a password"
}

function pushd () {
    command pushd "$@" > /dev/null
}

function popd () {
    command popd "$@" > /dev/null
}

while getopts "a:s:k:r:lu:h" option; do
    case ${option} in
        a ) ACCESS_KEY=$OPTARG;;
        s ) SECRET_KEY=$OPTARG;;
        k ) KEYBASE_PROFILE=$OPTARG;;
        r ) DEFAULT_REGION=$OPTARG;;
        l ) SKIP_LOCAL_STATE=1;;
        u ) LOGIN_USER=$OPTARG;;
        h )
            usage
            exit 0
            ;;
        \? )
            echo "Invalid option: -$OPTARG" 1>&2
            usage
            exit 1
            ;;
    esac
done

if [[ -z "${ACCESS_KEY}" ]]; then
    echo "Please provide the terraform-init user's AWS access key as -a key" 1>&2
    VALIDATION_ERROR=1
fi
if [[ -z "${SECRET_KEY}" ]]; then
    echo "Please provide the terraform-init user's AWS secret access key as -s secret " 1>&2
    VALIDATION_ERROR=1
fi
if [[ -z "${KEYBASE_PROFILE}" ]]; then
    echo "Please provide the keybase profile as -k profile " 1>&2
    VALIDATION_ERROR=1
fi
if [[ -n "${VALIDATION_ERROR}" ]]; then
    usage
    exit 1
fi

export AWS_DEFAULT_REGION=${DEFAULT_REGION}

function export_master_keys {
    echo "USING MASTER CREDENTIALS"
    export AWS_ACCESS_KEY_ID=${ACCESS_KEY}
    export AWS_SECRET_ACCESS_KEY=${SECRET_KEY}
}

function export_admin_keys {
    echo "USING ADMIN CREDENTIALS"
    export AWS_ACCESS_KEY_ID=${ADMIN_ACCESS_KEY}
    export AWS_SECRET_ACCESS_KEY=${ADMIN_SECRET_KEY}
}

pushd ./organization
export_master_keys
if [[ -n "${SKIP_LOCAL_STATE}" ]]; then
    echo "=== RUNNING ORG CONFIGS WITH REMOTE STATE ==="
    INFOSEC_AWS_ACCT=$(terraform output infosec_acct_id)
    export "TG_AWS_ACCT=${INFOSEC_AWS_ACCT}"
    terragrunt apply
    unset "TG_AWS_ACCT"
else
    echo "=== RUNNING ORG CONFIGS WITH LOCAL STATE ==="
    cp overrides/backend_local_override.tf .
    terragrunt init --terragrunt-config terraform-local.tfvars
    terragrunt apply --terragrunt-config terraform-local.tfvars
    INFOSEC_AWS_ACCT=$(terraform output infosec_acct_id)
    
    echo "=== COPYING LOCAL STATE TO S3 ==="
    rm ./backend_local_override.tf || true
    export "TG_AWS_ACCT=${INFOSEC_AWS_ACCT}"
    terragrunt init
    unset "TG_AWS_ACCT"
fi
MASTER_ALIAS=$(terraform output account_alias)
popd

echo "=== CREATING temp-admin USER ==="
pushd ./temp-admin
export "TG_AWS_ACCT=${INFOSEC_AWS_ACCT}"
terragrunt apply -var infosec_acct_id=${INFOSEC_AWS_ACCT} -var keybase=${KEYBASE_PROFILE}
unset "TG_AWS_ACCT"
ADMIN_ACCESS_KEY=$(terraform output temp_admin_access_key)
ADMIN_SECRET_KEY=$(terraform output temp_admin_secret_key | base64 --decode | keybase pgp decrypt)
popd
sleep 10 # give AWS some time for the new access key to be ready

echo "=== APPLYING ACCOUNTS CONFIGS ==="
export_admin_keys
pushd ../accounts/infosec
terragrunt init
terragrunt apply
INFOSEC_ALIAS=$(terraform output account_alias)
popd
pushd ../accounts/prod
terragrunt init
terragrunt apply
PROD_ALIAS=$(terraform output account_alias)
popd
pushd ../accounts/non-prod
terragrunt init
terragrunt apply
NONPROD_ALIAS=$(terraform output account_alias)
popd

if [[ -n "${LOGIN_USER}" ]]; then
    echo "=== GENERATING TEMP PASSWORD FOR ${LOGIN_USER} ==="
    pushd ../utility/one-time-login
    terragrunt apply -var user_name=${LOGIN_USER} -var infosec_acct_id=${INFOSEC_AWS_ACCT} -var keybase=${KEYBASE_PROFILE}
    ENCRYPTED_PASS=$(terraform output temp_password)
    terraform taint aws_iam_user_login_profile.login
    popd
fi

echo "=== DELETING temp-admin USER ==="
pushd ./temp-admin
export_master_keys
export "TG_AWS_ACCT=${INFOSEC_AWS_ACCT}"
terragrunt destroy -var infosec_acct_id=${INFOSEC_AWS_ACCT} -var keybase=${KEYBASE_PROFILE}
unset "TG_AWS_ACCT"
popd

echo "=== INITIALIZATION COMPLETE ==="

if [[ -n "${LOGIN_USER}" ]]; then
    echo "One-time password for ${LOGIN_USER}: $(echo ${ENCRYPTED_PASS} | base64 --decode | keybase pgp decrypt)"
fi

echo "Login URL: https://${INFOSEC_ALIAS}.signin.aws.amazon.com/console"
echo "Switch Role URLs -"
echo " Infosec Admin: https://signin.aws.amazon.com/switchrole?roleName=Administrator&account=${INFOSEC_ALIAS}"
echo " Prod Admin: https://signin.aws.amazon.com/switchrole?roleName=Administrator&account=${PROD_ALIAS}"
echo " NonProd Admin: https://signin.aws.amazon.com/switchrole?roleName=Administrator&account=${NONPROD_ALIAS}"
echo " Prod Developer: https://signin.aws.amazon.com/switchrole?roleName=Developer&account=${PROD_ALIAS}"
echo " NonProd Developer: https://signin.aws.amazon.com/switchrole?roleName=Developer&account=${NONPROD_ALIAS}"
echo " Master Billing: https://signin.aws.amazon.com/switchrole?roleName=Billing&account=${MASTER_ALIAS}"