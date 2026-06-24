# =============================================================================
#  CakeTopperGenerator.scad -- render previews + export printable parts
# =============================================================================
#  Usage:
#    make            # everything: all previews + all STL/3MF exports
#    make renders    # just the PNG previews
#    make exports    # just the STL + 3MF files
#    make topper     # one part: its preview + STL + 3MF
#    make open       # render + open the face-on preview (macOS)
#    make clean      # remove generated previews/ and export/
#  Re-runs only when CakeTopperGenerator.scad changes.
# =============================================================================

SCAD    := CakeTopperGenerator.scad
OSCAD   := openscad
PREVDIR := previews
EXPDIR  := export

# Printable parts (get STL + 3MF).
PARTS := topper
# Everything that gets a PNG preview (parts + extra camera views).
VIEWS := topper iso

# --- render settings ---------------------------------------------------------
COLOR := --colorscheme=Tomorrow
# face-on: look straight at the XY face so the text reads normally
FLAT  := --projection=o --camera=0,0,0,0,0,0,0 --viewall --autocenter --imgsize=900,800
# iso: a slight 3D angle to show the raised layers
ISOV  := --camera=0,0,0,60,0,20,0 --viewall --autocenter --imgsize=900,800

PREVIEWS := $(addprefix $(PREVDIR)/,$(addsuffix .png,$(VIEWS)))
STLS     := $(addprefix $(EXPDIR)/,$(addsuffix .stl,$(PARTS)))
TMFS     := $(addprefix $(EXPDIR)/,$(addsuffix .3mf,$(PARTS)))

.DEFAULT_GOAL := all
.PHONY: all renders exports clean open $(PARTS)

all: renders exports
renders: $(PREVIEWS)
exports: $(STLS) $(TMFS)

# convenience: `make topper` builds that part's preview + exports
$(PARTS): %: $(PREVDIR)/%.png $(EXPDIR)/%.stl $(EXPDIR)/%.3mf

# --- previews ----------------------------------------------------------------
# topper: face-on, reads like you'd see it on the cake
$(PREVDIR)/topper.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) $(FLAT) -D 'render_part="topper"' $(SCAD)

# iso: angled view to show the raised number/text layers
$(PREVDIR)/iso.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) $(ISOV) -D 'render_part="topper"' $(SCAD)

# --- exports -----------------------------------------------------------------
$(EXPDIR)/%.stl: $(SCAD) | $(EXPDIR)
	$(OSCAD) -o $@ -D 'render_part="$*"' $(SCAD)

# 3MF keeps per-colour objects: lazy-union (so each top-level coloured object
# stays separate) + colour export -> Bambu Studio imports a part per filament.
$(EXPDIR)/%.3mf: $(SCAD) | $(EXPDIR)
	$(OSCAD) -o $@ --enable lazy-union \
	    -O export-3mf/color-mode=model -O export-3mf/material-type=color \
	    -D 'render_part="$*"' $(SCAD)

# --- housekeeping ------------------------------------------------------------
$(PREVDIR) $(EXPDIR):
	mkdir -p $@

open: $(PREVDIR)/topper.png
	open $(PREVDIR)/topper.png

clean:
	rm -rf $(PREVDIR) $(EXPDIR)
