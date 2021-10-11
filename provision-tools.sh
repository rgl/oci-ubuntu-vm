#!/bin/bash
set -euxo pipefail

# install dependencies.
sudo apt-get install -y unzip jq

# install terraform.
# see https://www.terraform.io/downloads.html
artifact_url=https://releases.hashicorp.com/terraform/1.0.8/terraform_1.0.8_linux_amd64.zip
artifact_sha=a73459d406067ce40a46f026dce610740d368c3b4a3d96591b10c7a577984c2e
artifact_path="/tmp/$(basename $artifact_url)"
wget -qO $artifact_path $artifact_url
if [ "$(sha256sum $artifact_path | awk '{print $1}')" != "$artifact_sha" ]; then
    echo "downloaded $artifact_url failed the checksum verification"
    exit 1
fi
sudo unzip -o $artifact_path -d /usr/local/bin
rm $artifact_path
CHECKPOINT_DISABLE=1 terraform version

# install oci-cli.
# see https://github.com/oracle/oci-cli
# NB by default this installs at:
#       $HOME/lib/oracle-cli
#       $HOME/bin
#       $HOME/bin/oci-cli-scripts
#    and modifies your bashrc to include bin in the PATH and bash completions.
# NB you have to restart your shell session.
oci_cli_version=3.0.5
wget -qOinstall-oci-cli.sh https://raw.githubusercontent.com/oracle/oci-cli/v$oci_cli_version/scripts/install/install.sh
bash install-oci-cli.sh \
    --oci-cli-version $oci_cli_version \
    --accept-all-defaults
rm install-oci-cli.sh
~/bin/oci --version
