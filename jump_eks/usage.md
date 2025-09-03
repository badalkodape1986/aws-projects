🔹 Test

SSH into Bastion:

ssh -i my-keypair.pem ec2-user@$(terraform output -raw bastion_ip)


From Bastion, configure EKS and test:

aws eks --region us-east-1 update-kubeconfig --name my-eks-cluster
kubectl get nodes


You should see 2 worker nodes ready.
