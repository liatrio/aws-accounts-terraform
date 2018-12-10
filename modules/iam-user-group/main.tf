resource "aws_iam_user" "user" {
  name          = "${var.user_name}"
  force_destroy = true
}

resource "aws_iam_user_group_membership" "user_membership" {
  user   = "${aws_iam_user.user.name}"
  groups = ["${var.user_groups}"]
}
