# =============================================================================
#  airfilter_cap.scad -- render previews + export the printable part
# =============================================================================
#  Usage:
#    make            # everything: all previews + STL/3MF exports
#    make renders    # just the PNG previews
#    make exports    # just the STL + 3MF files
#    make cap        # the part: its preview + STL + 3MF
#    make open       # render + open the cap preview (macOS)
#    make clean      # remove generated previews/ and export/
#  Re-runs only when airfilter_cap.scad changes.
# =============================================================================

SCAD    := airfilter_cap.scad
OSCAD   := openscad
PREVDIR := previews
EXPDIR  := export

# Printable parts (get STL + 3MF).
PARTS := cap
# Everything that gets a PNG preview (parts + the extra views).
VIEWS := cap section vents profile inuse on_filter

# --- render settings ---------------------------------------------------------
# --render forces full (CGAL) geometry: the taper + swept louvers overflow the
# fast preview CSG normaliser, which would export a blank image.
COLOR := --render --colorscheme=Tomorrow
ISO   := --camera=0,0,0,62,0,25,0 --viewall --autocenter --imgsize=820,700

PREVIEWS := $(addprefix $(PREVDIR)/,$(addsuffix .png,$(VIEWS)))
STLS     := $(addprefix $(EXPDIR)/,$(addsuffix .stl,$(PARTS)))
TMFS     := $(addprefix $(EXPDIR)/,$(addsuffix .3mf,$(PARTS)))

.DEFAULT_GOAL := all
.PHONY: all renders exports clean open $(PARTS)

all: renders exports
renders: $(PREVIEWS)
exports: $(STLS) $(TMFS)

# convenience: `make cap` builds that part's preview + exports
$(PARTS): %: $(PREVDIR)/%.png $(EXPDIR)/%.stl $(EXPDIR)/%.3mf

# --- previews ----------------------------------------------------------------
# generic single-part isometric preview
$(PREVDIR)/%.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) $(ISO) -D 'render_part="$*"' $(SCAD)

# section: ortho cut-away so the bore + grip band + louvers read
$(PREVDIR)/section.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) --projection=o \
	    --camera=0,0,0,72,0,20,0 --viewall --autocenter --imgsize=820,700 \
	    -D 'render_part="section"' $(SCAD)

# vents: straight-on at the lower (vent) side
$(PREVDIR)/vents.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) --camera=0,-600,55,0,0,95 --viewall --imgsize=820,700 \
	    -D 'render_part="cap"' $(SCAD)

# inuse: as fitted (axis horizontal, vents down), viewed from slightly below
$(PREVDIR)/inuse.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) --camera=0,0,0,108,0,25,0 --viewall --autocenter --imgsize=820,700 \
	    -D 'render_part="inuse"' $(SCAD)

# profile: tight ortho cut through the vents, to read the print overhangs
$(PREVDIR)/profile.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) --projection=o --camera=-350,-95,55,90,0,90,110 --imgsize=760,760 \
	    -D 'render_part="profile"' $(SCAD)

# --- exports -----------------------------------------------------------------
$(EXPDIR)/%.stl: $(SCAD) | $(EXPDIR)
	$(OSCAD) -o $@ -D 'render_part="$*"' $(SCAD)

$(EXPDIR)/%.3mf: $(SCAD) | $(EXPDIR)
	$(OSCAD) -o $@ -D 'render_part="$*"' $(SCAD)

# --- housekeeping ------------------------------------------------------------
$(PREVDIR) $(EXPDIR):
	mkdir -p $@

open: $(PREVDIR)/cap.png
	open $(PREVDIR)/cap.png

clean:
	rm -rf $(PREVDIR) $(EXPDIR)
