#!/bin/bash
set -euxo pipefail

# install dependencies.
sudo apt-get install -y unzip jq

# install terraform.
# see https://developer.hashicorp.com/terraform/downloads
case "$(dpkg --print-architecture)" in
    amd64)
        artifact_url="https://releases.hashicorp.com/terraform/1.3.7/terraform_1.3.7_linux_amd64.zip"
        artifact_sha=b8cf184dee15dfa89713fe56085313ab23db22e17284a9a27c0999c67ce3021e
        ;;
    arm64)
        artifact_url="https://releases.hashicorp.com/terraform/1.3.7/terraform_1.3.7_linux_arm64.zip"
        artifact_sha=5b491c555ea8a62dda551675fd9f27d369f5cdbe87608d2a7367d3da2d38ea38
        ;;
    *)
        echo "ERROR: Unknow architecture $(dpkg --print-architecture)"
        exit 1
        ;;
esac
artifact_path="/tmp/$(basename $artifact_url)"
wget -qO $artifact_path $artifact_url
if [ "$(sha256sum $artifact_path | awk '{print $1}')" != "$artifact_sha" ]; then
    echo "ERROR: Downloaded $artifact_url failed the checksum verification"
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
oci_cli_version=3.22.3
wget -qOinstall-oci-cli.sh https://raw.githubusercontent.com/oracle/oci-cli/v$oci_cli_version/scripts/install/install.sh
bash install-oci-cli.sh \
    --oci-cli-version $oci_cli_version \
    --accept-all-defaults
rm install-oci-cli.sh
~/bin/oci --version
