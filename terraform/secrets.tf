resource "aws_kms_key" "teleport_secrets" {
  description             = "Encrypts Teleport secrets in Secrets Manager"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "teleport_secrets" {
  name          = "alias/${var.name_prefix}-secrets"
  target_key_id = aws_kms_key.teleport_secrets.key_id
}

resource "aws_secretsmanager_secret" "license" {
  name        = "${var.name_prefix}/enterprise-license"
  description = "Teleport Enterprise license.pem"
  kms_key_id  = aws_kms_key.teleport_secrets.arn
}

resource "aws_secretsmanager_secret_version" "license_placeholder" {
  secret_id = aws_secretsmanager_secret.license.id

  secret_string = jsonencode({
    "license.pem" = "REPLACE_ME" # replaced out of band
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# GitHub App credentials for the Flux notification Provider (commit statuses)
# actual app name is "flux-daniel-teleport-github-app"
resource "aws_secretsmanager_secret" "flux_github_app" {
  name        = "${var.name_prefix}/flux-github-app"
  description = "GitHub App creds used by notification-controller to post commit statuses"
  kms_key_id  = aws_kms_key.teleport_secrets.arn
}

resource "aws_secretsmanager_secret_version" "flux_github_app_placeholder" {
  secret_id = aws_secretsmanager_secret.flux_github_app.id

  # replaced out of band
  secret_string = jsonencode({
    githubAppID             = "REPLACE_ME"
    githubAppInstallationID = "REPLACE_ME"
    githubAppPrivateKey     = "REPLACE_ME"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# GitHub App credentials for the githubdispatch notification Provider (opens issues+comments on issues for subsequent occurrences)
# separate GitHub app, separate permissions
# actual app name is "flux-daniel-teleport-gh-dsptch-app" (limit of 34 characters)
resource "aws_secretsmanager_secret" "flux_github_dispatch_app" {
  name        = "${var.name_prefix}/flux-github-dispatch-app"
  description = "GitHub App creds used by notification-controller to send repository_dispatch events"
  kms_key_id  = aws_kms_key.teleport_secrets.arn
}

resource "aws_secretsmanager_secret_version" "flux_github_dispatch_app_placeholder" {
  secret_id = aws_secretsmanager_secret.flux_github_dispatch_app.id

  # replaced out of band
  secret_string = jsonencode({
    githubAppID             = "REPLACE_ME"
    githubAppInstallationID = "REPLACE_ME"
    githubAppPrivateKey     = "REPLACE_ME"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
