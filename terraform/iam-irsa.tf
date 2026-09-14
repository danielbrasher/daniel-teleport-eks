# IRSA trust policies (assuming preexisting IAM OIDC provider for cluster)

locals {
  irsa_service_accounts = {
    auth      = "system:serviceaccount:${var.teleport_namespace}:teleport"
    discovery = "system:serviceaccount:${var.teleport_namespace}:teleport-kube-agent"
    eso       = "system:serviceaccount:${var.external_secrets_namespace}:${var.external_secrets_service_account}"

    cert_manager = "system:serviceaccount:${var.cert_manager_namespace}:${var.cert_manager_service_account}"
    # fixed by the aws-ebs-csi-driver addon
    ebs_csi = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
  }
}

data "aws_iam_policy_document" "irsa_assume" {
  for_each = local.irsa_service_accounts

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:sub"
      values   = [each.value]
    }
  }
}

# Auth/Proxy pods (teleport/teleport SA -> S3 session recordings)
resource "aws_iam_role" "auth" {
  name               = "${var.name_prefix}-auth"
  description        = "Teleport Auth/Proxy: S3 session recording storage"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume["auth"].json
}

data "aws_iam_policy_document" "sessions_bucket" {
  statement {
    sid    = "BucketLevel"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:ListBucketMultipartUploads",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
    ]
    resources = [data.aws_s3_bucket.sessions.arn]
  }

  statement {
    sid    = "ObjectLevel"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = ["${data.aws_s3_bucket.sessions.arn}/*"]
  }
}

resource "aws_iam_policy" "sessions_bucket" {
  name   = "${var.name_prefix}-session-recordings"
  policy = data.aws_iam_policy_document.sessions_bucket.json
}

resource "aws_iam_role_policy_attachment" "auth_sessions" {
  role       = aws_iam_role.auth.name
  policy_arn = aws_iam_policy.sessions_bucket.arn
}

# Discovery Service pod (teleport/teleport-kube-agent SA)
resource "aws_iam_role" "discovery" {
  name               = "${var.name_prefix}-discovery"
  description        = "Teleport Discovery Service: EC2 discovery + SSM agent install"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume["discovery"].json
}

data "aws_iam_policy_document" "discovery" {
  statement {
    sid       = "FindInstances"
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"] # DescribeInstances doesn't have resource-level scoping
  }

  statement {
    sid    = "InspectSSMState"
    effect = "Allow"
    actions = [
      "ssm:DescribeInstanceInformation",
      "ssm:GetCommandInvocation",
      "ssm:ListCommandInvocations",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "RunInstallerDocument"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = [aws_ssm_document.installer.arn]
  }
  # narrowed to discovery tag so installer can't be run cluster-wide
  statement {
    sid       = "RunInstallerOnTaggedInstances"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:${local.partition}:ec2:${var.region}:${local.account_id}:instance/*"]

    condition {
      test     = "StringEquals"
      variable = "ssm:resourceTag/${var.discoverable_tag.key}"
      values   = [var.discoverable_tag.value]
    }
  }
}

resource "aws_iam_policy" "discovery" {
  name   = "${var.name_prefix}-discovery"
  policy = data.aws_iam_policy_document.discovery.json
}

resource "aws_iam_role_policy_attachment" "discovery" {
  role       = aws_iam_role.discovery.name
  policy_arn = aws_iam_policy.discovery.arn
}

# External Secrets Operator -> AWS Secrets Manager
resource "aws_iam_role" "external_secrets" {
  name               = "${var.name_prefix}-external-secrets"
  description        = "External Secrets Operator: read the Teleport license and Flux GitHub App creds from Secrets Manager"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume["eso"].json
}

data "aws_iam_policy_document" "external_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      aws_secretsmanager_secret.license.arn,
      aws_secretsmanager_secret.flux_github_app.arn,
      aws_secretsmanager_secret.flux_github_dispatch_app.arn,
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.teleport_secrets.arn]
  }
}

resource "aws_iam_policy" "external_secrets" {
  name   = "${var.name_prefix}-external-secrets"
  policy = data.aws_iam_policy_document.external_secrets.json
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  role       = aws_iam_role.external_secrets.name
  policy_arn = aws_iam_policy.external_secrets.arn
}

# cert-manager -> Route53
# for the DNS-01 solver on the letsencrypt-production ClusterIssuer (infrastructure/config/clusterissuer.yaml)
resource "aws_iam_role" "cert_manager" {
  name               = "${var.name_prefix}-cert-manager"
  description        = "cert-manager: solve ACME DNS-01 challenges in Route53"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume["cert_manager"].json
}

data "aws_iam_policy_document" "cert_manager" {
  statement {
    sid       = "PollChallengePropagation"
    effect    = "Allow"
    actions   = ["route53:GetChange"]
    resources = ["arn:${local.partition}:route53:::change/*"]
  }

  # scoped to single zone
  statement {
    sid    = "WriteChallengeRecords"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]
    resources = ["arn:${local.partition}:route53:::hostedzone/${data.aws_route53_zone.this.zone_id}"]
  }

  # zone lookup by name (ClusterIssuer doesn't pin hostedZoneID)
  statement {
    sid       = "FindZone"
    effect    = "Allow"
    actions   = ["route53:ListHostedZonesByName"]
    resources = ["*"] # ListHostedZonesByName has no resource-level scoping
  }
}

resource "aws_iam_policy" "cert_manager" {
  name   = "${var.name_prefix}-cert-manager"
  policy = data.aws_iam_policy_document.cert_manager.json
}

resource "aws_iam_role_policy_attachment" "cert_manager" {
  role       = aws_iam_role.cert_manager.name
  policy_arn = aws_iam_policy.cert_manager.arn
}
