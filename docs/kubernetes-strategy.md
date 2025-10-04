# Kubernetes Strategy for Placement Tracker

## Why Kubernetes?
- **Scalability**: As more students/staff use the application, Kubernetes can scale pods automatically.
- **Resilience**: If one pod fails, Kubernetes reschedules it automatically.
- **Environment Promotion**: Separate namespaces can be used for Dev, QA, and Prod.

## Implementation Plan
1. **Dockerize Application** (already done with Dockerfile).
2. **Push Docker Image** to Azure Container Registry (ACR).
3. **Create AKS Cluster** (managed Kubernetes in Azure).
4. **Deploy Pods** using a simple `deployment.yaml` and `service.yaml`.
5. **Promote** changes from Dev → QA → Prod by applying different manifests to different namespaces.

