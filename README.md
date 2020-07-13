# AWS Organization Terraform

This repository contains the Terraform configurations needed to manage a multi-account AWS organization and the various roles that will be used within the accounts.

At Liatrio, we used this as the foundation for our accounts. We created a private fork that contains the actual users and resources used in our accounts.

Related blog post: [liatrio.com/blog/secure-aws-account-structure-with-terraform-and-terragrunt](https://www.liatrio.com/blog/secure-aws-account-structure-with-terraform-and-terragrunt)

Be sure to modify `shared.hcl` to customize for your organization.

## Prerequisites

- [Terraform](https://www.terraform.io/)
- [Terragrunt](https://github.com/gruntwork-io/terragrunt)
- [Keybase](https://keybase.io) account (only required during initialization to get a secret key for the initial admin user)

## Initialization

See the [master](master) folder for initial setup instructions the first time the organization is being created.

## Post-Initialization

Future Terraform runs must be run by an IAM user in the Infosec account with the appropriate group assignment for the target account:

- Infosec account: `InfosecAdmins` group
- Prod account: `ProdAdmins` group
- Non-Prod account: `NonProdAdmins` group

## FAQs

### In which account does the Terraform state S3 bucket live?

The Terraform state is stored in an S3 bucket within the Infosec account.

### What's the workflow after initial creation?

Terraform configurations should be added to the appropriate subfolder under the [environments](environments) folders and applied by running `terragrunt plan` / `terragrunt apply` from there. You'll need to be running as an IAM user with permission to assume the Administrator role for the account. We find [`aws-vault`](https://github.com/99designs/aws-vault) to be helpful with user credential management.

### What if I want to add another account besides prod and non-prod after initial creation?

Additional accounts can be added by replicating and modifying one of the subfolders under [accounts](accounts) and re-running the [master](master) init script as the `terraform-init` IAM user. (You'll need to recreate the user first, because you deleted it after the first run, right?) You can run the init script with the `-l` parameter to skip the step of temporarily storing state locally since you've already created the S3 bucket.