# =============================================================================
#  HallOfFame.scad -- render previews, export the printable words + a 1:1
#  paper template for sticking them on the mirror.
# =============================================================================
#  Usage:
#    make            # everything: previews + STL/3MF + template
#    make renders    # just the PNG previews
#    make exports    # just the per-word STL/3MF
#    make template   # just the 1:1 placement template (SVG + tiled A4 PDF)
#    make check      # is every word ONE solid piece, and how thin is it?
#    make open       # render + open the layout preview (macOS)
#    make clean
# =============================================================================
#  The fonts live in ./fonts so this builds the same on any machine, and
#  `--enable textmetrics` is what lets the model measure the text and work
#  backwards from the 300 mm width.
# =============================================================================

SCAD    := HallOfFame.scad
OSCAD   := openscad
FONTS   := $(CURDIR)/fonts
PREVDIR := previews
EXPDIR  := export
RUN     := OPENSCAD_FONT_PATH=$(FONTS) $(OSCAD) --enable textmetrics

# The printable pieces: <index in reading order>:<file name>.
# Change the text in HallOfFame.scad -> update this line to match.
WORDS   := 0:hall 1:of 2:fame
NAMES   := $(foreach w,$(WORDS),$(word 2,$(subst :, ,$(w))))

VIEWS   := layout iso

# --- render settings ---------------------------------------------------------
COLOR := --colorscheme=Starnight
FLAT  := --projection=o --camera=0,0,0,0,0,0,0 --viewall --autocenter --imgsize=1200,900
ISOV  := --camera=0,0,0,62,0,18,0 --viewall --autocenter --imgsize=1200,900

PREVIEWS := $(addprefix $(PREVDIR)/,$(addsuffix .png,$(VIEWS)))
STLS     := $(addprefix $(EXPDIR)/,$(addsuffix .stl,$(NAMES)))
TMFS     := $(addprefix $(EXPDIR)/,$(addsuffix .3mf,$(NAMES)))

.DEFAULT_GOAL := all
.PHONY: all renders exports template check clean open

all: renders exports template
renders: $(PREVIEWS)
exports: $(STLS) $(TMFS)
template: $(EXPDIR)/template.svg $(EXPDIR)/template-a4.pdf

# --- previews ----------------------------------------------------------------
# layout: face-on, exactly how the three pieces sit on the mirror
$(PREVDIR)/layout.png: $(SCAD) | $(PREVDIR)
	$(RUN) -o $@ $(COLOR) $(FLAT) -D 'render_part="layout"' $(SCAD)

# iso: angled, to show the letters standing off the glass
$(PREVDIR)/iso.png: $(SCAD) | $(PREVDIR)
	$(RUN) -o $@ $(COLOR) $(ISOV) -D 'render_part="layout"' $(SCAD)

# --- exports -----------------------------------------------------------------
# One rule per word: render_part="word" + the piece index picks it out.
define WORD_RULE
$(EXPDIR)/$(word 2,$(subst :, ,$(1))).stl: $(SCAD) | $(EXPDIR)
	$(RUN) -o $$@ --export-format binstl \
	    -D 'render_part="word"' -D piece_index=$(word 1,$(subst :, ,$(1))) $(SCAD)
$(EXPDIR)/$(word 2,$(subst :, ,$(1))).3mf: $(SCAD) | $(EXPDIR)
	$(RUN) -o $$@ -O export-3mf/color-mode=model -O export-3mf/material-type=color \
	    -D 'render_part="word"' -D piece_index=$(word 1,$(subst :, ,$(1))) $(SCAD)
endef
$(foreach w,$(WORDS),$(eval $(call WORD_RULE,$(w))))

# --- placement template ------------------------------------------------------
# 2D-only render -> an SVG in real millimetres, then tiled onto A4 with
# registration marks so it can be taped up and printed at 100%.
$(EXPDIR)/template.svg: $(SCAD) | $(EXPDIR)
	$(RUN) -o $@ -D 'render_part="template"' $(SCAD)

$(EXPDIR)/template-a4.pdf: $(EXPDIR)/template.svg template.py
	python3 template.py $< $@

# --- checks ------------------------------------------------------------------
# Every word must come out as ONE body (loose letters are a nightmare to
# align), and no stroke may be thinner than a couple of extrusion widths.
check: $(STLS) $(EXPDIR)/template.svg
	python3 check.py $(EXPDIR)/template.svg $(STLS)

# --- housekeeping ------------------------------------------------------------
$(PREVDIR) $(EXPDIR):
	mkdir -p $@

open: $(PREVDIR)/layout.png
	open $(PREVDIR)/layout.png

clean:
	rm -rf $(PREVDIR) $(EXPDIR)
