<#
.SYNOPSIS
    Enterprise Spring Boot Security Anti-Pattern Scanner (PowerShell)
    Scans Java source files for common security misconfigurations.
#>
param (
    [string]$TargetDir = "src/main/java"
)

$ErrorActionPreference = "Continue"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Running Spring Security Anti-Pattern Audit on: $TargetDir" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

$issuesFound = 0

function Check-Pattern {
    param (
        [string]$Description,
        [string]$Pattern
    )
    Write-Host -NoNewline "Scanning for $Description... "
    $matches = Get-ChildItem -Path $TargetDir -Recurse -Filter "*.java" -ErrorAction SilentlyContinue |
               Select-String -Pattern $Pattern

    if ($matches) {
        Write-Host "[FAIL]" -ForegroundColor Red
        foreach ($m in $matches) {
            Write-Host "  $($m.Filename):$($m.LineNumber): $($m.Line.Trim())" -ForegroundColor Yellow
        }
        $script:issuesFound++
    } else {
        Write-Host "[PASS]" -ForegroundColor Green
    }
}

Check-Pattern -Description 'Wildcard CORS (allowedOrigins("*"))' -Pattern 'allowedOrigins\("\*"\)'
Check-Pattern -Description 'Deprecated authorizeRequests() or antMatchers()' -Pattern 'authorizeRequests\(|antMatchers\('
Check-Pattern -Description '@Value secret injection' -Pattern '@Value\(.*(secret|password|key|token).*\)'
Check-Pattern -Description 'Legacy WebSecurityConfigurerAdapter' -Pattern 'WebSecurityConfigurerAdapter'

Write-Host "========================================================" -ForegroundColor Cyan
if ($issuesFound -eq 0) {
    Write-Host "Security audit passed! No critical anti-patterns detected." -ForegroundColor Green
    exit 0
} else {
    Write-Host "Security audit completed with $issuesFound finding(s)." -ForegroundColor Red
    exit 1
}
