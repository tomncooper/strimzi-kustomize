# Strimzi Kustomize Examples

This repository contains Kustomize configurations for deploying the Strimzi Kafka Operator.

## Deployment Modes

This repository provides two deployment configurations:

- **all-namespaces**: Operator watches all namespaces for Kafka resources
- **single-namespace**: Operator watches only the namespace it's deployed in

In both configurations, the operator is deployed in the `strimzi` namespace. 
If you wish to deploy it in a different namespace, adjust the `namespace` field in the respective Kustomize overlays and the RoleBindings and ClusterRoleBindings overrides in the base kustomization.yaml.

## Installation

### Prerequisites

- kubectl installed and configured
- kustomize installed (or use `kubectl` with built-in kustomize support)

### Deploy All-Namespaces Mode

This configuration allows the operator to manage Kafka clusters in any namespace.

```bash
kubectl apply -k cluster-operator/all-namespaces/
```

Or using kustomize directly:

```bash
kustomize build cluster-operator/all-namespaces/ | kubectl apply -f -
```

### Deploy Single-Namespace Mode

This configuration restricts the operator to only manage Kafka clusters in the `strimzi` namespace.

```bash
kubectl apply -k cluster-operator/single-namespace/
```

Or using kustomize directly:

```bash
kustomize build cluster-operator/single-namespace/ | kubectl apply -f -
```

### Verify

Check that the operator is running:

```bash
kubectl get deployment -n strimzi strimzi-cluster-operator
kubectl get pods -n strimzi
```

## Deploying Kafka Clusters

### Single-Node Kafka Cluster

Deploy a simple single-node Kafka cluster for testing:

```bash
kubectl apply -k kafka/single-node/
```

Or using kustomize directly:

```bash
kustomize build kafka/single-node/ | kubectl apply -f -
```

This will create a Kafka cluster named `test-cluster` in the `kafka` namespace.
You can modify the `kafka/single-node/kustomization.yaml` to change the cluster name or namespace as needed.

Verify the deployment:

```bash
kubectl get kafka -n kafka
kubectl get kafkanodepool -n kafka
kubectl get pods -n kafka
```
