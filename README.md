# Govt Prep - Web Application

A comprehensive government exam preparation platform deployed on Azure using modern DevOps practices.

## 🚀 Quick Start

### Prerequisites
- Azure account with active subscription
- Azure CLI installed
- Terraform installed
- Docker Desktop installed
- kubectl installed
- Ansible installed (optional)

### Automated Deployment (Windows PowerShell)

```powershell
# Run the automated deployment script
.\deploy.ps1
```

This script will:
1. ✅ Check Azure authentication
2. ✅ Provision infrastructure (Resource Group, ACR, AKS)
3. ✅ Build Docker image
4. ✅ Push to Azure Container Registry
5. ✅ Deploy to Kubernetes
6. ✅ Verify deployment
7. ✅ Display access information

### Manual Deployment

For detailed step-by-step instructions, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

## 📁 Project Structure

```
GOVT-PREP-WEB-APP/
├── .github/
│   └── workflows/
│       └── deploy.yml              # GitHub Actions CI/CD pipeline
├── .dockerignore                   # Docker ignore file
├── ansible/
│   └── playbook.yml                # Ansible deployment automation
├── iac/
│   ├── k8s/
│   │   ├── deployment.yml          # Kubernetes deployment
│   │   └── service.yml             # Kubernetes service (LoadBalancer)
│   ├── main.tf                     # Terraform main configuration
│   ├── variables.tf                # Terraform variables
│   └── outputs.tf                  # Terraform outputs
├── IMG/                            # Application images
├── deploy.ps1                      # Automated deployment script
├── Dockerfile                      # Docker image configuration
├── index.html                      # Application entry point
├── contact.html
├── courses.html
├── login.html
├── register.html
├── DEPLOYMENT_GUIDE.md             # Detailed deployment guide
└── README.md                       # This file
```

## 🛠️ Technologies Used

- **Frontend**: HTML5, CSS3
- **Containerization**: Docker
- **Infrastructure as Code**: Terraform
- **Cloud**: Azure (AKS, ACR)
- **Orchestration**: Kubernetes
- **Configuration Management**: Ansible
- **CI/CD**: GitHub Actions
- **Version Control**: Git/GitHub

## 📋 Deployment Steps Overview

### Phase 1: Azure Setup
```powershell
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### Phase 2: Infrastructure Provisioning
```powershell
cd iac
terraform init
terraform plan
terraform apply
```

### Phase 3: Build and Push Docker Image
```powershell
az acr login --name govtprepregistry
docker build -t govtprepregistry.azurecr.io/govt-prep-app:latest .
docker push govtprepregistry.azurecr.io/govt-prep-app:latest
```

### Phase 4: Deploy to Kubernetes
```powershell
az aks get-credentials --resource-group govt-prep-rg --name govt-prep-aks
kubectl apply -f iac/k8s/deployment.yml
kubectl apply -f iac/k8s/service.yml
```

### Phase 5: Verify Deployment
```powershell
kubectl get pods -l app=govt-prep
kubectl get service govt-prep-service
```

### Phase 6: Access Application
```powershell
kubectl get service govt-prep-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
# Open browser to http://EXTERNAL_IP
```

## 🔧 Configuration

### Terraform Variables
Edit `iac/variables.tf` to customize:
- Resource group name
- AKS cluster name
- ACR name
- Node count
- Azure region

### Kubernetes Configuration
Edit `iac/k8s/deployment.yml` to adjust:
- Number of replicas
- Resource limits
- Container configurations

### GitHub Actions CI/CD
The CI/CD pipeline is configured in `.github/workflows/deploy.yml`.

To enable:
1. Create Azure service principal
2. Add `AZURE_CREDENTIALS` secret to GitHub
3. Push code to trigger pipeline

## 🌐 Application Access

After deployment, your application will be accessible via:
- **URL**: `http://<LOAD_BALANCER_IP>`
- **Port**: 80

To get the external IP:
```powershell
kubectl get service govt-prep-service
```

## 🧹 Cleanup

To delete all resources:

```powershell
cd iac
terraform destroy
```

Or manually:
```powershell
az group delete --name govt-prep-rg --yes --no-wait
```

## 📊 Cost Management

**Estimated Monthly Costs:**
- AKS Cluster: ~$70-100/month
- Container Registry: ~$5/month
- LoadBalancer: ~$16/month
- **Total: ~$91-121/month**

**Free Tier Available:**
- Azure Free Account includes $200 credit
- 12 months of free services

## 📸 Documentation Screenshots

Capture screenshots of:
1. Terraform apply output
2. Docker build and push
3. Kubernetes deployment status
4. Service with external IP
5. Application running in browser
6. GitHub Actions workflow (if using CI/CD)

## 🐛 Troubleshooting

### Common Issues

**Issue**: Terraform authentication error
```powershell
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

**Issue**: kubectl connection failed
```powershell
az aks get-credentials --resource-group govt-prep-rg --name govt-prep-aks --overwrite-existing
```

**Issue**: External IP stuck on pending
- Wait 5-10 minutes for LoadBalancer provisioning
- Check AKS cluster networking configuration

**Issue**: Pods not starting
```powershell
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

## 📚 Additional Resources

- [Azure Documentation](https://learn.microsoft.com/en-us/azure/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Ansible Documentation](https://docs.ansible.com/)

## 👥 Project Team

This project was developed as part of DevOps course requirements.

## 📄 License

See [LICENSE.txt](LICENSE.txt) for details.

---

## 🎯 Project Objectives Achieved

✅ Source code version control with Git/GitHub  
✅ Application containerization with Docker  
✅ Infrastructure provisioning with Terraform  
✅ Azure Kubernetes Service deployment  
✅ Configuration management with Ansible  
✅ CI/CD pipeline with GitHub Actions  
✅ Automated deployment and monitoring  

**Total Implementation Time**: 2-4 hours  
**Total Resources**: 5 Azure resources  
**Total Cost**: ~$91-121/month (or $0 with Azure free tier)

---

**Ready to deploy?** Run `.\deploy.ps1` or follow the [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed steps! 🚀

