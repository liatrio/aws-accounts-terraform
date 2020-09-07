resource "aws_organizations_policy" "regions" {
  name        = "DenyAllOutsideUSRegions"
  description = "Prevent resources from being created outside of the four US regions"

  content = <<CONTENT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyAllOutsideUSRegions",
            "Effect": "Deny",
            "NotAction": [
               "iam:*",
               "organizations:*",
               "route53:*",
               "budgets:*",
               "waf:*",
               "cloudfront:*",
               "globalaccelerator:*",
               "importexport:*",
               "support:*"
            ],
            "Resource": "*",
            "Condition": {
                "StringNotEquals": {
                    "aws:RequestedRegion": [
                        "us-east-1",
                        "us-east-2",
                        "us-west-1",
                        "us-west-2"
                    ]
                }
            }
        }
    ]
}
CONTENT

}

resource "aws_organizations_policy_attachment" "root_regions" {
  policy_id = aws_organizations_policy.regions.id
  target_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_policy" "cloudtrail" {
  name        = "ProtectCloudTrail"
  description = "Deny access to deleting or stopping CloudTrails"

  content = <<CONTENT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ProtectCloudTrail",
            "Effect": "Deny",
            "Action": [
                "cloudtrail:DeleteTrail",
                "cloudtrail:StopLogging"
            ],
            "Resource": "*"
        }
    ]
}
CONTENT

}

resource "aws_organizations_policy_attachment" "root_cloudtrail" {
  policy_id = aws_organizations_policy.cloudtrail.id
  target_id = aws_organizations_organization.org.roots[0]["id"]
}

resource "aws_organizations_policy" "iam_only" {
  name        = "InfosecRestrictions"
  description = "Restrictions for the infosec account"

  content = <<CONTENT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "InfosecRestrictions",
            "Effect": "Deny",
            "NotAction": [
                "iam:*",
                "sts:*",
                "dynamodb:*",
                "s3:*",
                "cloudtrail:*",
                "sns:*",
                "guardduty:*"
            ],
            "Resource": "*"
        }
    ]
}
CONTENT

}

resource "aws_organizations_policy_attachment" "infosec_iam_only" {
  policy_id = aws_organizations_policy.iam_only.id
  target_id = aws_organizations_account.infosec.id
}

