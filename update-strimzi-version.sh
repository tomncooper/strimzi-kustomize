#!/usr/bin/env bash
#
# Update Strimzi version across all kustomization files
#
# Usage: ./update-strimzi-version.sh <new-version>
# Example: ./update-strimzi-version.sh 0.50.0
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Files that contain Strimzi version references
CLUSTER_OPERATOR_KUSTOMIZATION="${SCRIPT_DIR}/cluster-operator/base/kustomization.yaml"
KAFKA_SINGLE_NODE_KUSTOMIZATION="${SCRIPT_DIR}/kafka/single-node/kustomization.yaml"

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

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] <new-version>

Update Strimzi version in all kustomization files.

Arguments:
  new-version    The Strimzi version to update to (e.g., 0.50.0)

Options:
  -c, --check        Only check if the release exists on GitHub (no changes made)
  -d, --dry-run      Show what would be changed without making changes
  -l, --list [N|all] List available Strimzi versions (default: 20, or 'all')
  -h, --help         Show this help message

Examples:
  $(basename "$0") --list           # List latest 20 versions
  $(basename "$0") --list 10        # List latest 10 versions
  $(basename "$0") --list all       # List all versions
  $(basename "$0") 0.50.0           # Update to version
  $(basename "$0") --check 0.50.0   # Verify release exists (no changes)
  $(basename "$0") --dry-run 0.50.0 # Preview changes
EOF
    exit 0
}

# Get current version from cluster-operator kustomization
get_current_version() {
    grep -oP 'releases/download/\K[0-9]+\.[0-9]+\.[0-9]+' "$CLUSTER_OPERATOR_KUSTOMIZATION" | head -1
}

# List available releases from GitHub
list_releases() {
    local limit="${1:-20}"
    local is_all=false
    local per_page="$limit"

    if [[ "$limit" == "all" ]]; then
        is_all=true
        per_page=100  # GitHub API max per page
    fi

    info "Fetching available Strimzi releases from GitHub..."
    echo ""

    if ! command -v curl &> /dev/null; then
        error "curl is required to list releases"
        exit 1
    fi

    local releases=""

    if [[ "$is_all" == "true" ]]; then
        # Paginate through all releases
        local page=1
        while true; do
            local page_releases
            page_releases=$(curl -s "https://api.github.com/repos/strimzi/strimzi-kafka-operator/releases?per_page=100&page=${page}" \
                | grep '"tag_name":' \
                | sed -E 's/.*"tag_name": "([^"]+)".*/\1/' || true)

            if [[ -z "$page_releases" ]]; then
                break
            fi

            if [[ -n "$releases" ]]; then
                releases="${releases}"$'\n'"${page_releases}"
            else
                releases="$page_releases"
            fi
            ((page++)) || true

            # Safety limit to avoid infinite loops
            if [[ $page -gt 10 ]]; then
                break
            fi
        done
    else
        releases=$(curl -s "https://api.github.com/repos/strimzi/strimzi-kafka-operator/releases?per_page=${per_page}" \
            | grep '"tag_name":' \
            | sed -E 's/.*"tag_name": "([^"]+)".*/\1/' \
            | head -n "$limit")
    fi

    if [[ -z "$releases" ]]; then
        error "Failed to fetch releases from GitHub"
        exit 1
    fi

    local current_version
    current_version=$(get_current_version)

    local count
    count=$(echo "$releases" | wc -l | tr -d ' ')

    if [[ "$is_all" == "true" ]]; then
        echo "Available versions (all ${count}):"
    else
        echo "Available versions (latest ${limit}):"
    fi
    echo ""
    while IFS= read -r version; do
        if [[ "$version" == "$current_version" ]]; then
            echo "  ${version}  (current)"
        else
            echo "  ${version}"
        fi
    done <<< "$releases"
    echo ""
    info "View all releases: https://github.com/strimzi/strimzi-kafka-operator/releases"
}

# Check if release exists on GitHub
check_release_exists() {
    local version="$1"
    local release_url="https://github.com/strimzi/strimzi-kafka-operator/releases/tag/${version}"

    info "Checking if release ${version} exists..."

    if command -v curl &> /dev/null; then
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" -L "$release_url")
        if [[ "$http_code" == "200" ]]; then
            info "Release ${version} exists on GitHub"
            return 0
        else
            error "Release ${version} not found on GitHub (HTTP ${http_code})"
            error "Check available releases at: https://github.com/strimzi/strimzi-kafka-operator/releases"
            return 1
        fi
    else
        warn "curl not available, skipping release check"
        return 0
    fi
}

