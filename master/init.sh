#!/bin/bash
set -e

DEFAULT_REGION='us-east-1'

function usage {
    echo "*** MUST BE RUN WITH ADMIN CREDENTIALS FOR terraform-init USER IN THE MASTER ACCOUNT ***"
    echo "Usage: init.sh -k terraform-init_access_key -s terraform-init_secret_key [-r default_region] [-l]"
    echo "  -l = skip using local state, can be used after the inital run"
}

while getopts "k:s:r:lh" option; do
    case ${option} in
        k ) ACCESS_KEY=$OPTARG;;
        s ) SECRET_KEY=$OPTARG;;
        r ) DEFAULT_REGION=$OPTARG;;
        l ) SKIP_LOCAL_STATE=1;;
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
    echo "Please provide the terraform-init user's AWS access key as -k key" 1>&2
    VALIDATION_ERROR=1
fi
if [[ -z "${SECRET_KEY}" ]]; then
    echo "Please provide the terraform-init user's AWS secret access key as -s secret " 1>&2
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
popd

echo "=== CREATING temp-admin USER ==="
pushd ./temp-admin
export "TG_AWS_ACCT=${INFOSEC_AWS_ACCT}"
terragrunt apply -var infosec_acct_id=${INFOSEC_AWS_ACCT}
unset "TG_AWS_ACCT"
ADMIN_ACCESS_KEY=$(terraform output temp_admin_access_key)
ADMIN_SECRET_KEY=$(terraform output temp_admin_secret_key | base64 --decode | keybase pgp decrypt)
popd

echo "=== APPLYING ACCOUNTS CONFIGS ==="
pushd ../accounts
export_admin_keys
terragrunt apply-all
popd

echo "=== DELETING temp-admin USER ==="
pushd ./temp-admin
export_master_keys
export "TG_AWS_ACCT=${INFOSEC_AWS_ACCT}"
terragrunt destroy -var infosec_acct_id=${INFOSEC_AWS_ACCT}
unset "TG_AWS_ACCT"
popd
