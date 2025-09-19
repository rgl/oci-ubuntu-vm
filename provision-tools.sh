#!/bin/bash
set -euxo pipefail

# install dependencies.
sudo apt-get install -y unzip jq

# install terraform.
# see https://developer.hashicorp.com/terraform/downloads
# renovate: datasource=github-releases depName=hashicorp/terraform
terraform_version='1.13.3'
case "$(dpkg --print-architecture)" in
    amd64)
        artifact_url="https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip"
        ;;
    arm64)
        artifact_url="https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_arm64.zip"
        ;;
    *)
        echo "ERROR: Unknow architecture $(dpkg --print-architecture)"
        exit 1
        ;;
esac
artifact_path="/tmp/$(basename $artifact_url)"
wget -qO "$artifact_path" "$artifact_url"
sudo unzip -o "$artifact_path" -d /usr/local/bin
rm "$artifact_path"
CHECKPOINT_DISABLE=1 terraform version

# install oci-cli.
# see https://github.com/oracle/oci-cli
# NB by default this installs at:
#       $HOME/lib/oracle-cli
#       $HOME/bin
#       $HOME/bin/oci-cli-scripts
#    and modifies your bashrc to include bin in the PATH and bash completions.
# NB you have to restart your shell session.
# renovate: datasource=github-releases depName=oracle/oci-cli
oci_cli_version='3.66.1'
rm -rf ~/bin/oci ~/lib/oracle-cli ~/bin/oci-cli-scripts
wget -qOinstall-oci-cli.sh https://raw.githubusercontent.com/oracle/oci-cli/v$oci_cli_version/scripts/install/install.sh
bash install-oci-cli.sh \
    --oci-cli-version $oci_cli_version \
    --accept-all-defaults
rm install-oci-cli.sh
~/bin/oci --version
