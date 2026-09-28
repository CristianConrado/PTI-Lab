# Lab3 — Microservices

## Objective

Take the car rental Express API from [Lab1](../Lab1) and deploy it as a containerized
microservice on Kubernetes, exploring deployments, services, ingress routing, and
horizontal autoscaling.

Contents of `src/`:

- `server.js` — the car rental REST API (JWT auth, `/login`, `/users`, `/rentals`, `/newrental`).
- `server2.js` — a minimal "Hello World" HTTP server used for early container/K8s tests.
- `Dockerfile` — builds the `car_rental` image used by the deployment manifests.
- `carrentaldeployment.yaml` — Deployment manifest (2 replicas, CPU requests/limits).
- `carrentaldeployment2.yaml` — a snapshot of the live Deployment state (`kubectl get deployment -o yaml`), kept for reference.
- `carrentalservice.yaml` — ClusterIP Service exposing the app on port 8080.
- `carrentalingress.yaml` — Ingress routing `carrental.local` to the service.
- `carrental-hpa.yaml` — HorizontalPodAutoscaler (1-5 replicas, target 50% CPU).
- `helloworld.tar` — exported image used for the initial "Hello World" deployment exercise.

## How to run

### Build the image

```bash
cd src
docker build -t car_rental:1.0 .
```

If using a local cluster (e.g. Minikube, Kind, Docker Desktop), make sure the image is
available to the cluster's runtime (e.g. `minikube image load car_rental:1.0`).

### Deploy to Kubernetes

```bash
kubectl apply -f carrentaldeployment.yaml
kubectl apply -f carrentalservice.yaml
kubectl apply -f carrentalingress.yaml
kubectl apply -f carrental-hpa.yaml
```

### Verify

```bash
kubectl get deployments,pods,svc,ingress,hpa -l app=carrental
```

If your ingress controller is set up, add `carrental.local` to your hosts file
pointing at the ingress IP, then browse to `http://carrental.local/`.
Otherwise, port-forward the service directly:

```bash
kubectl port-forward svc/carrental 8080:8080
```

### Load-test the autoscaler (optional)

Generate CPU load against the service and watch the HPA scale the deployment:

```bash
kubectl get hpa carrental --watch
```
