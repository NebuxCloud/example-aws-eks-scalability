resource "aws_iam_role" "eks_cluster_role" {
  name               = "${var.eks_cluster_name}-eks-cluster-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Attach AmazonEKSClusterPolicy to the IAM role for the cluster
resource "aws_iam_role_policy_attachment" "cluster_eks_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Create iam role for the node group
resource "aws_iam_role" "eks_node_group_role" {
  name               = "${var.eks_cluster_name}-eks-node-group-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Attach AmazonEKSWorkerNodePolicy to the IAM role for the node group
resource "aws_iam_role_policy_attachment" "node_group_eks_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

# Attach AmazonEKS_CNI_Policy to the IAM role for the node group
resource "aws_iam_role_policy_attachment" "node_group_cni_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

# Attach AmazonEC2ContainerRegistryReadOnly to the IAM role for the node group
resource "aws_iam_role_policy_attachment" "node_group_ecr_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

# Prepare IRSA for AWS Load Balancer Controller
## Create policy for AWS Load Balancer Controller
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "${var.eks_cluster_name}-alb-controller-policy"
  description = "Policy for ALB controller"
  policy      = file("policies/aws-alb-ingress-controller.json")
}
