# PowerShell Deployment Script for Govt Prep Web Application
# This script automates the deployment process to Azure

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Govt Prep - Automated Deployment" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if user is logged in to Azure
Write-Host "[1/9] Checking Azure authentication..." -ForegroundColor Yellow
$azAccount = az account show 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Please login to Azure..." -ForegroundColor Red
    az login
}

Write-Host "[1/9] ✓ Azure authentication successful" -ForegroundColor Green
Write-Host ""

# Phase 2: Infrastructure Provisioning
Write-Host "[2/9] Provisioning infrastructure with Terraform..." -ForegroundColor Yellow
Set-Location iac

Write-Host "  - Initializing Terraform..." -ForegroundColor Cyan
terraform init

Write-Host "  - Planning infrastructure..." -ForegroundColor Cyan
terraform plan

Write-Host "  - Applying infrastructure..." -ForegroundColor Cyan
terraform apply -auto-approve

if ($LASTEXITCODE -eq 0) {
    Write-Host "[2/9] ✓ Infrastructure provisioned successfully" -ForegroundColor Green
} else {
    Write-Host "[2/9] ✗ Infrastructure provisioning failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

Set-Location ..

# Get ACR details
$ACR_NAME = terraform output -raw acr_name 2>$null
if (-not $ACR_NAME) {
    $ACR_NAME = "govtprepregistry"
}
$ACR_LOGIN_SERVER = "$ACR_NAME.azurecr.io"

# Phase 3: Container Registry Setup
Write-Host "[3/9] Setting up Azure Container Registry..." -ForegroundColor Yellow
az acr login --name $ACR_NAME
az acr update -n $ACR_NAME --admin-enabled true

Write-Host "[3/9] ✓ Container Registry ready" -ForegroundColor Green
Write-Host ""

# Phase 4: Build and Push Docker Image
Write-Host "[4/9] Building and pushing Docker image..." -ForegroundColor Yellow

Write-Host "  - Building Docker image..." -ForegroundColor Cyan
docker build -t $ACR_LOGIN_SERVER/govt-prep-app:latest .

if ($LASTEXITCODE -eq 0) {
    Write-Host "  - Pushing to Azure Container Registry..." -ForegroundColor Cyan
    docker push $ACR_LOGIN_SERVER/govt-prep-app:latest
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[4/9] ✓ Docker image pushed successfully" -ForegroundColor Green
    } else {
        Write-Host "[4/9] ✗ Failed to push Docker image" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[4/9] ✗ Failed to build Docker image" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Phase 5: Configure Kubernetes Access
Write-Host "[5/9] Configuring Kubernetes access..." -ForegroundColor Yellow
$RESOURCE_GROUP = terraform output -raw resource_group_name 2>$null
$CLUSTER_NAME = terraform output -raw aks_cluster_name 2>$null

if (-not $RESOURCE_GROUP) {
    $RESOURCE_GROUP = "govt-prep-rg"
}
if (-not $CLUSTER_NAME) {
    $CLUSTER_NAME = "govt-prep-aks"
}

az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# Verify connection
kubectl get nodes > $null 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "[5/9] ✓ Kubernetes access configured" -ForegroundColor Green
} else {
    Write-Host "[5/9] ✗ Failed to configure Kubernetes access" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Phase 6: Deploy to Kubernetes
Write-Host "[6/9] Deploying to Kubernetes..." -ForegroundColor Yellow

Write-Host "  - Updating deployment manifest with ACR..." -ForegroundColor Cyan
(Get-Content "iac\k8s\deployment.yml") -replace 'acr_name.azurecr.io', $ACR_LOGIN_SERVER | Set-Content "iac\k8s\deployment.yml"

Write-Host "  - Applying deployment..." -ForegroundColor Cyan
kubectl apply -f iac/k8s/deployment.yml

Write-Host "  - Applying service..." -ForegroundColor Cyan
kubectl apply -f iac/k8s/service.yml

Write-Host "[6/9] ✓ Deployment applied" -ForegroundColor Green
Write-Host ""

# Phase 7: Wait for deployment
Write-Host "[7/9] Waiting for deployment to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

$retryCount = 0
$maxRetries = 30

while ($retryCount -lt $maxRetries) {
    $pods = kubectl get pods -l app=govt-prep --no-headers 2>$null
    if ($LASTEXITCODE -eq 0 -and $pods -match "Running") {
        Write-Host "[7/9] ✓ All pods are running" -ForegroundColor Green
        break
    }
    Write-Host "  - Waiting for pods... ($retryCount/$maxRetries)" -ForegroundColor Cyan
    Start-Sleep -Seconds 10
    $retryCount++
}

if ($retryCount -eq $maxRetries) {
    Write-Host "[7/9] ⚠ Deployment taking longer than expected" -ForegroundColor Yellow
}
Write-Host ""

# Phase 8: Verification
Write-Host "[8/9] Verifying deployment..." -ForegroundColor Yellow

Write-Host "  - Getting pods status..." -ForegroundColor Cyan
kubectl get pods -l app=govt-prep

Write-Host "  - Getting service details..." -ForegroundColor Cyan
kubectl get service govt-prep-service

Write-Host ""
Write-Host "[8/9] ✓ Verification complete" -ForegroundColor Green
Write-Host ""

# Phase 9: Display access information
Write-Host "[9/9] Deployment Summary" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Application deployed successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "Resource Details:" -ForegroundColor Cyan
Write-Host "  Resource Group: $RESOURCE_GROUP"
Write-Host "  AKS Cluster: $CLUSTER_NAME"
Write-Host "  ACR Name: $ACR_NAME"
Write-Host ""

# Get external IP
Write-Host "Getting LoadBalancer IP (this may take a few minutes)..." -ForegroundColor Yellow
$EXTERNAL_IP = kubectl get service govt-prep-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null

if ($EXTERNAL_IP) {
    Write-Host "  Access your application at: http://$EXTERNAL_IP" -ForegroundColor Green
} else {
    Write-Host "  External IP is still being provisioned..." -ForegroundColor Yellow
    Write-Host "  Run this command to check: kubectl get service govt-prep-service" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Cyan
Write-Host "  View pods: kubectl get pods -l app=govt-prep"
Write-Host "  View service: kubectl get service govt-prep-service"
Write-Host "  View logs: kubectl logs -l app=govt-prep"
Write-Host "  Check status: kubectl get all"
Write-Host ""
Write-Host "To destroy resources, run: cd iac && terraform destroy" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Cyan

