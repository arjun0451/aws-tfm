#!/bin/bash
# cloud-init user-data for server2
# Installs Apache httpd and serves "Hello from server2"

set -euo pipefail

SERVER_NAME="server2"
MESSAGE="Hello from server2"
WEB_ROOT="/var/www/html"
WEB_PORT="80"

echo "==> Configuring ${SERVER_NAME} on port ${WEB_PORT}"

mkdir -p "${WEB_ROOT}"

cat > "${WEB_ROOT}/index.html" <<EOF
<!DOCTYPE html>
<html>
<head><title>${MESSAGE}</title></head>
<body>
<h1>${MESSAGE}</h1>
<p>${MESSAGE}</p>
</body>
</html>
EOF

echo "OK" > "${WEB_ROOT}/health.html"

# Install and start the web server
dnf install -y httpd >/dev/null 2>&1 || yum install -y httpd >/dev/null 2>&1

systemctl enable --now httpd
systemctl restart httpd

echo "==> ${SERVER_NAME} web server configured"
curl -s -o /dev/null -w "local status: %{http_code}\n" "http://localhost:${WEB_PORT}/" || true