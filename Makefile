PDK ?= sky130A
#PDK ?= ihp-sg13g2

# Get the fabric names
FABRICS :=  $(patsubst fabrics/%,%,$(wildcard fabrics/*)) 

FABRICS_OPENROAD := $(addsuffix -openroad,$(FABRICS))
FABRICS_KLAYOUT := $(addsuffix -klayout,$(FABRICS))

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

librelane:
	librelane --pdk-root ${PDK_ROOT} --pdk ${PDK} --manual-pdk librelane/config.yaml
.PHONY: librelane

librelane-noklayoutdrc:
	librelane --pdk-root ${PDK_ROOT} --pdk ${PDK} --manual-pdk librelane/config.yaml --skip KLayout.DRC
.PHONY: librelane-noklayoutdrc

librelane-openroad:
	librelane --pdk-root ${PDK_ROOT} --pdk ${PDK} --manual-pdk librelane/config.yaml --last-run --flow OpenInOpenROAD
.PHONY: librelane-openroad

librelane-klayout:
	librelane --pdk-root ${PDK_ROOT} --pdk ${PDK} --manual-pdk librelane/config.yaml --last-run --flow OpenInKLayout
.PHONY: librelane-klayout
