terraform {
  required_version = "1.0.7"
  required_providers {
    # see https://registry.terraform.io/providers/hashicorp/template
    # see https://github.com/hashicorp/terraform-provider-template
    template = {
      source = "hashicorp/template"
      version = "2.2.0"
    }
    # see https://registry.terraform.io/providers/hashicorp/oci
    # see https://github.com/terraform-providers/terraform-provider-oci
    oci = {
      source = "hashicorp/oci"
      version = "4.45.0"
    }
  }
}

# oci provider settings.
# NB the Makefile sets this from your current oci-cli session.
variable "oci_tenancy_ocid" {}

# the compartment name that will be created inside the oci_tenancy_ocid root.
variable "compartment_name" {
  default = "rgl-ubuntu-vm-example"
}

# NB when you run make terraform-apply this is set from the TF_VAR_ssh_public_key
#    environment variable, which comes from the ~/.ssh/id_rsa.pub file.
variable "ssh_public_key" {
}

variable "vm_shape" {
  default = "VM.Standard.E2.1.Micro" # Always Free-eligible. 1 OCPU. 1 GB RAM. 1 NIC.
}

variable "vm_image_ocid" {
  # use Canonical-Ubuntu-20.04-Minimal-2021.08.26-0
  # NB the image id depends on the region.
  # NB see https://docs.oracle.com/en-us/iaas/images/ubuntu-2004/
  # NB see https://docs.oracle.com/en-us/iaas/images/image/aab05b4b-92b2-483b-a52c-1892f5ab90ba/
  default = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaaorcd6czuz2jqo6zxreigh2jjbdqyqzjp7x4mfk6hw4topxwjv7gq"
}

output "vm_serial_console_ssh_command" {
  value = oci_core_instance_console_connection.example.connection_string
}

output "vm_vnc_console_ssh_command" {
  value = oci_core_instance_console_connection.example.vnc_connection_string
}

output "vm_console_host_key_fingerprint" {
  value = oci_core_instance_console_connection.example.service_host_key_fingerprint
}

output "vm_ip_address" {
  value = oci_core_instance.example.public_ip
}

# see https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformproviderconfiguration.htm
# NB without any setting, the configuration is loaded from ~/.oci/config.
provider "oci" {
}

data "oci_identity_availability_domain" "example" {
  compartment_id = var.oci_tenancy_ocid
  ad_number = 1
}

resource "oci_identity_compartment" "example" {
  compartment_id = var.oci_tenancy_ocid
  name = var.compartment_name
  description = "example"
  enable_delete = true
}

# see https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_vcn
# see Requirements for DNS Labels and Hostnames at https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/dns.htm
resource "oci_core_vcn" "example" {
  compartment_id = oci_identity_compartment.example.id
  cidr_block = "10.1.0.0/16"
  display_name = "example net"
  dns_label = "example"
}

# see https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_subnet
# see Requirements for DNS Labels and Hostnames at https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/dns.htm
resource "oci_core_subnet" "example" {
  compartment_id = oci_identity_compartment.example.id
  vcn_id = oci_core_vcn.example.id
  cidr_block = "10.1.2.0/24"
  display_name = "example subnet"
  dns_label = "subnet1"
  security_list_ids = [oci_core_vcn.example.default_security_list_id]
  route_table_id = oci_core_vcn.example.default_route_table_id
  dhcp_options_id = oci_core_vcn.example.default_dhcp_options_id
}

# see https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_route_table
resource "oci_core_default_route_table" "example" {
  manage_default_resource_id = oci_core_vcn.example.default_route_table_id
  route_rules {
    destination = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.example.id
  }
}

# see https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_security_list
resource "oci_core_default_security_list" "example" {
  manage_default_resource_id = oci_core_vcn.example.default_security_list_id
  ingress_security_rules {
    description = "ICMP"
    protocol = "1" # ICMP
    source = "0.0.0.0/0"
    icmp_options {
      type = 3 # Destination Unreachable
      code = 4 # Fragmentation Needed and Don't Fragment was Set
    }
  }
  ingress_security_rules {
    description = "ICMP (from our VCN)"
    protocol = "1" # ICMP
    source = oci_core_vcn.example.cidr_block
    icmp_options {
      type = 3 # Destination Unreachable
    }
  }
  ingress_security_rules {
    description = "SSH"
    protocol = "6" # TCP
    source = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    description = "HTTP"
    protocol = "6" # TCP
    source = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol = "all"
  }
}

# see https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_internet_gateway
resource "oci_core_internet_gateway" "example" {
  compartment_id = oci_identity_compartment.example.id
  vcn_id = oci_core_vcn.example.id
  display_name = "example"
}

data "template_cloudinit_config" "app" {
  part {
    content_type = "text/x-shellscript"
    content = file("provision-app.sh")
  }
}

# see https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_instance
# NB cloud-init uses the https://cloudinit.readthedocs.io/en/latest/topics/datasources/oracle.html datasource.
#    see https://github.com/canonical/cloud-init/blob/612e39087aee3b1242765e7c4f463f54a6ebd723/cloudinit/sources/DataSourceOracle.py
resource "oci_core_instance" "example" {
  compartment_id = oci_identity_compartment.example.id
  availability_domain = data.oci_identity_availability_domain.example.name
  shape = var.vm_shape
  display_name = "example"

  create_vnic_details {
    subnet_id = oci_core_subnet.example.id
    display_name = "primary"
    hostname_label = "example"
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id = var.vm_image_ocid
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = data.template_cloudinit_config.app.rendered
  }
}

# see https://docs.oracle.com/en-us/iaas/Content/Compute/References/serialconsole.htm
# see https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_instance_console_connection
resource "oci_core_instance_console_connection" "example" {
  instance_id = oci_core_instance.example.id
  public_key = var.ssh_public_key
}
