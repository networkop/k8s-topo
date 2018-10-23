# k8s-topo
Arbitray network topology builder for network simulations inside Kubernetes. Analogous to [docker-topo](https://github.com/networkop/arista-ceos-topo). Relies on [meshnet CNI][meshnet-cni] plugin.

## TODO

0. Installation instructions
1. Add more examples
2. Add K8S setup/teardown instructions
3. Add logging
4. Save/archive action for device configs
5. Arbitrary port number publishing


## Local installation

Make sure you've got python3-dev and build-essential/build-base packages installed and then do

```
pip install git+https://github.com/networkop/k8s-topo.git
```

## Hosted K8s installation

Build the docker image and push it to the docker hub.

```
build.sh <dockerhub_username>
```

Update the image name in `kube-k8s-topo.yml` to match your dockerhub username and do:

```
kubectl create -f kube-k8s-topo.yml
```

# Examples 

## Prerequisites

Working K8s cluster with meshnet-CNI and externally accessible private etcd cluster. Refer to [meshnet-cni][meshnet-cni] for setup scripts.

## 3-node alpine linux topology

Topology definition file (alpine image is used whenever string `host` is matched in device name)

```yaml
etcd_port: 32781
links:
  - endpoints: ["host-1:eth1:12.12.12.1/24", "host-2:eth1:12.12.12.2/24"]
  - endpoints: ["host-1:eth2:13.13.13.1/24", "host-3:eth1:13.13.13.3/24"]
  - endpoints: ["host-2:eth2:23.23.23.2/24", "host-3:eth2:23.23.23.3/24"]
```

Create the topology

```bash
./bin/k8s-topo --create examples/3node-host.yml
```

Destroy the topology

```bash
./bin/k8s-topo --destroy examples/3node-host.yml
```

## 3-node cEOS topology

Topology definition file (cEOS is stored in a private Docker registry)

```yaml
etcd_port: 32781
ceos_image: 172.16.0.46:5000/ceos:4.20.0F
conf_dir: ./config-3node
links:
  - endpoints: ["sw-1:eth1", "sw-2:eth1"]
  - endpoints: ["sw-1:eth2", "sw-3:eth1"]
  - endpoints: ["sw-2:eth2", "sw-3:eth2"]
```

Create the topology

```bash
./bin/k8s-topo --create examples/3node-ceos.yml
INFO:__main__:All data has been uploaded to etcd
INFO:__main__:All pods have been created successfully
INFO:__main__:
alias sw-1='kubectl exec -it sw-1 Cli'
alias sw-2='kubectl exec -it sw-2 Cli'
alias sw-3='kubectl exec -it sw-3 Cli'
```

List all pods in the topology

```bash
./bin/k8s-topo --list examples/3node-ceos.yml
sw-1@kube-node-1
sw-2@kube-node-2
sw-3@kube-node-1

```

Destroy the topology

```bash
./bin/k8s-topo --destroy examples/3node-ceos.yml
INFO:__main__:All pods have been destroyed successfully
INFO:__main__:
unalias sw-1
unalias sw-2
unalias sw-3
INFO:__main__:All data has been cleaned up from etcd
```


## 200-node Quagga router topology

Install required prerequisites:

```
pip install -r examples/builder/requirements.txt 
```

Generate a ranom 200-node network topology 199 links

```
./examples/builder/builder 200 0
Total number of links generated: 199
```

Create the topology (takes about 20 seconds)

```
./bin/k8s-topo --create examples/builder/RANDTOPO.yml
```



[meshnet-cni]: https://github.com/networkop/meshnet-cni