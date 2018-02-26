PACKERBIN ?= $(shell which packer-io || which packer)
TERRAFORMBIN ?= $(shell which terraform)

all: coreos

.terraform:
	@$(TERRAFORMBIN) init

terraform.tfstate: .terraform
	@$(TERRAFORMBIN) apply -var region=$(OS_REGION_NAME) > /dev/null 2>&1

coreos: terraform.tfstate
	$(PACKERBIN) build -var region=$(OS_REGION_NAME) \
	           	  -var ext_net_id=$(shell $(TERRAFORMBIN) output ext_net_id) \
				  packer.json
