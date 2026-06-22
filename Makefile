# =============================================================================
#  bulkhead.scad -- render previews + export printable parts
# =============================================================================
#  Usage:
#    make            # everything: all previews + all STL/3MF exports
#    make renders    # just the PNG previews
#    make exports    # just the STL + 3MF files
#    make body       # one part: its preview + STL + 3MF
#    make open       # render + open the assembly preview (macOS)
#    make clean      # remove generated previews/ and export/
#  Re-runs only when bulkhead.scad changes.
# =============================================================================

SCAD    := bulkhead.scad
OSCAD   := openscad
PREVDIR := previews
EXPDIR  := export

# Printable parts (get STL + 3MF). Accessories + the fit-test coupon.
PARTS := body cap widener test
# Everything that gets a PNG preview (parts + the multi-part views).
VIEWS := body cap widener test assembly section section_zoom

# --- render settings ---------------------------------------------------------
COLOR := --colorscheme=Tomorrow
ISO   := --camera=0,0,0,68,0,22,0 --viewall --autocenter --imgsize=750,600

PREVIEWS := $(addprefix $(PREVDIR)/,$(addsuffix .png,$(VIEWS)))
STLS     := $(addprefix $(EXPDIR)/,$(addsuffix .stl,$(PARTS)))
TMFS     := $(addprefix $(EXPDIR)/,$(addsuffix .3mf,$(PARTS)))

.DEFAULT_GOAL := all
.PHONY: all renders exports clean open $(PARTS)

all: renders exports
renders: $(PREVIEWS)
exports: $(STLS) $(TMFS)

# convenience: `make body` builds that part's preview + exports
$(PARTS): %: $(PREVDIR)/%.png $(EXPDIR)/%.stl $(EXPDIR)/%.3mf

# --- previews ----------------------------------------------------------------
# generic single-part isometric preview
$(PREVDIR)/%.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) $(ISO) -D 'render_part="$*"' $(SCAD)

# widener: lower, side-on angle so the flat mouth section + grip tabs show
$(PREVDIR)/widener.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) --imgsize=750,600 \
	    --camera=0,0,0,82,0,25,0 --viewall --autocenter -D 'render_part="widener"' $(SCAD)

# section: orthographic, centred on the clamp stack (overrides generic rule)
$(PREVDIR)/section.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) --projection=ortho --imgsize=900,760 \
	    --camera=0,0,30,90,0,0,300 -D 'render_part="section"' $(SCAD)

# section_zoom: tight ortho on the thread / clamp interface
$(PREVDIR)/section_zoom.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) --projection=ortho --imgsize=850,850 \
	    --camera=40,0,40,90,0,0,90 -D 'render_part="section"' $(SCAD)

# --- exports -----------------------------------------------------------------
$(EXPDIR)/%.stl: $(SCAD) | $(EXPDIR)
	$(OSCAD) -o $@ -D 'render_part="$*"' $(SCAD)

$(EXPDIR)/%.3mf: $(SCAD) | $(EXPDIR)
	$(OSCAD) -o $@ -D 'render_part="$*"' $(SCAD)

# --- housekeeping ------------------------------------------------------------
$(PREVDIR) $(EXPDIR):
	mkdir -p $@

open: $(PREVDIR)/assembly.png
	open $(PREVDIR)/assembly.png

clean:
	rm -rf $(PREVDIR) $(EXPDIR)
