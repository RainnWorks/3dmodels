SCAD := velux_bridge_enclosure.scad
CAPSCAD := velux_bridge_enclosure_captive_usb.scad
# The arm64 Qt build aborts on this host because its runtime expects NEON.
# The universal app's x86_64 slice works reliably under Rosetta.
OSCAD := arch -x86_64 /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
PREVDIR := previews
EXPDIR := export
CAPEXPDIR := export-captive-usb
RENDER := scripts/render_preview.py
VALIDATION_RENDER := scripts/render_validation.py
PYTHON := python3

PARTS := base lid fit_test
VIEWS := assembly layout top bottom rear base lid fit_test

PREVIEWS := $(addprefix $(PREVDIR)/,$(addsuffix .png,$(VIEWS)))
STLS := $(addprefix $(EXPDIR)/,$(addsuffix .stl,$(PARTS)))
TMFS := $(addprefix $(EXPDIR)/,$(addsuffix .3mf,$(PARTS)))
CAP_PARTS := base lid
CAP_STLS := $(addprefix $(CAPEXPDIR)/,$(addsuffix .stl,$(CAP_PARTS)))
CAP_TMFS := $(addprefix $(CAPEXPDIR)/,$(addsuffix .3mf,$(CAP_PARTS)))
CAP_PREVIEW := $(PREVDIR)/captive_usb_assembly.png
PAIR_PREVIEWS := $(PREVDIR)/standard_usb_pair.png $(PREVDIR)/captive_usb_pair.png
VALIDATION_PREVIEWS := $(PREVDIR)/fit_validation.png $(PREVDIR)/fit_validation_captive_usb.png

.DEFAULT_GOAL := all
.NOTPARALLEL:
.PHONY: all renders exports captive_usb test clean open $(PARTS)

all: renders exports
renders: $(PREVIEWS) $(PAIR_PREVIEWS) $(VALIDATION_PREVIEWS)
exports: $(STLS) $(TMFS)
captive_usb: $(CAP_STLS) $(CAP_TMFS) $(CAP_PREVIEW)
test: exports captive_usb $(VALIDATION_PREVIEWS)
	$(PYTHON) -m unittest discover -s tests -v

$(PARTS): %: $(PREVDIR)/%.png $(EXPDIR)/%.stl $(EXPDIR)/%.3mf

$(PREVIEWS): $(STLS) $(RENDER) | $(PREVDIR)
	$(PYTHON) $(RENDER) --view $(@F:.png=) --output $@

$(EXPDIR)/%.stl: $(SCAD) | $(EXPDIR)
	$(OSCAD) -o $@ -D 'render_part="$*"' $(SCAD)

$(EXPDIR)/%.3mf: $(SCAD) | $(EXPDIR)
	$(OSCAD) -o $@ -D 'render_part="$*"' $(SCAD)

$(CAPEXPDIR)/%.stl: $(CAPSCAD) $(SCAD) | $(CAPEXPDIR)
	$(OSCAD) -o $@ -D 'render_part="$*"' $(CAPSCAD)

$(CAPEXPDIR)/%.3mf: $(CAPSCAD) $(SCAD) | $(CAPEXPDIR)
	$(OSCAD) -o $@ -D 'render_part="$*"' $(CAPSCAD)

$(CAP_PREVIEW): $(CAP_STLS) $(RENDER) | $(PREVDIR)
	$(PYTHON) $(RENDER) --variant captive_usb --view assembly --output $@

$(PREVDIR)/standard_usb_pair.png: $(EXPDIR)/base.stl $(EXPDIR)/lid.stl $(RENDER) | $(PREVDIR)
	$(PYTHON) $(RENDER) --variant standard --view pair --output $@

$(PREVDIR)/captive_usb_pair.png: $(CAP_STLS) $(RENDER) | $(PREVDIR)
	$(PYTHON) $(RENDER) --variant captive_usb --view pair --output $@

$(PREVDIR)/fit_validation.png: $(STLS) $(CAP_STLS) $(VALIDATION_RENDER) tests/test_fit.py | $(PREVDIR)
	$(PYTHON) $(VALIDATION_RENDER) --variant standard --output $@

$(PREVDIR)/fit_validation_captive_usb.png: $(STLS) $(CAP_STLS) $(VALIDATION_RENDER) tests/test_fit.py | $(PREVDIR)
	$(PYTHON) $(VALIDATION_RENDER) --variant captive_usb --output $@

$(PREVDIR) $(EXPDIR) $(CAPEXPDIR):
	mkdir -p $@

open: $(PREVDIR)/assembly.png
	open $(PREVDIR)/assembly.png

clean:
	rm -rf $(PREVDIR) $(EXPDIR) $(CAPEXPDIR)
