#!/usr/bin/env bash
set -euo pipefail

# JFR (Java Flight Recorder) Profiling Automation Script
# Attaches to a running Java process, enables virtual thread and GC event recording, and produces a diagnostic dump.
# Usage: ./jfr-profile.sh <PID> [DURATION_SECONDS] [OUTPUT_FILE]

PID="${1:-}"
DURATION="${2:-60}"
OUTPUT="${3:-profile-${PID}-$(date +%s).jfr}"

if [ -z "${PID}" ]; then
    echo "Usage: $0 <Java_PID> [duration_seconds] [output_filename]"
    echo ""
    echo "Active Java processes:"
    jcmd -l 2>/dev/null || true
    exit 1
fi

echo "=========================================================="
echo "Starting JFR diagnostic recording on PID ${PID}"
echo "Duration: ${DURATION} seconds"
echo "Output:   ${OUTPUT}"
echo "=========================================================="

jcmd "${PID}" JFR.start \
    name="PerfDiagnostic" \
    duration="${DURATION}s" \
    filename="${OUTPUT}" \
    settings=profile \
    jdk.VirtualThreadPinned#enabled=true \
    jdk.VirtualThreadPinned#threshold=10ms \
    jdk.ObjectAllocationInNewTLAB#enabled=true

echo "Recording in progress... Sleeping for ${DURATION} seconds."
sleep "${DURATION}"

echo "=========================================================="
echo "Recording finished!"
echo "Saved to: ${OUTPUT}"
echo "Inspect with JDK Mission Control (JMC) or run:"
echo "  jfr print --events jdk.VirtualThreadPinned ${OUTPUT}"
echo "=========================================================="
