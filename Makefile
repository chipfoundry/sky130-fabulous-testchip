PDK ?= sky130A
PDK_COMMIT ?= d815bb30c9afdf9e264c276a8a2b533108dea3d0

# Get the fabric names
FABRICS :=  $(patsubst fabrics/%,%,$(wildcard fabrics/*)) 

FABRICS_OPENROAD := $(addsuffix -openroad,$(FABRICS))
FABRICS_KLAYOUT := $(addsuffix -klayout,$(FABRICS))
FABRICS_COPY := $(addsuffix -copy,$(FABRICS))

all: $(FABRICS)
.PHONY: all

$(FABRICS):
	librelane --pdk ${PDK} fabrics/$@/config.yaml --save-views-to fabrics/$@/macro/${PDK}/
.PHONY: $(FABRICS)

$(FABRICS_OPENROAD):
	librelane --pdk ${PDK} fabrics/$(subst -openroad,,$@)/config.yaml --last-run --flow OpenInOpenROAD
.PHONY: $(FABRICS_OPENROAD)

$(FABRICS_KLAYOUT):
	librelane --pdk ${PDK} fabrics/$(subst -klayout,,$@)/config.yaml --last-run --flow OpenInKLayout
.PHONY: $(FABRICS_KLAYOUT)

$(FABRICS_COPY):
	# Copy fabric database
	mkdir -p user_designs/fabrics/$(subst -copy,,$@)/macro/${PDK}/
	cp -R fabrics/$(subst -copy,,$@)/macro/${PDK}/fabulous/ user_designs/fabrics/$(subst -copy,,$@)/macro/${PDK}/
	cp fabrics/$(subst -copy,,$@)/constraints.pcf user_designs/fabrics/$(subst -copy,,$@)/constraints.pcf
.PHONY: $(FABRICS_COPY)

clone-pdk:
	ciel enable $(PDK_COMMIT) --pdk-family $(PDK)
.PHONY: clone-pdk

librelane:
	librelane --pdk-root ${PDK_ROOT} --pdk ${PDK} --manual-pdk librelane/config.yaml --save-views-to final/
.PHONY: librelane

librelane-noklayoutdrc:
	librelane --pdk-root ${PDK_ROOT} --pdk ${PDK} --manual-pdk librelane/config.yaml --skip KLayout.DRC --save-views-to final/
.PHONY: librelane-noklayoutdrc

librelane-openroad:
	librelane --pdk-root ${PDK_ROOT} --pdk ${PDK} --manual-pdk librelane/config.yaml --last-run --flow OpenInOpenROAD
.PHONY: librelane-openroad

librelane-klayout:
	librelane --pdk-root ${PDK_ROOT} --pdk ${PDK} --manual-pdk librelane/config.yaml --last-run --flow OpenInKLayout
.PHONY: librelane-klayout
