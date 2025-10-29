# Kubernetes Deployment Guide

This directory contains Kubernetes manifests for deploying the internship-api to Azure Kubernetes Service (AKS).

## Prerequisites

1. **Azure Kubernetes Service (AKS) cluster**
2. **kubectl configured** to connect to your AKS cluster
3. **Container image** available in Azure Container Registry

## Quick Setup

### 1. Create AKS Cluster

```bash
# Create AKS cluster
az aks create \
  --resource-group placement-tracker-rg \
  --name placement-tracker-aks \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --enable-addons monitoring \
  --attach-acr cloudprojectacr

# Get credentials
az aks get-credentials --resource-group placement-tracker-rg --name placement-tracker-aks
```

### 2. Create Secrets

First, create the secrets that the deployment needs:

```bash
kubectl create secret generic app-secrets \
  --namespace=placement-tracker \
  --from-literal=appinsights-key=your-appinsights-key \
  --from-literal=sql-user=your-sql-user \
  --from-literal=sql-password=your-sql-password \
  --from-literal=sql-server=your-sql-server \
  --from-literal=sql-database=your-sql-database \
  --from-literal=jwt-secret=your-jwt-secret
```

### 3. Deploy Application

```bash
# Deploy all manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get all -n placement-tracker

# Check pods
kubectl get pods -n placement-tracker

# Check services
kubectl get services -n placement-tracker

# Check ingress
kubectl get ingress -n placement-tracker
```

## Monitoring

```bash
# View logs
kubectl logs -f deployment/internship-api -n placement-tracker

# Check pod details
kubectl describe pod <pod-name> -n placement-tracker

# Check resource usage
kubectl top pods -n placement-tracker
kubectl top nodes
```

## Scaling

```bash
# Manual scaling
kubectl scale deployment internship-api --replicas=5 -n placement-tracker

# Check HPA status
kubectl get hpa -n placement-tracker
kubectl describe hpa internship-api-hpa -n placement-tracker
```

## Updates

```bash
# Update image
kubectl set image deployment/internship-api api=cloudprojectacr.azurecr.io/internship-api:v2 -n placement-tracker

# Check rollout status
kubectl rollout status deployment/internship-api -n placement-tracker

# Rollback if needed
kubectl rollout undo deployment/internship-api -n placement-tracker
```

## Cost Considerations

- **Control Plane**: FREE (managed by Azure)
- **Worker Nodes**: 2x Standard_B2s ≈ ₹250-400/day
- **Load Balancers**: Additional cost
- **Storage**: Additional cost

**Total estimated cost**: ₹300-500/day (3-4x more than Container Apps)

## Comparison with Current Setup

| Feature | Container Apps | AKS |
|---------|---------------|-----|
| Cost | ₹60-120/day | ₹300-500/day |
| Management | Simple | Complex |
| Scaling | Automatic | Configurable |
| Flexibility | Limited | Full Kubernetes |
| Learning Curve | Low | High |

## Recommendation

For your current single-service application, **Container Apps is recommended** due to:
- Lower cost
- Simpler management
- Adequate for current requirements
- Better fit for serverless workloads

Consider Kubernetes for future projects with:
- Multiple microservices
- Complex orchestration needs
- Advanced deployment strategies
- Team Kubernetes expertise