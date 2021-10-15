#!/bin/bash
set -euxo pipefail

# install dependencies.
sudo apt-get install -y unzip jq

# install terraform.
# see https://www.terraform.io/downloads.html
case "$(dpkg --print-architecture)" in
    amd64)
        artifact_url="https://releases.hashicorp.com/terraform/1.0.9/terraform_1.0.9_linux_amd64.zip"
        artifact_sha=f06ac64c6a14ed6a923d255788e4a5daefa2b50e35f32d7a3b5a2f9a5a91e255
        ;;
    arm64)
        artifact_url="https://releases.hashicorp.com/terraform/1.0.9/terraform_1.0.9_linux_arm64.zip"
        artifact_sha=457ac590301126e7b151ea08c5b9586a882c60039a0605fb1e44b8d23d2624fd
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
oci_cli_version=3.1.1
wget -qOinstall-oci-cli.sh https://raw.githubusercontent.com/oracle/oci-cli/v$oci_cli_version/scripts/install/install.sh
bash install-oci-cli.sh \
    --oci-cli-version $oci_cli_version \
    --accept-all-defaults
rm install-oci-cli.sh
~/bin/oci --version
