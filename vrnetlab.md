# Multi-vendor scale-out network simulations

Starting with CoreOS
sudo systemctl stop update-engine
sudo systemctl stop update-engine
sudo systemctl disable update-engine
sudo systemctl stop  locksmithd
sudo systemctl disable  locksmithd


Installing k8s
git clone --branch v2.8.1 --depth 1  https://github.com/kubernetes-sigs/kubespray.git
cd kube
cd kubespray/
vi requirements.txt 
# disable ansible 2.7.5
cp -rfp inventory/sample/ inventory/mycluster
declare -a IPS=(10.83.30.251 10.83.30.252 10.83.30.253 10.83.30.254)
CONFIG_FILE=inventory/mycluster/hosts.ini python3 contrib/inventory_builder/inventory.py ${IPS[@]}
sed -i 's/calico/flannel/g' inventory/mycluster/group_vars/k8s-cluster/k8s-cluster.yml
echo -e "docker_insecure_registries:\n   - 0.0.0.0/0" >> inventory/mycluster/group_vars/all/docker.yml
grep -ri max_pod *
inventory/mycluster/group_vars/k8s-cluster/k8s-cluster.yml
# change ipvs -> iptables
vi roles/kubernetes/node/defaults/main.yml 
# enable iptables and max_pods=254
ansible-playbook -i inventory/mycluster/hosts.ini --become --become-user=root -u core cluster.yml

from master node
sudo cp -au /root/.kube ~/.
sudo chown -R core:core ~/.kube/


Install meshnet
cp inventory/mycluster/hosts.ini ~/meshnet-cni/kubespray/ && cd ~/meshnet-cni/kubespray/
./build.sh

Log in one of the master nodes

Install make

```
docker run -ti --rm -v /opt/bin:/out ubuntu:14.04 \
  /bin/bash -c "apt-get update && apt-get -y install make && cp /usr/bin/make /out/make"
```

Download vrnetlab

```
git clone --depth 1 https://github.com/networkop/vrnetlab.git
```

Copy XRV/VMX image into vrnetlab/xrv and do 

```
make
```

setup a k8s-topo and a private docker registry


```
git clone https://github.com/networkop/k8s-topo.git && cd k8s-topo/
kubectl create -f kube-k8s-topo.yml
kubectl create -f examples/docker-registry/docker-registry.yml
```

Get a pointer to docker registry

```
REGISTRY=$(kubectl get service docker-registry -o json | jq -r '.spec.clusterIP'):5000
echo $REGISTRY
10.233.55.236:5000
```

Push the image into docker registry

```
docker image tag vrnetlab/vr-xrv:6.1.2 $REGISTRY/vr-xrv:6.1.2
docker push $REGISTRY/vr-xrv:6.1.2
docker image tag vrnetlab/vr-vmx:17.2R1.13 $REGISTRY/vr-vmx:17.2R1.13
docker push $REGISTRY/vr-vmx:17.2R1.13
```

check that images are in the repo

curl -X GET http://$REGISTRY/v2/_catalog
{"repositories":["vr-vmx","vr-xrv"]}



















=------=======
1000 OSPF routers
kubectl exec -it k8s-topo sh
git pull

