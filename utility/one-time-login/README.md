# One-Time-Login

This module can be used to generate a one-time-login for an existing IAM user. This can only be run once per user.

Must run as an IAM user with Administrator role access in the infosec account.

## Usage
`terragrunt apply -var user_name=UserName -var infosec_acct_id=11111111111 -var keybase=keybase_user`

To decrypt the password:
`terraform output temp_password | base64 --decode | keybase pgp decrypt`

Taint the resource after fetching the password if you will need to run again for another user:
`terraform taint aws_iam_user_login_profile.login`