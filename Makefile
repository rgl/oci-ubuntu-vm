all: terraform-init terraform-plan terraform-apply

terraform-init:
	CHECKPOINT_DISABLE=1 \
	TF_LOG=TRACE \
	TF_LOG_PATH=$@.log \
	terraform init
	CHECKPOINT_DISABLE=1 \
	terraform -v

terraform-plan:
	CHECKPOINT_DISABLE=1 \
	TF_LOG=TRACE \
	TF_LOG_PATH=$@.log \
	TF_VAR_oci_tenancy_ocid="$(shell ./get-oci-cli-variable tenancy)" \
	TF_VAR_ssh_public_key="$(shell cat ~/.ssh/id_rsa.pub)" \
	TF_VAR_admin_username="$$USER" \
	terraform plan -out=tfplan

terraform-apply:
	CHECKPOINT_DISABLE=1 \
	TF_LOG=TRACE \
	TF_LOG_PATH=$@.log \
	TF_VAR_oci_tenancy_ocid="$(shell ./get-oci-cli-variable tenancy)" \
	TF_VAR_ssh_public_key="$(shell cat ~/.ssh/id_rsa.pub)" \
	TF_VAR_admin_username="$$USER" \
	terraform apply tfplan

terraform-destroy:
	CHECKPOINT_DISABLE=1 \
	TF_LOG=TRACE \
	TF_LOG_PATH=$@.log \
	TF_VAR_oci_tenancy_ocid="$(shell ./get-oci-cli-variable tenancy)" \
	TF_VAR_ssh_public_key="$(shell cat ~/.ssh/id_rsa.pub)" \
	terraform destroy

terraform-destroy-vm:
	CHECKPOINT_DISABLE=1 \
	TF_LOG=TRACE \
	TF_LOG_PATH=$@.log \
	TF_VAR_oci_tenancy_ocid="$(shell ./get-oci-cli-variable tenancy)" \
	TF_VAR_ssh_public_key="$(shell cat ~/.ssh/id_rsa.pub)" \
	terraform destroy -target oci_core_instance.example
