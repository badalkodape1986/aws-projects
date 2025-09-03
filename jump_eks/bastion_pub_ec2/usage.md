🔹 Test

SSH into Bastion:

ssh -i my-keypair.pem ec2-user@$(terraform output -raw bastion_ip)


From Bastion, check IAM role:

aws sts get-caller-identity


Configure kubeconfig and check nodes:

aws eks --region us-east-1 update-kubeconfig --name my-eks-cluster
kubectl get nodes


✅ You should see 2 worker nodes.
# to get IPV4 address
curl -4 ifconfig.me
