#!/usr/bin/env bash
#
# Install the full Strimzi + Apicurio Registry dev stack
#
# Usage:
#   # Install from remote repository
#   curl -sL https://raw.githubusercontent.com/tomncooper/strimzi-kustomize/main/dev/install.sh | bash
#
#   # Pin to a specific ref or fork
#   curl -sL https://raw.githubusercontent.com/tomncooper/strimzi-kustomize/main/dev/install.sh | REF=v1.0.0 bash
#   curl -sL https://raw.githubusercontent.com/myuser/strimzi-kustomize/main/dev/install.sh | REPO=myuser/strimzi-kustomize bash
#
# Environment variables:
#   REPO    — GitHub repo path (default: tomncooper/strimzi-kustomize)
#   REF     — Git ref/branch/tag (default: main)
#   TIMEOUT — kubectl wait timeout (default: 120s)
#

set -euo pipefail

# Defaults (overridable via environment variables)
REPO="${REPO:-tomncooper/strimzi-kustomize}"
REF="${REF:-main}"
TIMEOUT="${TIMEOUT:-120s}"

# Color output helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Build the kustomize URL for a given sub-path
kustomize_url() {
    local path="$1"
    echo "https://github.com/${REPO}//${path}?ref=${REF}"
}

# Check prerequisites
check_prerequisites() {
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed or not in PATH"
        error "Install kubectl: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi
    info "kubectl found: $(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | head -1)"
}

main() {
    echo ""
    info "Installing Strimzi + Apicurio Registry dev stack"
    info "Repo: ${REPO} | Ref: ${REF} | Timeout: ${TIMEOUT}"
    echo ""

    # --- Prerequisites ---
    check_prerequisites
    echo ""

    # --- Step 1: Install operators (dev/base) ---
    local base_url
    base_url=$(kustomize_url "dev/base")
    info "Step 1/4: Installing operators..."
    info "Applying: ${base_url}"
    kubectl apply -k "${base_url}"
    echo ""

    # --- Step 2: Wait for Strimzi operator ---
    info "Step 2/4: Waiting for strimzi-cluster-operator to be ready (timeout: ${TIMEOUT})..."
    kubectl wait --for=condition=Available deployment/strimzi-cluster-operator \
        -n strimzi --timeout="${TIMEOUT}"
    info "Strimzi operator is ready"
    echo ""

    # --- Step 3: Wait for Apicurio Registry operator ---
    info "Step 3/4: Waiting for apicurio-registry-operator to be ready (timeout: ${TIMEOUT})..."
    kubectl wait --for=condition=Available deployment/apicurio-registry-operator \
        -n apicurio-registry --timeout="${TIMEOUT}"
    info "Apicurio Registry operator is ready"
    echo ""

    # --- Step 4: Install operands (dev/stack) ---
    local stack_url
    stack_url=$(kustomize_url "dev/stack")
    info "Step 4/4: Installing operands (Kafka cluster, Registry instance)..."
    info "Applying: ${stack_url}"
    kubectl apply -k "${stack_url}"
    echo ""

    # --- Summary ---
    info "Dev stack installation complete!"
    echo ""
    echo "Deployed components:"
    echo "  - Strimzi operator          (namespace: strimzi)"
    echo "  - Kafka cluster             (namespace: kafka, name: test-cluster)"
    echo "  - Apicurio Registry operator (namespace: apicurio-registry)"
    echo "  - Apicurio Registry instance (namespace: apicurio-registry, storage: in-memory)"
    echo ""
    echo "Verify with:"
    echo "  kubectl get deployment -n strimzi strimzi-cluster-operator"
    echo "  kubectl get kafka -n kafka"
    echo "  kubectl get deployment -n apicurio-registry apicurio-registry-operator"
    echo "  kubectl get apicurioregistry3 -n apicurio-registry"
}

main
