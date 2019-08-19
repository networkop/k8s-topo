VERSION  ?= 0.2.0
DOCKERID ?= networkop
KUBECONFIG ?= /home/null/.kube/kind-config-kind

export KUBECONFIG

.PHONY: build install clean init-wait

build:
	docker build --no-cache -t k8s-topo .
	docker tag k8s-topo $(DOCKERID)/k8s-topo:$(VERSION)
	docker push $(DOCKERID)/k8s-topo:$(VERSION)

install: clean
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