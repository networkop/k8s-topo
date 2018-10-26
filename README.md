# k8s-topo
Arbitray network topology builder for network simulations inside Kubernetes. Analogous to [docker-topo](https://github.com/networkop/arista-ceos-topo). Relies on [meshnet CNI][meshnet-cni] plugin.

## TODO

0. Installation instructions
1. Add more examples
2. Add K8S setup/teardown instructions
3. Add logging
4. Save/archive action for device configs
5. Arbitrary port number publishing
6. Add visualisation explanation
7. Create correlation between node name and index

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

# Visualisation
Every time a new topology is created with `k8s-topo --create topology_name` command, it's possible to view a visual graph, representing this topology. Using `k8s-topo --graph topology_name` after the topology has been created, will create a json representation of a graph and feed it into a simple D3.js-based web page. A NodePort service exposes internal web server, running inside a `k8s-topo` pod, on port **32080** of every node.

![](random.png)

The colour of vertices represent the node the pod is running on. In these case there are 4 nodes in total.

# Private docker registry setup

It's possible to setup a private docker registry with the following command:

```
kubectl create -f examples/docker-registry/docker-registry.yml 
```

The private registry can be accessed by its cluster IP:

```
kubectl get service docker-registry
NAME              TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
docker-registry   ClusterIP   10.233.6.223   <none>        5000/TCP   10s
```

Now we can upload any docker image to this registry:

```
docker import cEOS-4.20.5F-lab.tar.xz ceos:4.20.5F
docker image tag ceos:4.20.5F 10.233.6.223:5000/ceos:4.20.5F
docker image push 10.233.6.223:5000/ceos:4.20.5F 
The push refers to repository [10.233.6.223:5000/ceos]
7d3e293b5c56: Pushed 
4.20.5F: digest: sha256:caee130f23d25206ae5a3381c6c716b83fa12122f9a092ba99b09bd106c5f970 size: 529
```

This registry and cEOS image can now be used in the examples below

```
export CEOS_IMAGE=$(kubectl get service docker-registry -o json | jq -r '.spec.clusterIP'):5000/ceos:4.20.5F
```

# Examples 

## Prerequisites

Working K8s cluster with meshnet-CNI and externally accessible private etcd cluster. Refer to [meshnet-cni][meshnet-cni] for setup scripts.

## 3-node alpine linux topology

Topology definition file (alpine image is used whenever string `host` is matched in device name)

```yaml
etcd_port: 32379
links:
  - endpoints: ["host-1:eth1:12.12.12.1/24", "host-2:eth1:12.12.12.2/24"]
  - endpoints: ["host-1:eth2:13.13.13.1/24", "host-3:eth1:13.13.13.3/24"]
  - endpoints: ["host-2:eth2:23.23.23.2/24", "host-3:eth2:23.23.23.3/24"]
```

Create the topology

```bash
./bin/k8s-topo --create examples/3node-host.yml
```

List all pods in the topology

```
./bin/k8s-topo --show examples/3node-host.yml
host-1@node2
host-2@node2
host-3@node1
```

Test connectivity

```bash
kubectl exec -it host-1 -- ping -c 1 12.12.12.2
kubectl exec -it host-1 -- ping -c 1 13.13.13.3
kubectl exec -it host-2 -- ping -c 1 23.23.23.3
```

Destroy the topology

```bash
./bin/k8s-topo --destroy examples/3node-host.yml
```

## 3-node cEOS topology

Topology definition file (cEOS is stored in a private Docker registry)

```yaml
etcd_port: 32379
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
./bin/k8s-topo --show examples/3node-ceos.yml
sw-1@node1
sw-2@node1
sw-3@node1
```

Interact with a pod

```
/k8s-topo # sw-1
sw-1>en
sw-1#sh run 
! Command: show running-config
! device: sw-1 (cEOSSim, EOS-4.20.5F)
!
transceiver qsfp default-mode 4x10G
!
hostname sw-1
!
spanning-tree mode mstp
!
no aaa root
!
interface Ethernet1
   no switchport
   ip address 12.12.12.1/24
!
interface Ethernet2
   no switchport
   ip address 13.13.13.1/24
!
no ip routing
!
end
sw-1#ping  12.12.12.2
PING 12.12.12.2 (12.12.12.2) 72(100) bytes of data.
80 bytes from 12.12.12.2: icmp_seq=1 ttl=64 time=33.9 ms
80 bytes from 12.12.12.2: icmp_seq=2 ttl=64 time=10.2 ms
80 bytes from 12.12.12.2: icmp_seq=3 ttl=64 time=13.3 ms
80 bytes from 12.12.12.2: icmp_seq=4 ttl=64 time=13.2 ms
80 bytes from 12.12.12.2: icmp_seq=5 ttl=64 time=9.28 ms

--- 12.12.12.2 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 122ms
rtt min/avg/max/mdev = 9.280/16.004/33.929/9.105 ms, ipg/ewma 30.596/24.630 ms
sw-1#
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

Generate a ranom 200-node, network topology with 10000 links

```
./examples/builder/builder 200 801
Total number of links generated: 1000
```

Create the topology (takes about 20 seconds)

```
./bin/k8s-topo --create examples/builder/random.yml
```

Check connectivity

```
/k8s-topo # qrtr-143
/ # for i in `seq 1 200`; do ping -c 1 -W 1 198.51.100.$i|grep loss; done
1 packets transmitted, 1 packets received, 0% packet loss
...
```

Destroy the topology

```bash
./bin/k8s-topo --destroy examples/builder/random.yml
```


# Troubleshooting

## Check the contents of etcd database

```
ETCD_HOST=$(kubectl get service etcd-client -o json |  jq -r '.spec.clusterIP')
ENDPOINTS=$ETCD_HOST:2379
ETCDCTL_API=3 etcdctl --endpoints=$ENDPOINTS get --prefix=true ""
ETCDCTL_API=3 etcdctl --endpoints=$ENDPOINTS get --prefix=true "/sw-9"
```

[meshnet-cni]: https://github.com/networkop/meshnet-cni