# Strimzi Kustomize Examples

This repository contains Kustomize configurations for deploying the Strimzi Kafka Operator, Kafka Clusters, Apicurio Registry and other event streaming infrastructure components on Kubernetes.

## Table of Contents

- [Deployment Modes](#deployment-modes)
- [Prerequisites](#prerequisites)
- [Strimzi Operator Installation](#strimzi-operator-installation)
  - [Deploy All-Namespaces Mode](#deploy-all-namespaces-mode)
  - [Deploy Single-Namespace Mode](#deploy-single-namespace-mode)
  - [Verify the Strimzi Operator Deployment](#verify-the-strimzi-operator-deployment)
- [Deploying Kafka Clusters](#deploying-kafka-clusters)
  - [Single-Node Kafka Cluster](#single-node-kafka-cluster)
- [Apicurio Registry](#apicurio-registry)
  - [Operator Installation](#operator-installation)
  - [Deploying a Registry Instance](#deploying-a-registry-instance)
    - [In-Memory Storage](#in-memory-storage)
    - [KafkaSQL Storage](#kafkasql-storage)
    - [Verify the Registry Instance](#verify-the-registry-instance)
- [Updating Versions](#updating-versions)

## Deployment Modes

This repository provides two deployment configurations for each operator:

- **all-namespaces**: Operator watches all namespaces for resources
- **single-namespace**: Operator watches only the namespace it's deployed in

The Strimzi operator is deployed in the `strimzi` namespace and the Apicurio Registry operator in the `apicurio-registry` namespace.
If you wish to deploy in different namespaces, adjust the `namespace` field in the respective Kustomize overlays and the ClusterRoleBinding overrides in the base kustomization.yaml.

## Prerequisites

- kubectl installed and configured
- kustomize installed (or use `kubectl` with built-in kustomize support)

## Strimzi Operator Installation

### Deploy All-Namespaces Mode

#### Using the remote repository

You can apply the configuration directly from the GitHub repository:

```bash
kubectl apply -k 'https://github.com/tomncooper/strimzi-kustomize//cluster-operator/all-namespaces?ref=main'
```

#### Using the local repository

This configuration allows the operator to manage Kafka clusters in any namespace.

```bash
kubectl apply -k cluster-operator/all-namespaces/
```

Or using kustomize directly:

```bash
kustomize build cluster-operator/all-namespaces/ | kubectl apply -f -
```

### Deploy Single-Namespace Mode

#### Using the remote repository

You can apply the configuration directly from the GitHub repository:

```bash
kubectl apply -k 'https://github.com/tomncooper/strimzi-kustomize//cluster-operator/single-namespace?ref=main'
```

#### Using the local repository

This configuration restricts the operator to only manage Kafka clusters in the `strimzi` namespace.

```bash
kubectl apply -k cluster-operator/single-namespace/
```

Or using kustomize directly:

```bash
kustomize build cluster-operator/single-namespace/ | kubectl apply -f -
```

### Verify the Strimzi Operator Deployment

Check that the operator is running:

```bash
kubectl get deployment -n strimzi strimzi-cluster-operator
kubectl get pods -n strimzi
```

## Deploying Kafka Clusters

### Single-Node Kafka Cluster

#### Using the remote repository

You can apply the configuration directly from the GitHub repository:

```bash
kubectl apply -k 'https://github.com/tomncooper/strimzi-kustomize//kafka/single-node?ref=main'
```

#### Using the local repository

Deploy a simple single-node Kafka cluster for testing:

```bash
kubectl apply -k kafka/single-node/
```

Or using kustomize directly:

```bash
kustomize build kafka/single-node/ | kubectl apply -f -
```

#### Verify the Kafka Cluster

The above commands will create a Kafka cluster named `test-cluster` in the `kafka` namespace.
You can modify the `kafka/single-node/kustomization.yaml` to change the cluster name or namespace as needed.

Verify the deployment:

```bash
kubectl get kafka -n kafka
kubectl get kafkanodepool -n kafka
kubectl get pods -n kafka
```

## Apicurio Registry

[Apicurio Registry](https://www.apicur.io/registry/) is a schema/API registry that can use Kafka as a storage backend via the KafkaSQL storage type.

### Operator Installation

#### Deploy All-Namespaces Mode

##### Using the remote repository

```bash
kubectl apply -k 'https://github.com/tomncooper/strimzi-kustomize//apicurio-registry/operator/all-namespaces?ref=main'
```

##### Using the local repository

This configuration allows the operator to manage Apicurio Registry instances in any namespace.

```bash
kubectl apply -k apicurio-registry/operator/all-namespaces/
```

Or using kustomize directly:

```bash
kustomize build apicurio-registry/operator/all-namespaces/ | kubectl apply -f -
```

#### Deploy Single-Namespace Mode

##### Using the remote repository

```bash
kubectl apply -k 'https://github.com/tomncooper/strimzi-kustomize//apicurio-registry/operator/single-namespace?ref=main'
```

##### Using the local repository

This configuration restricts the operator to only manage registry instances in the `apicurio-registry` namespace.

```bash
kubectl apply -k apicurio-registry/operator/single-namespace/
```

Or using kustomize directly:

```bash
kustomize build apicurio-registry/operator/single-namespace/ | kubectl apply -f -
```

#### Verify the Apicurio Registry Operator

Check that the operator is running:

```bash
kubectl get deployment -n apicurio-registry apicurio-registry-operator
kubectl get pods -n apicurio-registry
```

### Deploying a Registry Instance

#### In-Memory Storage

This deploys an Apicurio Registry instance using in-memory storage. This is useful for quick testing and does not require a Kafka cluster. **Not suitable for production use** as data will be lost when the pod is restarted.

##### Using the remote repository

```bash
kubectl apply -k 'https://github.com/tomncooper/strimzi-kustomize//apicurio-registry/registry/in-memory?ref=main'
```

##### Using the local repository

```bash
kubectl apply -k apicurio-registry/registry/in-memory/
```

Or using kustomize directly:

```bash
kustomize build apicurio-registry/registry/in-memory/ | kubectl apply -f -
```

#### KafkaSQL Storage

This deploys an Apicurio Registry instance using KafkaSQL storage, connecting to the `test-cluster` Kafka cluster deployed via the `kafka/single-node/` configuration.

##### Using the remote repository

```bash
kubectl apply -k 'https://github.com/tomncooper/strimzi-kustomize//apicurio-registry/registry/kafkasql?ref=main'
```

##### Using the local repository

```bash
kubectl apply -k apicurio-registry/registry/kafkasql/
```

Or using kustomize directly:

```bash
kustomize build apicurio-registry/registry/kafkasql/ | kubectl apply -f -
```

#### Verify the Registry Instance

```bash
kubectl get apicurioregistry3 -n apicurio-registry
kubectl get pods -n apicurio-registry
```

To access the registry UI, use port-forwarding:

```bash
kubectl port-forward -n apicurio-registry svc/apicurio-registry-app-service 8080:8080
```

Then open http://localhost:8080 in your browser.

## Updating Versions

To update the version of a component, use the update script:

```bash
# Strimzi
./update-version.sh strimzi <new-version>

# Apicurio Registry
./update-version.sh apicurio-registry <new-version>
```

List available versions:

```bash
./update-version.sh --list strimzi
./update-version.sh --list apicurio-registry
```

See `./update-version.sh --help` for more options, such as performing a dry-run or checking if a release exists.
