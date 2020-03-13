# Vault Trusted Broker Demo

The code in this demo will build a local Consul cluster with a single Vault server. Additionally, instructions are provided to run a local Kubernetes install with Minikube.

The demo intends to show how Vault can use the Kubernetes Auth Method such that a Vault Agent running on a particular pod can share the value of secrets with another container in the same pod.

## Important Notes

1. **Note:** As of 2nd January 2019, there is an incompatibility between Vagrant 2.2.6 and Virtualbox 6.1.X. Until this incompatibility is fixed, it is recommended to run Vagrant with Virtualbox 6.0.14 instead.

2. **Note:** This demo aims to demonstrate how a Vault Server can be configured to use the Kubernetes Auth Method, and how a Vault Agent can run in a sidecar-container within a Kubernetes Pod to share secrets with an application container, in this case Nginx. It does **not** intend to demonstrate how to build a Vault and Consul deployment according to any recommended architecture, any recommended standard for configuring or deploying onto Kubernetes, nor does it intend to demonstrate any form of best practice with any component. Amongst many other things, you should always enable ACLs, configure TLS and never store your Vault unseal keys or tokens on your Vault server!

## Requirements
* The VMs created by the demo will consume a total of 3GB memory.
* The demo was tested using Vagrant 2.2.6 and Virtualbox 6.0.14


## What is built?

The demo will build the following Virtual Machines:
* **vault-server**: A single Vault server
* **consul-{1-3}-server**: A cluster of 3 Consul servers within a single Datacenter
* **minikube**: A Kubernetes instance, provisioned and managed via Minikube.

## Provisioning scripts
The following provisioning scripts will be run by Vagrant:
* install-consul.sh: Automatically installs and configures Consul 1.6.2 (open source) on each of the consul-{1-3}-server VMs. A flag allows it to configure a consul client on the Vault VM too.
* install-vault.sh: Automatically installs and configures Vault (open source) on the Vault server.

## Additional files
The following additional files are also included and will need to be run manually (see "How to get started"):
* 0-init-vault.sh: Needs to be run as a manual step to initialise and unseal Vault and login as root token. Run on vault-server
* 1-create-k8s-service-account.sh: Needs to be run on the host, in the vagrant working directory. This creates a service account on the minikube cluster.
* 2-create-k8s-auth-method.sh: Needs to be run on the Vault server. Uses values set in a file in the Vagrant working directory created in script 1.
* 3-deploy-to-k8s.sh: Needs to be run on host. Deploys the Pod, which includes both the Nginx Container and the Vault Agent container, onto Kubernetes.
* 4-config-minikube-port-forward: Configures a port forward from the Nginx container to localhost:8080.

## How to get started
Once Vagrant, Virtualbox and Minikube are installed, to get started just run the following command within the code directory:

```
minikube start
```
```
vagrant up
```
Once vagrant has completely finished, run the following to SSH onto the vault server
```
vagrant ssh vault-server
```
Once SSH'd onto vault-server, run the following commands in sequence:
```
cp /vagrant/{0,2}*.sh . ;
chmod 744 {0,2)*.sh ;
./0-init-vault.sh ;
```
This will create a file called vault.txt in the directory you run the script in. The file contains a single Vault unseal key and root token, in case you wish to seal or unseal vault in the future. Of course, in a real-life scenario these files should not be generated automatically and not be stored on the vault server. It will also enable the KV secrets engine at the path secret/, also with the following secrets added to the store `vault kv put secret/myapp/config username=hello password=world`.

Once Vault has been initialised and unsealed, return your terminal back to the vagrant working directory on your host machine and run the following script to create the Kubernetes Service Account
```
./1-create-k8s-service-account
```
Running script 1 will create a file in the vagrant working directory called `kube_sa_info`. Vault will require this in the next step. `vagrant ssh vault-server` to get back onto the Vault server and run the following command:
```
./2-create-k8s-auth-method
```
This will create the Kubernetes Auth Method on Vault. The next step is to then deploy the Pod onto Kubernetes. This can be done by returning the terminal back to the vagrant working directory on the host and running the following command:
```
./3-deploy-to-k8s.sh
```
Shortly after the Pod has been deployed onto Kubernetes, you should then be able to open a port forward onto the Nginx container by running the last script:
```
./4-config-minikube-port-forward.sh
```
This will allow you to view the output from Nginx at localhost:8080.

## Support
No support or guarantees are offered with this code. It is purely a demo.

## Kudos/Thanks
- Consul and Vault configuration scripts are based on Iain Gray's [Vault-DR-Vagrant](https://github.com/iainthegray/vault-dr-vagrant) repo. Those scripts were used in this demo with kind permission.

## Future Improvements
* Use Docker containers instead of VMs for running Vault and Consul.
* Other suggested future improvements very welcome.
