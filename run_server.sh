#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="${ROOT_DIR}/safety_monitor_server"
PYTHON_CMD="${ROOT_DIR}/.venv/bin/python"
SERVER_LOG_DIR="${ROOT_DIR}/logs"
export SAFETY_MONITOR_LOG_FILE="${SERVER_LOG_DIR}/server.log"

mkdir -p "${SERVER_LOG_DIR}"

if [[ ! -f "${SERVER_DIR}/main.py" ]]; then
  echo "Server entry file not found: ${SERVER_DIR}/main.py" >&2
  exit 1
fi

if [[ ! -x "${PYTHON_CMD}" ]]; then
  echo "Python venv not found: ${PYTHON_CMD}" >&2
  echo "Create it first:" >&2
  echo "  python3.12 -m venv .venv" >&2
  echo "  . .venv/bin/activate" >&2
  echo "  python -m pip install --upgrade pip" >&2
  echo "  python -m pip install -r requirements-server.txt" >&2
  exit 1
fi

echo "Starting Safety Monitor Server on http://0.0.0.0:8000"
echo "Server log file: ${SAFETY_MONITOR_LOG_FILE}"
echo
echo "Server URLs to use from other PCs:"
hostname -I 2>/dev/null | tr ' ' '\n' | awk 'NF { print "  http://" $1 ":8000" }' || true
echo
echo "If other PCs cannot open http://SERVER_IP:8000/health, check Ubuntu firewall/security-group rules for TCP 8000."
echo

cd "${SERVER_DIR}"
exec "${PYTHON_CMD}" -m uvicorn main:app --host 0.0.0.0 --port 8000 --no-access-log
