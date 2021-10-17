An example Ubuntu virtual machine running in the Oracle Cloud Infrastructure (OCI) cloud.

For a similar example running in Azure see the [rgl/azure-ubuntu-vm](https://github.com/rgl/azure-ubuntu-vm) repository.

# Usage (on a Ubuntu Desktop)

Install the tools:

```bash
./provision-tools.sh
```

Restart your shell:

```bash
exit
```

Review the [`main.tf` file](main.tf).

Login into oci:

```bash
# NB this saves the details at ~/.oci/config
# NB you really have to choose a region. without any arguments it will ask it.
# NB if you use another region, you must modify the vm_image_ocid variable
#    inside the main.tf file.
# NB this authentication session in only valid for one hour.
oci session authenticate --region eu-amsterdam-1 # NB save as the DEFAULT profile
```

Try using oci by listing the regions and users:

```bash
oci iam region list --auth security_token
oci iam user list --auth security_token
```

Initialize terraform:

```bash
make terraform-init
```

Launch the example:

```bash
make terraform-plan
make terraform-apply
```

At VM initialization time [cloud-init](https://cloudinit.readthedocs.io/en/latest/index.html) will run the `provision-app.sh` script to launch the example application.

Wait for `cloud-init` to finish:

```bash
while ! ssh "ubuntu@$(terraform output -raw vm_ip_address)" cloud-init status --wait --long; do sleep 5; done
```

**NB** The `cloud-init` logs are at `/var/log/cloud-init-output.log`.

Test the `app` endpoint:

```bash
wget -qO- "http://$(terraform output -raw vm_ip_address)/test"
```

Connect to the VM serial console:

**NB** the console requires login, which means you must have previously set the
ubuntu user password (by default it does not have a password; only ssh
key login).

```bash
# NB the ssh command is alike:
#       ssh -o ProxyCommand='ssh -W %h:%p -p 443 ocid1.instanceconsoleconnection.oc1.eu-amsterdam-1.<id1>@instance-console.eu-amsterdam-1.oci.oraclecloud.com' ocid1.instance.oc1.eu-amsterdam-1.<id2>
bash -c "$(terraform output -raw vm_serial_console_ssh_command)"
```

You can also connect to the VNC console of the VM:

```bash
# NB the ssh command is alike:
#       ssh -o ProxyCommand='ssh -W %h:%p -p 443 ocid1.instanceconsoleconnection.oc1.eu-amsterdam-1.<id1>@instance-console.eu-amsterdam-1.oci.oraclecloud.com'-N -L localhost:5900:ocid1.instance.oc1.eu-amsterdam-1.<id2>:5900 ocid1.instance.oc1.eu-amsterdam-1.<id2>
bash -c "$(terraform output -raw vm_vnc_console_ssh_command)" & # start the tunnel in background.
vinagre localhost:5900 # open a VNC connection tru the local tunnel.
```

Connect to the VM and start a Debian LXC system container:

```bash
ssh "ubuntu@$(terraform output -raw vm_ip_address)" # enter the VM.
snap list lxd # show the lxd package version.
journalctl -u snap.lxd.daemon.service # show lxd logs.
lxc launch images:debian/11 debian # start the container.
lxc exec debian -- bash # enter the container.
lscpu
# NB if the container does not obtain an IP address from lxd managed dnsmasq
#    DHCP server, try to reboot the host. it seems lxd/docker iptables rules
#    are racing/conflicting with each other. it generally fubars when the
#    lxd iptables rules are after the docker ones.
#    NB we already workround this by configuring cloud-init to reboot the
#       system, so the above problem should not occur anymore.
ping -c 3 debian.org
exit # exit the container.
lxc delete debian --force # destroy the container.
exit # exit the VM.
```

Destroy everything:

```bash
make terraform-destroy
```
