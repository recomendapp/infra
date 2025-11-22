#!/usr/bin/env bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging
log_info() {
    echo -e "${BLUE}ℹ️  ${1}${NC}"
}

log_success() {
    echo -e "${GREEN}✅ ${1}${NC}"
}

log_error() {
    echo -e "${RED}❌ ${1}${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  ${1}${NC}"
}

log_debug() {
    if [ "${DEBUG:-false}" = "true" ]; then
        echo -e "${CYAN}🔍 ${1}${NC}"
    fi
}

log_section() {
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo -e "${BLUE}  ${1}${NC}"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
}

log_component() {
    echo ""
    echo "────────────────────────────────────────────────────────────────"
    echo -e "${CYAN}  📦 ${1}${NC}"
    echo "────────────────────────────────────────────────────────────────"
    echo ""
}

# Check required environment variables
check_env_var() {
    local var_name="$1"
    if [ -z "${!var_name}" ]; then
        log_error "Required environment variable $var_name is not set"
        return 1
    fi
    return 0
}

# Check multiple env vars
check_env_vars() {
    local missing=()
    for var in "$@"; do
        if [ -z "${!var}" ]; then
            missing+=("$var")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required environment variables:"
        for var in "${missing[@]}"; do
            echo "  • $var"
        done
        return 1
    fi
    return 0
}

# Get script directory
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# Get project root
get_project_root() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # Assume scripts are in PROJECT_ROOT/scripts or PROJECT_ROOT/scripts/lib
    if [[ "$script_dir" == */scripts/lib ]]; then
        cd "$script_dir/../.." && pwd
    elif [[ "$script_dir" == */scripts ]]; then
        cd "$script_dir/.." && pwd
    else
        cd "$script_dir" && pwd
    fi
}

# Check kubectl connectivity
check_kubectl() {
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "Cannot connect to Kubernetes cluster"
        log_info "Please ensure KUBECONFIG is set correctly"
        return 1
    fi
    return 0
}

# Source all lib files
source_libs() {
    local lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    for lib in "$lib_dir"/*.sh; do
        if [ "$lib" != "${BASH_SOURCE[0]}" ]; then
            source "$lib"
        fi
    done
}