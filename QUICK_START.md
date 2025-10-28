# Quick Start Guide - Govt Prep Deployment

## ⚡ Fast Track Deployment (10 minutes)

### 1. Prerequisites Check
```powershell
# Check if all tools are installed
az --version
terraform --version
docker --version
kubectl version --client
```

### 2. Login to Azure
```powershell
az login
```

### 3. Run Automated Deployment
```powershell
.\deploy.ps1
```

### 4. Wait for Application URL
The script will display the external IP once deployment completes.

### 5. Access Application
Open browser to `http://EXTERNAL_IP`

---

## 📝 Manual Step-by-Step (30 minutes)

### Step 1: Login to Azure
```powershell
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### Step 2: Provision Infrastructure
```powershell
cd iac
terraform init
terraform apply  # Type 'yes' when prompted
cd ..
```

### Step 3: Push Docker Image
```powershell
az acr login --name govtprepregistry
docker build -t govtprepregistry.azurecr.io/govt-prep-app:latest .
docker push govtprepregistry.azurecr.io/govt-prep-app:latest
```

### Step 4: Deploy to Kubernetes
```powershell
az aks get-credentials --resource-group govt-prep-rg --name govt-prep-aks
# Update deployment.yml with ACR name
kubectl apply -f iac/k8s/deployment.yml
kubectl apply -f iac/k8s/service.yml
```

### Step 5: Get Application URL
```powershell
# Wait 5 minutes for external IP
kubectl get service govt-prep-service -w
```

---

## 🔑 Key Commands Reference

| Task | Command |
|------|---------|
| Check Azure login | `az account show` |
| List resource groups | `az group list` |
| View Terraform plan | `cd iac && terraform plan` |
| Apply infrastructure | `cd iac && terraform apply` |
| Build Docker image | `docker build -t IMAGE_NAME .` |
| Push to ACR | `docker push IMAGE_NAME` |
| Configure kubectl | `az aks get-credentials -g RESOURCE_GROUP -n CLUSTER_NAME` |
| Deploy to K8s | `kubectl apply -f iac/k8s/deployment.yml` |
| Check pods | `kubectl get pods -l app=govt-prep` |
| Check service | `kubectl get service govt-prep-service` |
| View logs | `kubectl logs -l app=govt-prep` |
| Delete resources | `cd iac && terraform destroy` |

---

## 🆘 Quick Troubleshooting

### Cannot login to Azure
```powershell
az logout
az login
```

### Terraform stuck
```powershell
# Cancel and retry
terraform apply
```

### Docker build fails
```powershell
# Check Dockerfile
cat Dockerfile
```

### Pods not running
```powershell
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### No external IP
```powershell
# Wait 10 minutes and check again
kubectl get service govt-prep-service -w
```

---

## 📊 Deployment Status Check

```powershell
# All-in-one status check
Write-Host "=== Deployment Status ===" -ForegroundColor Cyan
az group list -o table
kubectl get nodes
kubectl get pods -l app=govt-prep
kubectl get service govt-prep-service
```

---

## 🧹 Cleanup

```powershell
cd iac
terraform destroy  # Type 'yes'
```

---

**Need more details?** See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

