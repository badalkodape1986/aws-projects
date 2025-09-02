Run:

chmod +x eks_setup.sh
./eks_setup.sh


Wait ~15 minutes (EKS cluster provisioning).

Get app URL:

kubectl get svc web-service


Open the EXTERNAL-IP in browser → 🎉 Hello NGINX from EKS!
