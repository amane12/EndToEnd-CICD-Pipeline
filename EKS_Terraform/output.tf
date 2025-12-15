output "cluster_id" {
  value = aws_eks_cluster.logging.id
}

output "node_group_id" {
  value = aws_eks_node_group.logging.id
}

output "vpc_id" {
  value = aws_vpc.logging_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.logging_subnet[*].id
}
