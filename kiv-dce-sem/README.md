# Semestrální práce z KIV/DCE

Tato práce vznikla na základě dvou projektů,  [KIV/DS exercise 3](https://github.com/maxotta/kiv-ds-vagrant/tree/master/demo-3) a projektu kiv-dce-lab-project-k8s, který vnizkl na cvycění tohoto kurzu.
Pro vytvoření infrastruktury pro aplikaci je využíváno technologií Terraform a Ansible. Terraform vygeneruje infrastrukturu pro Ansible, který na jednotlivé virtuální stroje provede delopoy frontedové nebo backendové části projektu. 
Cílem je vytvořit infrastrukturu s jedním frontendem a několika parametrem upravitelnými počty nodů.


## Terraform
Terraform se stará o vytváření infrasturktury podle postupu uvedeného v souborech .tfvars, variables.tf a terraform.tf. Projekt vychází z projektu kiv-dce-lab-project-k8s. Skript vytvoří master-balancer a slave-node podle specifikace. Po vytvoření virtuálů jsou nakopírovány soubory z init-scripts a vykonány na cílových nodech. Teraform následně využívá funkci OUTPUT a předem vytvořené šablony pro uložení ip-adress pro následné využití Ansiblem.

## Ansible
Ansible je definován promocí souborů ve formátu YAML. 
V rámci tohoto projektu se soubory pro Ansible nachází ve složce Ansible. Pro běh ještě využívá seznam nodů uložených v dynamic_inventories/inventory.

Při instalaci backendu a frontendu se u obou na začátku nakopírují soubory z localhostu na cílový server. Následě je na frontend a backend nainstalován docker a jsou v něm spuštěné příslušné docker-immage.

Ansible nemá ode mě žádné parametry pro kofiguraci uživatelem zvenčí. Očekává se jen, že existuje inventory a uživatel nodeadm s přávy SUDO, který bude mít přístup odkudkoliv s klíčem vygenerovaným v KIV/DCE.

### Parametry
Pro správný běh je potřeba v terraform.tfvars specifikovat hodnoty one_username a one_password. One password je token, který se nechá získat jako API Token v OpenNebule.

  nodes_count - je parametr, který ovlivňuje počet backendů pro běh aplikace.



## Příkazy pro rozchození projektu
```
cd sem/
terraform init
terraform plan
terraform apply
yes
'''
změnit ip adresy v souboru /frontend/config/backend-upstream na ip adresy vytvořených slave nodoes
'''
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i dynamic_inventories/inventory ansible/main_play.yml

```
