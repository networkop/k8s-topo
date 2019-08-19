VERSION  ?= 0.2.0
DOCKERID ?= networkop
KUBECONFIG = $(shell ${GOPATH}/kind get kubeconfig-path --name="kind")
GOPATH = ${HOME}/go/bin

export KUBECONFIG

.PHONY: build install clean init-wait release

build:
	docker build --no-cache -t k8s-topo .
	docker tag k8s-topo $(DOCKERID)/k8s-topo:$(VERSION)

release:
	docker push $(DOCKERID)/k8s-topo:$(VERSION)

install: clean
	kubectl wait --for condition=Ready pod -l name=meshnet -n meshnet   
	kubectl apply -f manifest.yml

clean: 
	-kubectl delete -f manifest.yml

init-wait:
	docker build -f init-wait/Dockerfile -t init-wait .
	docker tag init-wait $(DOCKERID)/init-wait
	docker push $(DOCKERID)/init-wait

quagga-rtr:
	docker build -f examples/quagga-rtr/Dockerfile -t qrtr .
	docker tag qrtr $(DOCKERID)/qrtr
	docker push $(DOCKERID)/qrtr

registry:
	kubectl apply -f examples/docker-registry/docker-registry.yml

login:
	kubectl wait --for condition=Ready pod -l app=k8s-topo  
	kubectl exec -it deployment/k8s-topo sh