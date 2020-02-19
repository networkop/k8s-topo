VERSION  ?= 0.2.0
DOCKERID ?= networkop
KUBECONFIG ?= $(shell ${GOPATH}/kind get kubeconfig-path --name="kind")
GOPATH = ${HOME}/go/bin

export KUBECONFIG

.PHONY: build install clean init-wait release help

# From: https://gist.github.com/klmr/575726c7e05d8780505a
.DEFAULT_GOAL := help
help:
	@echo "$$(tput sgr0)";sed -ne"/^## /{h;s/.*//;:d" -e"H;n;s/^## //;td" -e"s/:.*//;G;s/\\n## /---/;s/\\n/ /g;p;}" ${MAKEFILE_LIST}|awk -F --- -v n=$$(tput cols) -v i=15 -v a="$$(tput setaf 6)" -v z="$$(tput sgr0)" '{printf"%s%*s%s ",a,-i,$$1,z;m=split($$2,w," ");l=n-i;for(j=1;j<=m;j++){l-=length(w[j])+1;if(l<= 0){l=n-i-length(w[j])-1;printf"\n%*s ",-i," ";}printf"%s ",w[j];}printf"\n";}'

## Build the k8s-topo image
build: 
	docker build --no-cache -t k8s-topo .
	docker tag k8s-topo $(DOCKERID)/k8s-topo:$(VERSION)

## Publish the k8s-topo docker image
release: 
	docker push $(DOCKERID)/k8s-topo:$(VERSION)

## Install k8s-topo on top of meshnet
install: clean 
	kubectl wait --for condition=Ready pod -l name=meshnet -n meshnet   
	kubectl apply -f manifest.yml

## Apply k8s-topo manifest
install-nsm: clean 
	kubectl apply -f manifest.yml

## Delete k8s-topo deployment
clean:  
	-kubectl delete -f manifest.yml

## Build and publish init-wait image
init-wait: 
	docker build -f init-wait/Dockerfile -t init-wait .
	docker tag init-wait $(DOCKERID)/init-wait
	docker push $(DOCKERID)/init-wait

## Build a quagga router image
quagga-rtr-build: 
	docker build -f examples/quagga-rtr/Dockerfile -t qrtr .
	
## Release a quagga router image
quagga-rtr-release:
	docker tag qrtr $(DOCKERID)/qrtr
	docker push $(DOCKERID)/qrtr

## Create a docker registry deployment
registry: 
	kubectl apply -f examples/docker-registry/docker-registry.yml

## Connect to a running k8s-topo pod
login: 
	kubectl wait --for condition=Ready pod -l app=k8s-topo  
	kubectl exec -it deployment/k8s-topo sh