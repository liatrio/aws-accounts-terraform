The Terraform configurations in this folder should be run from the master account to set up the sub-accounts and the necessary role assumptions for admin users.

Creates an AWS organization linked to the master account and three sub-accounts in the organization:

- Infosec
- Prod
- Non-Prod

Within each sub-account, it creates an admin role tied to the default administrator policy and sets up a trust with the infosec account for role assumption. Policies are created in the Infosec account that allow role assumption for each of those sub-account admin role. A `temp-admin` user is created with those policies attached.

A Terragrunt policy and associated role are created that allows updating the S3 bucket and Dynamo DB table that are used by Terraform for managing state. Terragrunt is configured to assume this role in the root `terraform.tfvars`.

## Prerequisites

This configuration will create an access key pair for the `temp-admin` user. The secret key will be PGP encrypted. In order to encrypt and decrypt the key, you must have a [keybase](https://keybase.io) account with a PGP key applied and have the keybase app running during the run.

## Usage

The following steps must be performed manually through the AWS Console before the Terraform can be run:
1. Create the AWS root account and promptly lock it down.
2. Create the policy named `TerraformInit` as defined in `TerraformInit-IAM-Policy.txt`. (Replace with the AWS root account ID.)
3. Create an `terraform-init` IAM user (no console access) and apply the `TerraformInit` policy.

Run the Terraform configurations as the `terraform-init` user to setup the initial accounts and users:
1. Run the `init.sh` script from the `init` folder. Pass the access key and secret key of the `terraform-init` user as parameters.
2. The script will configure Terragrunt to use a local backend for state and apply the configurations from the `organizations` folder to create the sub-accounts.
3. It will then configure Terragrunt to use the S3 remote backend and re-init Terraform to copy the state. When propmted, confirm that you want to copy the existing state to the new S3 backend (or overwrite it, if you run this multiple times).
4. The script will then run the `temp-admin` configurations to create the `temp-admin` user. Provide the keybase username when prompted.
5. It will then use the output of the apply to retrieve the secret key and encrypted secret access key for the `temp-admin` user and echo the credentials to the console.

If you need to re-apply the configurations after the state has been copied to S3, add the `-l` flag to the `init.sh` command. This will copy the remote state back to your local before applying the configurations. You will need to provide the keys for both the `terraform-init` user and the `temp-admin` user.

Once initialization is complete, delete the `terraform-init` IAM user from the master account. Future terragrunt runs should be done by IAM users with appropriate permissions.
