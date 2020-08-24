[![Docker Pulls](https://img.shields.io/docker/pulls/networkop/k8s-topo.svg)](https://img.shields.io/docker/pulls/networkop/k8s-topo)

# k8s-topo
Arbitrary network topology builder for network simulations inside Kubernetes. Analogous to [docker-topo](https://github.com/networkop/docker-topo). Relies on either [meshnet CNI][meshnet-cni] plugin (default) or [Network Service Mesh](#network-service-mesh).

![](k8s-topo.png)

## Local installation

Make sure you've got python3-dev and build-essential/build-base packages installed and then do

```
pip install git+https://github.com/networkop/k8s-topo.git
```

## Hosted K8s installation

The following manifest will install the `k8s-topo` as a deployment inside the Kubernetes cluster and create all the necessary RBAC rules:

```
kubectl create -f https://raw.githubusercontent.com/networkop/k8s-topo/master/manifest.yml
```

Connect to the k8s-topo pod to get access to the script:

```
kubectl exec -it deployment/k8s-topo sh
```

# Usage

Create a topology definition file. Example below is for a full-mesh 3-node topology.

```yaml
links:
  - endpoints: ["host-1:eth1:12.12.12.1/24", "host-2:eth1:12.12.12.2/24"]
  - endpoints: ["host-1:eth2:13.13.13.1/24", "host-3:eth1:13.13.13.3/24"]
  - endpoints: ["host-2:eth2:23.23.23.2/24", "host-3:eth2:23.23.23.3/24"]
```

Instantiate the topology inside Kubernetes

```bash
k8s-topo --create examples/3node-host.yml
```

List all pods in the topology and their respective locations

```
k8s-topo --show examples/3node-host.yml
host-1@kind-worker
host-2@kind-worker2
host-3@kind-worker2
```

Test connectivity

```bash
kubectl exec -it host-1 -- ping -c 1 12.12.12.2
kubectl exec -it host-1 -- ping -c 1 13.13.13.3
kubectl exec -it host-2 -- ping -c 1 23.23.23.3
```

Destroy the topology

```bash
k8s-topo --destroy examples/3node-host.yml
```

# Visualisation
After the topology has been created, it is possible to view the resulting graph. The `k8s-topo --graph topology_name` command will create a json representation of the topology graph and feed it into a simple D3.js-based web page. 

```
k8s-topo --graph examples/builder/random.yml 
INFO:__main__:D3 graph created
INFO:__main__:URL: http://172.17.0.2:30000

```

This web page, running inside a `k8s-topo` pod, is exposed externally as a NodePort service on port **32000** of every node.

![](random.png)

The colour of vertices represent the node the pod is running on. In this case the topology is spread across 4 different nodes.

# Network Service Mesh

By default all pod connectivity is setup by the [meshnet][meshnet-cni] CNI plugin. Alternatively, connectivity can be setup at runtime by [NSM][nsm]. You first would need to install NSM:

```bash
git clone https://github.com/networkservicemesh/networkservicemesh
cd networkservicemesh
make helm-init
SPIRE_ENABLED=false INSECURE=true FORWARDING_PLANE=kernel make helm-install-nsm 
```

Once installed, any topology definition file can be made "nsm-compliant" by adding a `nsm: true` flag to the top of the file, e.g.:

```yaml
nsm: true
links:
  - endpoints: ["qrtr-1:eth12", "qrtr-2:eth21"]
```

See [nsm-5node.yml](examples/nsm-5node.yml) for another example.



# Private docker registry setup

It's possible to setup a private docker registry to speed up the image pull process and store cEOS images locally:

```
kubectl create -f examples/docker-registry/docker-registry.yml 
```

The private registry can be accessed by its cluster IP:

```
kubectl get service docker-registry
NAME              TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
docker-registry   ClusterIP   10.233.6.223   <none>        5000/TCP   10s
```

The following environment variable will be used by `k8s-topo` script to set the default cEOS image:

```
export CEOS_IMAGE=$(kubectl get service docker-registry -o json | jq -r '.spec.clusterIP'):5000/ceos:4.20.5F
```


Now we can upload the cEOS docker image to this registry:

```
docker import cEOS-4.20.5F-lab.tar.xz ceos:4.20.5F
docker image tag ceos:4.20.5F $CEOS_IMAGE
docker image push $CEOS_IMAGE 
The push refers to repository [10.233.6.223:5000/ceos]
7d3e293b5c56: Pushed 
4.20.5F: digest: sha256:caee130f23d25206ae5a3381c6c716b83fa12122f9a092ba99b09bd106c5f970 size: 529
```

This registry and cEOS image can now be used in the examples below

# Examples 

## Prerequisites

Working K8s cluster with meshnet-CNI installed is required. Refer to [meshnet-cni][meshnet-cni] for setup scripts.

To use [vrnetlab] images, refer to this [guide](./vrnetlab.md)

## 3-node cEOS topology

Topology definition file (cEOS is stored in a private Docker registry)

```yaml
conf_dir: ./config-3node
links:
  - endpoints: ["sw-1:eth1", "sw-2:eth1"]
  - endpoints: ["sw-1:eth2", "sw-3:eth1"]
  - endpoints: ["sw-2:eth2", "sw-3:eth2"]
```

Create the topology

```bash
k8s-topo --create examples/3node-ceos.yml
```

List all pods in the topology

```bash
k8s-topo --show examples/3node-ceos.yml
sw-1@node1
sw-2@node1
sw-3@node1
```

Interact with any pod

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
k8s-topo --destroy examples/3node-ceos.yml
INFO:__main__:All pods have been destroyed successfully
INFO:__main__:
unalias sw-1
unalias sw-2
unalias sw-3
INFO:__main__:All data has been cleaned up from etcd
```

## 20-node random cEOS topology

Generate a random 20-node cEOS topology


```
./examples/builder/builder 20 0 --prefix sw
```

Create the topology (takes about 2 minutes)

```
k8s-topo --create examples/builder/random.yml
```

Enable ip forwarding inside cEOS containers

```
k8s-topo --eif examples/builder/random.yml
```

Generate the topology graph

```
k8s-topo --graph examples/builder/random.yml
INFO:__main__:D3 graph created
INFO:__main__:URL: http://10.83.30.251:30000
```

Check connectivity

```
19/k8s-topo # kubectl exec -it sw-1 bash
/ # export PREFIX=192.0.2
/ # for i in `seq 0 19`; do echo "${PREFIX}.$i =>"  $(ping -c 1 -W 1 ${PREFIX}.$i|grep loss); done
1 packets transmitted, 1 packets received, 0% packet loss
```

Destroy the topology

```bash
k8s-topo --destroy examples/builder/random.yml
```

## 750-node random Quagga router topology

> Note: max limit for random topology builder is 768 nodes, based on the available address space [reserved for documentation](https://tools.ietf.org/html/rfc5737) - '192.0.2.0/24', '198.51.100.0/24', '203.0.113.0/24'

Generate a random 750-node network topology

```
./examples/builder/builder 750 0
Total number of links generated: 749
```

Create the topology (takes about 2 minutes)

```
k8s-topo --create examples/builder/random.yml
```

Check connectivity (repeat for all loopback ranges - '192.0.2.0/24', '198.51.100.0/24', '203.0.113.0/24')

```
/k8s-topo # qrtr-143
/ # export PREFIX=192.0.2
/ # for i in `seq 0 255`; do echo "${PREFIX}.$i =>"  $(ping -c 1 -W 1 ${PREFIX}.$i|grep loss); done
1 packets transmitted, 1 packets received, 0% packet loss
...
```

Destroy the topology

```bash
k8s-topo --destroy examples/builder/random.yml
```



[meshnet-cni]: https://github.com/networkop/meshnet-cni
[vrnetlab]: https://github.com/plajjan/vrnetlab
[nsm]: https://github.com/networkservicemesh/networkservicemesh
