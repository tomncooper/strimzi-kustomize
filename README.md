# Strimzi Kustomize Examples

This repository contains Kustomize configurations for deploying the Strimzi Kafka Operator, Kafka Clusters, Apicurio Registry and other event streaming infrastructure components on Kubernetes.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Dev Environment (Full Development Stack)](#dev-environment-full-development-stack)
- [Strimzi Operator Installation](#strimzi-operator-installation)
  - [Deploy All-Namespaces Mode](#deploy-all-namespaces-mode)
  - [Deploy Single-Namespace Mode](#deploy-single-namespace-mode)
- [Deploying Kafka Clusters](#deploying-kafka-clusters)
  - [Single-Node Kafka Cluster](#single-node-kafka-cluster)
- [Apicurio Registry](#apicurio-registry)
  - [Operator Installation](#operator-installation)
  - [Deploying a Registry Instance](#deploying-a-registry-instance)
    - [In-Memory Storage](#in-memory-storage)
    - [KafkaSQL Storage](#kafkasql-storage)
- [StreamsHub Console](#streamshub-console)
  - [Operator Installation](#streamshub-console-operator-installation)
  - [Deploying a Console Instance](#deploying-a-console-instance)
  - [Accessing the Console](#accessing-the-console)
- [Updating Versions](#updating-versions)

## Prerequisites

- kubectl installed and configured
- kustomize installed (or use `kubectl` with built-in kustomize support)

## Dev Environment (Full Development Stack)

The `dev/` directory contains Kustomize configurations for deploying the complete development environment, including:

- **Strimzi operator** (all-namespaces mode) in the `strimzi` namespace
- **Single-node Kafka cluster** (`test-cluster`) in the `kafka` namespace
- **Apicurio Registry operator** (single-namespace mode) in the `apicurio-registry` namespace
- **Apicurio Registry instance** (in-memory storage) in the `apicurio-registry` namespace
- **StreamsHub Console operator** in the `streamshub-console` namespace
- **StreamsHub Console instance** connected to `test-cluster` in the `streamshub-console` namespace

The configuration is split into two layers:

- **`dev/base/`** — Installs only the operators (Strimzi, Apicurio Registry and StreamsHub Console)
- **`dev/stack/`** — Includes the base operators plus the operands (Kafka cluster, Apicurio Registry and StreamsHub Console instance)

### Quick install

Run the full two-step deployment with a single command:

```bash
curl -sL https://raw.githubusercontent.com/tomncooper/strimzi-kustomize/main/dev/install.sh | bash
```

### Manual Two-step deployment

Operator CRDs must be registered before their custom resources (KafkaNodePool, Kafka, ApicurioRegistry3, Console etc.) can be created. 
The two-step approach installs operators first, waits for them to be ready, then deploys the operands.

#### Using the remote repository

```bash
# Step 1: Install operators
kubectl apply -k 'https://github.com/tomncooper/strimzi-kustomize//dev/base?ref=main'

# (Optional) Step 2: Wait for operators to be ready
kubectl wait --for=condition=Available deployment/strimzi-cluster-operator -n strimzi --timeout=120s
kubectl wait --for=condition=Available deployment/apicurio-registry-operator -n apicurio-registry --timeout=120s
kubectl wait --for=condition=Available deployment/streamshub-console-operator -n streamshub-console --timeout=120s

# Step 3: Install operands
kubectl apply -k 'https://github.com/tomncooper/strimzi-kustomize//dev/stack?ref=main'
```

#### Using the local repository

If you checkout the repository, you can use the local files:

```bash
# Step 1: Install operators
kubectl apply -k dev/base/

# (Optional) Step 2: Wait for operators to be ready
kubectl wait --for=condition=Available deployment/strimzi-cluster-operator -n strimzi --timeout=120s
kubectl wait --for=condition=Available deployment/apicurio-registry-operator -n apicurio-registry --timeout=120s
kubectl wait --for=condition=Available deployment/streamshub-console-operator -n streamshub-console --timeout=120s

# Step 3: Install operands
kubectl apply -k dev/stack/
```

## Strimzi Operator Installation

### Deploy All-Namespaces Mode

This configuration allows the operator to manage Kafka clusters in any namespace.

#### Using the remote repository

You can apply the configuration directly from the GitHub repository:

```bash
kubectl apply -k 'https://github.com/tomncooper/strimzi-kustomize//cluster-operator/all-namespaces?ref=main'
```

#### Using the local repository

```bash
kubectl apply -k cluster-operator/all-namespaces/
```

### Deploy Single-Namespace Mode

This configuration restricts the operator to only manage Kafka clusters in the `strimzi` namespace.

#### Using the remote repository

You can apply the configuration directly from the GitHub repository:

```bash
kubectl apply -k 'https://github.com/tomncooper/strimzi-kustomize//cluster-operator/single-namespace?ref=main'
```

#### Using the local repository

```bash
kubectl apply -k cluster-operator/single-namespace/
```

## Deploying Kafka Clusters

### Single-Node Kafka Cluster

Deploy a simple single-node Kafka cluster for testing:

#### Using the remote repository

You can apply the configuration directly from the GitHub repository:

```bash
kubectl apply -k 'https://github.com/tomncooper/strimzi-kustomize//kafka/single-node?ref=main'
```
#### Using the local repository

```bash
kubectl apply -k kafka/single-node/
```

## Apicurio Registry

[Apicurio Registry](https://www.apicur.io/registry/) is a schema/API registry that can use Kafka as a storage backend via the KafkaSQL storage type.

### Operator Installation

#### Deploy All-Namespaces Mode

This configuration allows the operator to manage Apicurio Registry instances in any namespace.

##### Using the remote repository

```bash
kubectl apply -k 'https://github.com/tomncooper/strimzi-kustomize//apicurio-registry/operator/all-namespaces?ref=main'
```

##### Using the local repository

```bash
kubectl apply -k apicurio-registry/operator/all-namespaces/
```

#### Deploy Single-Namespace Mode

This configuration restricts the operator to only manage registry instances in the `apicurio-registry` namespace.

##### Using the remote repository

```bash
kubectl apply -k 'https://github.com/tomncooper/strimzi-kustomize//apicurio-registry/operator/single-namespace?ref=main'
```

##### Using the local repository

```bash
kubectl apply -k apicurio-registry/operator/single-namespace/
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

## StreamsHub Console

[StreamsHub Console](https://github.com/streamshub/console) provides a web-based UI for monitoring and managing Kafka clusters.

### StreamsHub Console Operator Installation

#### Using the local repository

```bash
kubectl apply -k streamshub-console-operator/
```

### Deploying a Console Instance

The console instance is configured to connect to the `test-cluster` Kafka cluster deployed via the `kafka/single-node/` configuration.

#### Using the local repository

```bash
kubectl apply -k streamshub-console/
```

### Accessing the Console

The console creates an Ingress resource with the hostname configured in the Console CR (default: `console.streamshub.local`).

#### Minikube

When using minikube, enable the ingress addon and run `minikube tunnel`:

```bash
minikube addons enable ingress
minikube tunnel
```

Then use port-forwarding to access the console:

```bash
kubectl port-forward -n streamshub-console svc/streamshub-console-console-service 8080:80
```

Open http://localhost:8080 in your browser.

## Updating Versions

To update the version of a component, use the update script:

```bash
./update-version.sh <component> <new-version>

```

List available versions:

```bash
./update-version.sh --list strimzi
./update-version.sh --list apicurio-registry
./update-version.sh --list streamshub-console
```

See `./update-version.sh --help` for more options, such as performing a dry-run or checking if a release exists.
