# DevOps Deployment Guide - Govt Prep Web Application

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Phase 1: Azure Account Setup and Authentication](#phase-1-azure-account-setup)
3. [Phase 2: Infrastructure Provisioning with Terraform](#phase-2-infrastructure-provisioning)
4. [Phase 3: Container Registry Setup](#phase-3-container-registry-setup)
5. [Phase 4: Build and Push Docker Image](#phase-4-build-and-push-docker-image)
6. [Phase 5: Configure Kubernetes Access](#phase-5-configure-kubernetes-access)
7. [Phase 6: Deploy to AKS using Ansible](#phase-6-deploy-to-aks)
8. [Phase 7: CI/CD Pipeline Setup with GitHub Actions](#phase-7-cicd-pipeline-setup)
9. [Phase 8: Verification and Access](#phase-8-verification)
10. [Phase 9: Cleanup](#phase-9-cleanup)

---

## Prerequisites

### Required Software
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Terraform](https://www.terraform.io/downloads.html)
- [Docker](https://www.docker.com/products/docker-desktop)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html)
- [Git](https://git-scm.com/downloads)

### Required Accounts
- Azure account with active subscription
- GitHub account

---

## Phase 1: Azure Account Setup and Authentication

### Step 1.1: Install Azure CLI
```powershell
# Download and install Azure CLI from:
# https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows
```

### Step 1.2: Login to Azure
```powershell
az login
```

### Step 1.3: Verify your subscription
```powershell
az account list --output table
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### Step 1.4: Verify Azure CLI installation
```powershell
az --version
terraform --version
kubectl version --client
docker --version
```

---

## Phase 2: Infrastructure Provisioning with Terraform

### Step 2.1: Navigate to Terraform directory
```powershell
cd iac
```

### Step 2.2: Initialize Terraform
```powershell
terraform init
```

**Expected Output:**
```
Initializing the backend...
Initializing provider plugins...
- Reusing previous version of hashicorp/azurerm from the dependency lock file
Terraform has been successfully initialized!
```

### Step 2.3: Validate Terraform configuration
```powershell
terraform validate
```

### Step 2.4: Plan the infrastructure
```powershell
terraform plan
```

**Expected Output:** Shows the resources that will be created:
- Resource Group
- Azure Container Registry (ACR)
- Azure Kubernetes Service (AKS)

### Step 2.5: Apply Terraform configuration
```powershell
terraform apply
```

**Note:** Type `yes` when prompted to confirm the deployment.

**Expected Output:**
```
azurerm_resource_group.govt_prep_rg: Creating...
azurerm_resource_group.govt_prep_rg: Creation complete after 1s
azurerm_container_registry.acr: Creating...
azurerm_container_registry.acr: Creation complete after 60s
azurerm_kubernetes_cluster.aks: Creating...
azurerm_kubernetes_cluster.aks: Still creating... [10m elapsed]
azurerm_kubernetes_cluster.aks: Creation complete after 15m

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

### Step 2.6: View Terraform outputs
```powershell
terraform output
```

**Expected Output:**
```
resource_group_name = "govt-prep-rg"
aks_cluster_name = "govt-prep-aks"
acr_name = "govtprepregistry"
acr_login_server = "govtprepregistry.azurecr.io"
```

### Step 2.7: Take a screenshot of the outputs
Capture the Terraform output for your documentation.

---

## Phase 3: Container Registry Setup

### Step 3.1: Login to Azure Container Registry
```powershell
az acr login --name govtprepregistry
```

**Expected Output:** `Login Succeeded`

### Step 3.2: Enable admin user for ACR (if needed)
```powershell
az acr update -n govtprepregistry --admin-enabled true
```

### Step 3.3: Get ACR credentials
```powershell
az acr credential show --name govtprepregistry
```

**Take a screenshot** of this output for documentation.

---

## Phase 4: Build and Push Docker Image

### Step 4.1: Navigate to project root
```powershell
cd ..
```

### Step 4.2: Build Docker image
```powershell
docker build -t govtprepregistry.azurecr.io/govt-prep-app:latest .
```

### Step 4.3: Tag the image (optional)
```powershell
docker tag govtprepregistry.azurecr.io/govt-prep-app:latest govtprepregistry.azurecr.io/govt-prep-app:v1.0
```

### Step 4.4: Push image to Azure Container Registry
```powershell
docker push govtprepregistry.azurecr.io/govt-prep-app:latest
```

**Expected Output:**
```
The push refers to repository [govtprepregistry.azurecr.io/govt-prep-app]
latest: digest: sha256:... size: 1234
```

### Step 4.5: Verify image in ACR
```powershell
az acr repository list --name govtprepregistry --output table
```

**Take a screenshot** of this for documentation.

---

## Phase 5: Configure Kubernetes Access

### Step 5.1: Install kubectl (if not installed)
```powershell
az aks install-cli
```

### Step 5.2: Get AKS credentials
```powershell
az aks get-credentials --resource-group govt-prep-rg --name govt-prep-aks
```

**Expected Output:**
```
Merged "govt-prep-aks" as current context in C:\Users\...\.kube\config
```

### Step 5.3: Verify kubectl connection
```powershell
kubectl get nodes
```

**Expected Output:**
```
NAME                                STATUS   ROLES   AGE   VERSION
aks-default-12345678-vmss000000     Ready    agent   5m    v1.28.5
aks-default-12345678-vmss000001     Ready    agent   5m    v1.28.5
```

**Take a screenshot** of this for documentation.

---

## Phase 6: Deploy to AKS using Ansible

### Step 6.1: Install Ansible (if not installed)
```powershell
pip install ansible
```

### Step 6.2: Navigate to ansible directory
```powershell
cd ansible
```

### Step 6.3: Update the deployment file with ACR name
```powershell
# First, get your ACR login server
az acr show --name govtprepregistry --query loginServer --output tsv

# Edit iac/k8s/deployment.yml and replace 'acr_name' with your ACR server name
# Example: govtprepregistry.azurecr.io
```

### Step 6.4: Run Ansible Playbook
```powershell
ansible-playbook playbook.yml -e "acr_login_server=govtprepregistry.azurecr.io"
```

**Alternative: Deploy using kubectl directly**
```powershell
# Navigate back to root
cd ..

# Apply Kubernetes manifests
kubectl apply -f iac/k8s/deployment.yml
kubectl apply -f iac/k8s/service.yml

# Watch the deployment
kubectl get pods -w
```

**Expected Output:**
```
deployment.apps/govt-prep-deploy created
service/govt-prep-service created
```

### Step 6.5: Check deployment status
```powershell
kubectl get deployment govt-prep-deploy
kubectl get pods -l app=govt-prep
kubectl get service govt-prep-service
```

**Take screenshots** of all these commands' outputs.

---

## Phase 7: CI/CD Pipeline Setup with GitHub Actions

### Step 7.1: Create Azure Service Principal for GitHub Actions
```powershell
az ad sp create-for-rbac --name "github-actions-govt-prep" --role contributor --scopes /subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/govt-prep-rg --sdk-auth
```

**Copy the JSON output** - this will be used as a GitHub Secret.

### Step 7.2: Enable ACR Authentication
```powershell
az role assignment create --assignee <SP_CLIENT_ID> --role AcrPush --scope /subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/govt-prep-rg/providers/Microsoft.ContainerRegistry/registries/govtprepregistry
```

### Step 7.3: Add GitHub Secrets
1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secrets:
   - Name: `AZURE_CREDENTIALS`
   - Value: Paste the JSON output from Step 7.1

### Step 7.4: Push code to GitHub
```powershell
git add .
git commit -m "Setup DevOps pipeline with CI/CD"
git push origin main
```

### Step 7.5: Verify GitHub Actions
1. Go to your GitHub repository
2. Click on **Actions** tab
3. You should see the workflow running
4. Wait for the deployment to complete

**Take screenshots** of:
- GitHub Actions workflow running
- Deployment steps in progress
- Successful deployment status

---

## Phase 8: Verification and Access

### Step 8.1: Check pods status
```powershell
kubectl get pods -l app=govt-prep
```

**Expected Output:**
```
NAME                                 READY   STATUS    RESTARTS   AGE
govt-prep-deploy-1234567890-abcde    1/1     Running   0          2m
govt-prep-deploy-1234567890-xyzab    1/1     Running   0          2m
```

### Step 8.2: Get LoadBalancer external IP
```powershell
kubectl get service govt-prep-service
```

**Expected Output:**
```
NAME                 TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)        AGE
govt-prep-service    LoadBalancer   10.0.0.123    <pending...>    80:30008/TCP   5m
```

**Note:** Wait until `<pending>` changes to an actual IP address (may take 5-10 minutes)

### Step 8.3: Access the application
```powershell
kubectl get service govt-prep-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Open your browser and navigate to: `http://EXTERNAL_IP`

### Step 8.4: Verify application functionality
Test the following:
- Home page loads correctly
- Navigation links work
- Images display properly
- All pages are accessible

**Take screenshots** of:
- Browser showing the application
- Service status with external IP
- Pod status

---

## Phase 9: Cleanup

### Option 1: Delete using Terraform (Recommended)
```powershell
cd iac
terraform destroy
```

Type `yes` when prompted. This will delete:
- AKS cluster
- Container Registry
- Resource Group and all resources

### Option 2: Manual cleanup via Azure CLI
```powershell
# Delete the resource group (this deletes everything in it)
az group delete --name govt-prep-rg --yes --no-wait
```

---

## Troubleshooting

### Issue: Terraform fails with authentication error
**Solution:**
```powershell
az login --tenant YOUR_TENANT_ID
az account set --subscription YOUR_SUBSCRIPTION_ID
```

### Issue: kubectl connection fails
**Solution:**
```powershell
az aks get-credentials --resource-group govt-prep-rg --name govt-prep-aks --overwrite-existing
```

### Issue: Docker push fails
**Solution:**
```powershell
az acr login --name govtprepregistry
docker push govtprepregistry.azurecr.io/govt-prep-app:latest
```

### Issue: Pods not starting
**Solution:**
```powershell
# Check pod logs
kubectl logs <pod-name>

# Describe pod
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Issue: External IP stuck in pending
**Solution:**
- Check that LoadBalancer service is correctly configured
- Verify AKS cluster has proper networking setup
- Wait 5-10 minutes for Azure to provision the load balancer

---

## Documentation Checklist

Ensure you have screenshots and documentation for:
- [ ] Terraform initialization and apply
- [ ] Resource group, ACR, and AKS creation
- [ ] Docker build and push process
- [ ] ACR with images listed
- [ ] kubectl connecting to AKS
- [ ] Kubernetes nodes status
- [ ] Pods running successfully
- [ ] Service with external IP
- [ ] Application running in browser
- [ ] GitHub Actions workflow execution
- [ ] Ansible playbook execution (if used)

---

## Project Structure

```
GOVT-PREP-WEB-APP/
├── .github/
│   └── workflows/
│       └── deploy.yml              # GitHub Actions CI/CD pipeline
├── .dockerignore                   # Files to ignore in Docker build
├── ansible/
│   └── playbook.yml                # Ansible deployment automation
├── Dockerfile                       # Docker image configuration
├── iac/
│   ├── k8s/
│   │   ├── deployment.yml          # Kubernetes deployment manifest
│   │   └── service.yml             # Kubernetes service manifest
│   ├── main.tf                      # Terraform infrastructure config
│   ├── variables.tf                 # Terraform variables
│   └── outputs.tf                   # Terraform outputs
├── index.html                       # Application entry point
├── contact.html
├── courses.html
├── login.html
├── register.html
└── DEPLOYMENT_GUIDE.md             # This guide
```

---

## Cost Management

**Estimated Monthly Costs:**
- AKS Cluster (Standard_B2s, 2 nodes): ~$70-100/month
- Azure Container Registry (Basic): ~$5/month
- LoadBalancer: ~$16/month
- **Total: ~$91-121/month**

**To minimize costs:**
```powershell
# Delete resources after testing
terraform destroy
```

---

## Additional Resources

- [Azure CLI Documentation](https://learn.microsoft.com/en-us/cli/azure/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Ansible Documentation](https://docs.ansible.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

## Summary

This project demonstrates a complete DevOps pipeline:
1. ✅ **Source Control**: Git/GitHub
2. ✅ **Containerization**: Docker
3. ✅ **Infrastructure as Code**: Terraform
4. ✅ **Cloud Infrastructure**: Azure (AKS, ACR)
5. ✅ **Configuration Management**: Ansible
6. ✅ **CI/CD**: GitHub Actions
7. ✅ **Container Orchestration**: Kubernetes (AKS)

**Project Duration**: Estimated 2-4 hours for complete deployment

Good luck with your project! 🚀

