MAKEFILE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

PDK_ROOT ?= ~/.ciel
PDK ?= sky130A
TOP ?= logo_fabulous

all: logo drc
.PHONY: all

logo:
	python3 script/make_gds.py image/${TOP}.png gds/${TOP}.gds.gz --cellname ${TOP} --merge --pixel-size 0.3 --width 270 --height 270 --foreground "71/20" \
	--boundary "235/4" "67/10" "62/24" "105/52" "107/24" "112/4" "117/4" 
.PHONY: logo

drc:
	PDK_ROOT=${PDK_ROOT} PDK=${PDK} klayout -b -zz -r ${PDK_ROOT}/${PDK}/libs.tech/klayout/drc/${PDK}_mr.drc -rd input=gds/${TOP}.gds.gz -rd report=report.lyrdb
.PHONY: drc
