resource "aws_eks_node_group" "system-nodes" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "system-nodes"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn

  ami_type       = "AL2_ARM_64"
  capacity_type  = "ON_DEMAND"
  instance_types = ["t4g.micro"]

  scaling_config {
    desired_size = 4
    max_size     = 5
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "system"
  }

  # Tags
  tags = {
    "Name" = format("%s-%s", var.eks_cluster_name, "system-nodes")
  }

  subnet_ids = local.subnets_private_ids

  depends_on = [
    aws_iam_role_policy_attachment.node_group_eks_policy_attachment,
  ]
}
