# =============================================================================
#  nametag_back.scad -- render previews + export a tag for every name
# =============================================================================
#  Usage:
#    make            # previews + one STL per name
#    make renders    # just the PNGs. previews/head.png is the one to look at
#    make exports    # just the STLs, already rolled letters-down for the bed
#    make test       # geometry tests -- does it grip, is it one body, does it
#                    #   clear the glass, and what is the printer left holding
#    make falsify    # break the model on purpose and check the tests notice
#    make overhangs  # which way up does it print? five orientations, measured
#    make trade      # what the sprung arm costs, swept
#    make open       # render + open the head-on sheet (macOS)
#    make clean      # remove generated previews/ and export/
#
#  This model INCLUDES ../glass-name-tag/nametag.scad and reuses that
#  directory's measure.py and bridges.py as modules, so both are dependencies
#  of everything here. The unit of export is a NAME, not a part, so the
#  per-name work lives in build.py rather than in pattern rules.
# =============================================================================

SCAD    := nametag_back.scad
V1      := ../glass-name-tag
PREVDIR := previews
EXPDIR  := export
PY      := python3

NAMES   := $(shell sed -e '/^[[:space:]]*$$/d' names.txt)
STLS    := $(addprefix $(EXPDIR)/,$(addsuffix .stl,$(NAMES)))
SHEETS  := $(PREVDIR)/head.png $(PREVDIR)/all.png $(PREVDIR)/stack.png \
           $(PREVDIR)/print.png $(PREVDIR)/section.png $(PREVDIR)/onglass.png
DEPS    := $(SCAD) place.py names.txt $(V1)/nametag.scad $(V1)/measure.py \
           $(V1)/bridges.py

.DEFAULT_GOAL := all
.PHONY: all renders exports test falsify overhangs trade open clean

all: renders exports

renders: $(SHEETS)
exports: $(STLS)

$(PREVDIR) $(EXPDIR):
	@mkdir -p $@

# previews.py builds the lot in one pass -- the contact sheet needs every name
# rendered anyway, so per-file rules would only re-run OpenSCAD more often.
$(SHEETS): $(DEPS) previews.py | $(PREVDIR)
	@$(PY) previews.py

$(STLS): $(DEPS) build.py | $(EXPDIR)
	@$(PY) build.py

test:
	@$(PY) tests/run.py

# A test that cannot fail reads as coverage and is worse than no test.
falsify:
	@$(PY) falsify.py

# This part does NOT print unsupported, and these two say how much it costs
# rather than argue about it.
overhangs: | $(EXPDIR)
	@$(PY) overhangs.py Justine

trade: | $(EXPDIR)
	@$(PY) overhangs.py --trade Justine

open: $(PREVDIR)/head.png
	@open $<

clean:
	rm -rf $(PREVDIR) $(EXPDIR) __pycache__ tests/__pycache__
