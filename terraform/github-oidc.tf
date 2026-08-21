# GitHub Actions OIDC role (Terraform plan/apply)

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

locals {
  github_oidc_arn = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : "arn:${local.partition}:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "ci_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # plan runs on PRs, apply runs on main
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repo}:ref:refs/heads/main",
        "repo:${var.github_repo}:pull_request",
      ]
    }
  }
}

resource "aws_iam_role" "ci" {
  count              = var.manage_ci_role ? 1 : 0
  name               = "${var.name_prefix}-ci"
  description        = "GitHub Actions: terraform plan/apply for the Teleport AWS layer"
  assume_role_policy = data.aws_iam_policy_document.ci_assume.json
}

# TODO: tighten scope here
resource "aws_iam_role_policy_attachment" "ci" {
  count      = var.manage_ci_role ? 1 : 0
  role       = aws_iam_role.ci[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/PowerUserAccess"
}
