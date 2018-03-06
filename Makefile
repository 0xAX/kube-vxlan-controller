USER = aialferov
PROJECT = kube-vxlan-controller
VERSION = $(shell $(MAKE) version)

REBAR = ./rebar3

PREFIX = usr/local

BIN_DIR = bin
BIN_PATH = $(DEST_DIR)/$(PREFIX)/$(BIN_DIR)
BIN_PATH_IN = $(shell $(REBAR) path --bin)

BUILD_DIR = _build
BUILD_DIR_IMAGE = $(BUILD_DIR)/image

CONFIG = \
	--server=https://api.k8s.nce-01.fra-01.eu.cennso.net \
	--namespace-file=pki/namespace \
	--ca-cert-file=pki/ca.pem \
	--token-file=pki/token \
	--vxlan-config-name=kube-vxlan-controller \
	--agent-container-name=vxlan-controller-agent

all:
	$(REBAR) compile
	$(REBAR) unlock

shell:
	$(REBAR) shell
	$(REBAR) unlock

run:
	$(BIN_PATH_IN)/$(PROJECT) $(CONFIG)

version:
	@$(BIN_PATH_IN)/$(PROJECT) version | cut -d" " -f2

install:
	mkdir -p $(BIN_PATH)
	install -p $(BIN_PATH_IN)/$(PROJECT) $(BIN_PATH)

install-check:
	mkdir -p $(BIN_PATH)
	install -p scripts/check.sh $(BIN_PATH)/$(PROJECT)-check

uninstall:
	rm -f $(BIN_PATH)/$(PROJECT)
	rmdir -p $(BIN_PATH) 2> /dev/null || true

uninstall-check:
	rm -f $(BIN_PATH)/$(PROJECT)-check
	rmdir -p $(BIN_PATH) 2> /dev/null || true

clean:
	$(REBAR) clean -a
	$(REBAR) unlock

distclean: clean
	rm -rf $(BUILD_DIR)

docker-build: all
	$(MAKE) install DEST_DIR=$(BUILD_DIR_IMAGE) PREFIX=
	install -p -m 644 Dockerfile $(BUILD_DIR_IMAGE)
	docker build $(BUILD_DIR_IMAGE) -t $(USER)/$(PROJECT):$(VERSION)
	docker tag $(USER)/$(PROJECT):$(VERSION) $(USER)/$(PROJECT):latest

docker-push:
	docker push $(USER)/$(PROJECT):$(VERSION)
	docker push $(USER)/$(PROJECT):latest

docker-run:
	docker run --name $(PROJECT) --rm -it -v ${PWD}/pki:/pki \
		$(USER)/$(PROJECT):$(VERSION) $(PROJECT) $(CONFIG)

docker-start:
	docker run --name $(PROJECT) --rm -itd -v ${PWD}/pki:/pki \
		$(USER)/$(PROJECT):$(VERSION) $(PROJECT) $(CONFIG)

docker-stop:
	docker stop $(PROJECT) -t0

docker-attach:
	docker attach $(PROJECT) -it

docker-clean:
	docker images -qf dangling=true | xargs docker rmi
