#!/bin/bash
set -euxo pipefail

# configure the firewall to allow HTTP ingress.
# NB we should not simply replace the existing firewall rules. they are
#    configured to provide a sane base for accessing the oci services.
sed -i -E 's,^(-A INPUT .+ --dport 22 .+),-A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT\n\1,g' /etc/iptables/rules.v4
iptables-restore </etc/iptables/rules.v4

# install node LTS.
# see https://github.com/nodesource/distributions#debinstall
apt-get install -y curl
curl -sL https://deb.nodesource.com/setup_22.x | bash
apt-get install -y nodejs
node --version
npm --version

# add the app user.
groupadd --system app
adduser \
    --system \
    --disabled-login \
    --no-create-home \
    --gecos '' \
    --ingroup app \
    --home /opt/app \
    app
install -d -o root -g app -m 750 /opt/app

# create an example http server and run it as a systemd service.
cat >/opt/app/main.js <<EOF
const http = require("http");

function createRequestListener(metadata) {
    return (request, response) => {
        const serverAddress = \`\${request.socket.localAddress}:\${request.socket.localPort}\`;
        const clientAddress = \`\${request.socket.remoteAddress}:\${request.socket.remotePort}\`;
        const message = \`VM Display Name: \${metadata.displayName}
VM ID: \${metadata.id}
Server Address: \${serverAddress}
Client Address: \${clientAddress}
Request URL: \${request.url}
\`;
        console.log(message);
        response.writeHead(200, {"Content-Type": "text/plain"});
        response.write(message);
        response.end();
    };
}

function main(metadata, port) {
    const server = http.createServer(createRequestListener(metadata));
    server.listen(port);
}

// see https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/gettingmetadata.htm#accessing__linux
// see https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/gettingmetadata.htm#metadata-keys
http.get(
    "http://169.254.169.254/opc/v2/instance/",
    {
        headers: {
            Authorization: "Bearer Oracle"
        }
    },
    (response) => {
        let data = "";
        response.on("data", (chunk) => data += chunk);
        response.on("end", () => {
            const metadata = JSON.parse(data);
            main(metadata, process.argv[2]);
        });
    }
).on("error", (error) => console.log("Error fetching metadata: " + error.message));
EOF
cat >package.json <<'EOF'
{
    "name": "app",
    "description": "example application",
    "version": "1.0.0",
    "license": "MIT",
    "main": "main.js",
    "dependencies": {}
}
EOF
npm install

# launch the app.
cat >/etc/systemd/system/app.service <<EOF
[Unit]
Description=Example Web Application
After=network.target

[Service]
Type=simple
User=app
Group=app
AmbientCapabilities=CAP_NET_BIND_SERVICE
Environment=NODE_ENV=production
ExecStart=/usr/bin/node main.js 80
WorkingDirectory=/opt/app
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF
systemctl enable app
systemctl start app

# try it.
sleep .2
wget -qO- localhost/try