# Update version in a file using sed
update_file() {
    local file="$1"
    local old_version="$2"
    local new_version="$3"
    local dry_run="$4"

    if [[ ! -f "$file" ]]; then
        warn "File not found: ${file}"
        return 1
    fi

    # Check if old version exists in file
    if ! grep -q "$old_version" "$file"; then
        warn "Version ${old_version} not found in ${file}"
        return 1
    fi

    if [[ "$dry_run" == "true" ]]; then
        echo "Would update: ${file}"
        echo "  Old version: ${old_version}"
        echo "  New version: ${new_version}"
        echo "  Changes:"
        while IFS= read -r line; do
            echo "    - ${line}"
            echo "    + ${line//$old_version/$new_version}"
        done < <(grep "$old_version" "$file")
    else
        # Use sed to replace version
        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS sed requires empty string after -i
            sed -i '' "s/${old_version}/${new_version}/g" "$file"
        else
            # GNU sed
            sed -i "s/${old_version}/${new_version}/g" "$file"
        fi
        info "Updated: ${file}"
    fi
}

main() {
    local check_release=false
    local dry_run=false
    local list_releases_flag=false
    local list_limit="20"
    local new_version=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--check)
                check_release=true
                shift
                ;;
            -d|--dry-run)
                dry_run=true
                shift
                ;;
            -l|--list)
                list_releases_flag=true
                shift
                # Check if next arg is a number or "all"
                if [[ $# -gt 0 && ( "$1" == "all" || "$1" =~ ^[0-9]+$ ) ]]; then
                    list_limit="$1"
                    shift
                fi
                ;;
            -h|--help)
                usage
                ;;
            -*)
                error "Unknown option: $1"
                usage
                ;;
            *)
                if [[ -z "$new_version" ]]; then
                    new_version="$1"
                else
                    error "Multiple versions specified"
                    usage
                fi
                shift
                ;;
        esac
    done

    # Handle --list flag
    if [[ "$list_releases_flag" == "true" ]]; then
        list_releases "$list_limit"
        exit 0
    fi

    # Validate new version provided
    if [[ -z "$new_version" ]]; then
        error "No version specified"
        usage
    fi

    # Validate version format
    if ! [[ "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        error "Invalid version format: ${new_version}"
        error "Expected format: X.Y.Z (e.g., 0.50.0)"
        exit 1
    fi

    # Get current version
    local current_version
    current_version=$(get_current_version)

    if [[ -z "$current_version" ]]; then
        error "Could not determine current Strimzi version"
        exit 1
    fi

    info "Current Strimzi version: ${current_version}"
    info "Target Strimzi version: ${new_version}"

    if [[ "$current_version" == "$new_version" ]]; then
        warn "Already at version ${new_version}"
        exit 0
    fi

    # Check if release exists
    if [[ "$check_release" == "true" ]]; then
        if check_release_exists "$new_version"; then
            exit 0
        else
            exit 1
        fi
    fi

    echo ""

    # Update files
    local files_updated=0

    if update_file "$CLUSTER_OPERATOR_KUSTOMIZATION" "$current_version" "$new_version" "$dry_run"; then
        ((files_updated++)) || true
    fi

    if update_file "$KAFKA_SINGLE_NODE_KUSTOMIZATION" "$current_version" "$new_version" "$dry_run"; then
        ((files_updated++)) || true
    fi

    echo ""

    if [[ "$dry_run" == "true" ]]; then
        info "Dry run complete. ${files_updated} file(s) would be updated."
    else
        info "Updated ${files_updated} file(s) from ${current_version} to ${new_version}"
        echo ""
        info "Next steps:"
        echo "  1. Review the changes: git diff"
        echo "  2. Test the deployment: kubectl apply -k cluster-operator/all-namespaces/ --dry-run=client"
        echo "  3. Commit the changes: git add -A && git commit -m 'Update Strimzi to ${new_version}'"
    fi
}

main "$@"
