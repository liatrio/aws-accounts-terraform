data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "Assume${replace(title(var.account_name),"/-| /","")}${replace(title(var.role),"/-| /","")}Role"
    actions = ["sts:AssumeRole"]

    resources = [
      "arn:aws:iam::${var.account_id}:role/${var.role}",
    ]
  }
}

resource "aws_iam_policy" "assume_role" {
  name        = "${replace(title(var.account_name),"/-| /","")}${replace(title(var.role),"/-| /","")}RoleAccess"
  policy      = "${data.aws_iam_policy_document.assume_role.json}"
  description = "Grants role assuption for the ${title(var.role)} role in the ${title(var.account_name)} account"
}
