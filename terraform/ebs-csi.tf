# EBS CSI driver to back the gp3 StorageClass the Postgres StatefulSet claims
# attached to preexisting cluster
resource "aws_iam_role" "ebs_csi" {
  count              = var.manage_ebs_csi_addon ? 1 : 0
  name               = "${var.name_prefix}-ebs-csi"
  description        = "EBS CSI driver controller: provision/attach gp3 volumes"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume["ebs_csi"].json
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  count      = var.manage_ebs_csi_addon ? 1 : 0
  role       = aws_iam_role.ebs_csi[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi" {
  count                       = var.manage_ebs_csi_addon ? 1 : 0
  cluster_name                = data.aws_eks_cluster.this.name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = aws_iam_role.ebs_csi[0].arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_iam_role_policy_attachment.ebs_csi]
}
