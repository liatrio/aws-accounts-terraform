resource "aws_iam_role" "role" {
  name               = "${replace(title(var.role),"/-| /","")}"
  assume_role_policy = "${var.assume_role_policy_json}"
}

resource "aws_iam_role_policy_attachment" "role_policy" {
  role       = "${aws_iam_role.role.name}"
  policy_arn = "${var.role_policy_arn}"
}
