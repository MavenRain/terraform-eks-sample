variable avail-zones {
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "oni-subnet" {
  default = "192.168"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "eks-example" {
  name = "terraform-eks-demo"

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

resource "aws_iam_role_policy_attachment" "eks-example-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.eks-example.name}"
}

resource "aws_iam_role_policy_attachment" "eks-example-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.eks-example.name}"
}

resource "aws_vpc" "boss" {
  cidr_block = "${var.oni-subnet}.0.0/16"
}

resource "aws_subnet" "oni" {
  count = "${length(var.avail-zones)}"
  vpc_id = "${aws_vpc.boss.id}"
  cidr_block = "${var.oni-subnet}.${count.index}.0/24"
  availability_zone = "${element(var.avail-zones, count.index)}"
}

resource "aws_eks_cluster" "demo" {
  name            = "terraform-eks-demo"
  role_arn        = "${aws_iam_role.eks-example.arn}"

    vpc_config {
    subnet_ids = ["${aws_subnet.oni.*.id}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.eks-example-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.eks-example-AmazonEKSServicePolicy",
  ]
}
  