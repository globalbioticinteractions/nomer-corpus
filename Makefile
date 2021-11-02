SHELL=/bin/bash
BUILD_DIR=target
STAMP=$(BUILD_DIR)/.$(BUILD_DIR)stamp

PRESTON_VERSION:=0.3.1
PRESTON_JAR:=$(BUILD_DIR)/preston.jar
PRESTON:=java -jar $(BUILD_DIR)/preston.jar
PRESTON_DATASET_DIR:=${BUILD_DIR}/data

NOMER_VERSION:=0.2.5
NOMER_JAR:=$(BUILD_DIR)/nomer.jar
NOMER:=java -jar $(NOMER_JAR)

ZENODO_UPLOAD:=$(BUILD_DIR)/zenodo_upload.sh
ZENODO_DEPOSIT:=5639794

TAXON_GRAPH_URL_PREFIX:=https://zenodo.org/record/5021869/files

DIST_DIR:=dist

.PHONY: all clean update package

all: update package

clean:
	rm -rf $(BUILD_DIR)/* $(DIST_DIR)/* data/*

$(STAMP):
	mkdir -p $(BUILD_DIR) && touch $@

$(PRESTON_JAR): $(STAMP)
	curl --silent "https://github.com/bio-guoda/preston/releases/download/$(PRESTON_VERSION)/preston.jar" > $(PRESTON_JAR)

clone: $(PRESTON_JAR)
	$(PRESTON) clone --data-dir=$(PRESTON_DATASET_DIR) $(TAXON_GRAPH_URL_PREFIX)

track: $(NOMER_JAR) $(PRESTON_JAR)
	$(NOMER) properties | grep -o -P 'http([^!])*' | sort | uniq | xargs $(PRESTON) track --data-dir=$(PRESTON_DATASET_DIR)

update: clone track
	mkdir -p $(DIST_DIR)
	$(PRESTON) cp --data-dir=$(PRESTON_DATASET_DIR) -p directoryDepth0 $(DIST_DIR)

$(NOMER_JAR): $(STAMP)
	curl --silent "https://github.com/globalbioticinteractions/nomer/releases/download/$(NOMER_VERSION)/nomer.jar" > $(NOMER_JAR)

$(ZENODO_UPLOAD): $(STAMP)
	curl --silent "https://raw.githubusercontent.com/jhpoelen/zenodo-upload/master/zenodo_upload.sh" >  $(ZENODO_UPLOAD)

package: update $(ZENODO_UPLOAD)
	cd $(DIST_DIR)
	ls -1 | xargs -L1 bash zenodo_upload.sh $(ZENODO_DEPOSIT)
