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

  # JSON with a single license.pem key; ESO maps it into the Secret.
  secret_string = jsonencode({
    "license.pem" = "REPLACE_ME"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}