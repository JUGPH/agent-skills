#!/usr/bin/env bash
set -euo pipefail

# Enterprise Spring Boot Security Anti-Pattern Scanner
# Scans Java source files for common security misconfigurations

TARGET_DIR="${1:-src/main/java}"

echo "========================================================"
echo "Running Spring Security Anti-Pattern Audit on: ${TARGET_DIR}"
echo "========================================================"

ISSUES_FOUND=0

check_pattern() {
    local description="$1"
    local pattern="$2"
    echo -n "Scanning for ${description}... "
    local matches
    matches=$(grep -rnE "${pattern}" "${TARGET_DIR}" 2>/dev/null || true)
    if [ -n "${matches}" ]; then
        echo -e "\033[0;31m[FAIL]\033[0m"
        echo "${matches}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
        echo -e "\033[0;32m[PASS]\033[0m"
    fi
}

# 1. Check for wildcard CORS with credentials
check_pattern "Wildcard CORS (allowedOrigins(\"*\"))" 'allowedOrigins\("\*"\)'

# 2. Check for deprecated Spring Security 5 methods
check_pattern "Deprecated authorizeRequests() or antMatchers()" 'authorizeRequests\(|antMatchers\('

# 3. Check for plaintext @Value injection of sensitive keys
check_pattern "@Value secret injection (hardcoded secret strings)" '@Value\(".*\b(secret|password|key|token)\b.*"\)'

# 4. Check for controllers lacking @PreAuthorize on public mappings
check_pattern "Public @DeleteMapping or @PostMapping without @PreAuthorize" '@(PostMapping|PutMapping|DeleteMapping).*'

# 5. Check for WebSecurityConfigurerAdapter (removed in Spring Security 6+)
check_pattern "Legacy WebSecurityConfigurerAdapter" 'WebSecurityConfigurerAdapter'

echo "========================================================"
if [ "${ISSUES_FOUND}" -eq 0 ]; then
    echo -e "\033[0;32mSecurity audit passed! No critical anti-patterns detected.\033[0m"
    exit 0
else
    echo -e "\033[0;31mSecurity audit completed with ${ISSUES_FOUND} finding(s).\033[0m"
    exit 1
fi
