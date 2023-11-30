terraform init
terraform plan
terraform apply

export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i dynamic_inventories/inventory ansible/main_play.yml



