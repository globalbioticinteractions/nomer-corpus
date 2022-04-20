SHELL=/bin/bash
BUILD_DIR=$(PWD)/target
STAMP=$(BUILD_DIR)/.stamp

PRESTON_VERSION:=0.3.8
PRESTON_URL:=https://github.com/bio-guoda/preston/releases/download/$(PRESTON_VERSION)/preston.jar
PRESTON_JAR:=$(BUILD_DIR)/preston.jar
PRESTON:=java -jar $(BUILD_DIR)/preston.jar
PRESTON_DATASET_DIR:=${BUILD_DIR}/data

NOMER_VERSION:=0.2.5
NOMER_URL:=https://github.com/globalbioticinteractions/nomer/releases/download/$(NOMER_VERSION)/nomer.jar
NOMER_JAR:=$(BUILD_DIR)/nomer.jar
NOMER:=java -jar $(NOMER_JAR)

ZENODO_UPLOAD_URL:=https://raw.githubusercontent.com/jhpoelen/zenodo-upload/master/zenodo_upload.sh
ZENODO_UPLOAD:=$(BUILD_DIR)/zenodo_upload.sh
ZENODO_DEPOSIT:=6473194

TAXON_GRAPH_URL_PREFIX:=https://zenodo.org/record/6127573/files

DIST_DIR:=$(PWD)/dist

CURL:=curl --silent -L

.PHONY: all clean update package

all: update package

clean:
	rm -rf $(BUILD_DIR)/* $(DIST_DIR)/* data/*

$(STAMP):
	mkdir -p $(BUILD_DIR) && touch $@

$(PRESTON_JAR): $(STAMP)
	$(CURL) $(PRESTON_URL) > $(PRESTON_JAR)

clone: $(PRESTON_JAR)
	$(PRESTON) ls --data-dir=$(PRESTON_DATASET_DIR) --remote $(TAXON_GRAPH_URL_PREFIX) | grep hash | $(PRESTON) cat --data-dir=$(PRESTON_DATASET_DIR) --remote $(TAXON_GRAPH_URL_PREFIX) > /dev/null

track: $(NOMER_JAR) $(PRESTON_JAR)
	$(NOMER) properties | grep -o -P '(http|ftp)([^!])*' | sort | uniq > $(BUILD_DIR)/aliases.txt
	echo -e "$(PRESTON_URL)\n$(NOMER_URL)\n$(ZENODO_UPLOAD_URL)" >> $(BUILD_DIR)/aliases.txt
	cat $(BUILD_DIR)/aliases.txt | xargs $(PRESTON) track --data-dir=$(PRESTON_DATASET_DIR)

update: clone track
	mkdir -p $(DIST_DIR)
	$(PRESTON) cp --data-dir=$(PRESTON_DATASET_DIR) -p directoryDepth0 $(DIST_DIR)

$(NOMER_JAR): $(STAMP)
	$(CURL) $(NOMER_URL) > $(NOMER_JAR)

$(ZENODO_UPLOAD): $(STAMP)
	$(CURL) $(ZENODO_UPLOAD_URL) >  $(ZENODO_UPLOAD)

package: update $(ZENODO_UPLOAD)
	cd $(DIST_DIR) && ls -1 | xargs -L1 bash $(ZENODO_UPLOAD) $(ZENODO_DEPOSIT)
