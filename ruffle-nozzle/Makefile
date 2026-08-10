# =============================================================================
#  nozzle.scad -- render previews + export the printable parts
# =============================================================================
#  Usage:
#    make            # everything: all previews + STL/3MF exports
#    make renders    # just the PNG previews
#    make exports    # just the STL + 3MF files
#    make test       # geometry tests -- do the three parts actually fit?
#    make sizes      # export a MATCHED set (nozzle+coupon+sleeve+ring) per Ø
#    make compare    # the side-by-side previews (model vs photo, both sizes)
#    make trace      # re-derive aperture + proportions from the product photos
#    make coupon     # the aperture test print: preview + STL
#    make open       # render + open the assembly preview (macOS)
#    make clean      # remove generated previews/ and export/
#  Re-runs only when nozzle.scad changes.
# =============================================================================

SCAD    := nozzle.scad
OSCAD   := openscad
PREVDIR := previews
EXPDIR  := export

# The three printable parts. The nozzle alone is a complete tool -- the sleeve
# and ring are the coupler, and are only needed to swap tips mid-bag.
PARTS := nozzle sleeve ring
# Plus the aperture test print, which is not a part so much as a 5-minute question.
EXTRA := coupon
# Everything that gets a PNG.
VIEWS := $(PARTS) $(EXTRA) assembly section all aperture

COLOR := --render --colorscheme=Tomorrow
ISO   := --camera=0,0,0,68,0,20,0 --viewall --autocenter --imgsize=820,700
FLAT  := --camera=0,0,0,90,0,0,0 --viewall --autocenter --imgsize=760,700
TOP   := --camera=0,0,0,0,0,0,0 --viewall --autocenter --imgsize=520,520

PREVIEWS := $(addprefix $(PREVDIR)/,$(addsuffix .png,$(VIEWS)))
STLS     := $(addprefix $(EXPDIR)/,$(addsuffix .stl,$(PARTS) $(EXTRA)))
TMFS     := $(addprefix $(EXPDIR)/,$(addsuffix .3mf,$(PARTS)))

.DEFAULT_GOAL := all
.PHONY: all renders exports test sizes compare trace clean open $(PARTS) $(EXTRA)

all: renders exports compare

renders: $(PREVIEWS)
exports: $(STLS) $(TMFS)

$(PREVDIR) $(EXPDIR):
	@mkdir -p $@

# section and aperture want their own cameras; everything else gets the iso.
$(PREVDIR)/section.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) $(FLAT) -D 'render_part="section"' $(SCAD)

$(PREVDIR)/aperture.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) $(TOP) -D 'render_part="aperture"' $(SCAD)

$(PREVDIR)/%.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) $(ISO) -D 'render_part="$*"' $(SCAD)

$(EXPDIR)/%.stl: $(SCAD) | $(EXPDIR)
	$(OSCAD) -o $@ -D 'render_part="$*"' $(SCAD)

$(EXPDIR)/%.3mf: $(SCAD) | $(EXPDIR)
	$(OSCAD) -o $@ -D 'render_part="$*"' $(SCAD)

# per-part shortcut: `make nozzle`
$(PARTS) $(EXTRA): %: $(PREVDIR)/%.png $(EXPDIR)/%.stl

test:
	@python3 tests/run.py

# Composites that OpenSCAD cannot make alone -- model against the photo it was
# traced from, the three rotations, and the two sizes at a common scale.
COMPARES := $(addprefix $(PREVDIR)/,rotate.png compare_top.png sizes.png)
compare: $(COMPARES)
$(COMPARES): $(SCAD) compare.py | $(PREVDIR)
	@python3 compare.py

# The published Ø is unresolved (see README). These are the two candidates.
#
# EVERY part is exported per diameter, INCLUDING the coupler, because the
# coupler is not one-size-fits-all: it derives its thread, its clamp and its
# nose from base_d. A Ø23 ring's lip bore is Ø23.6 against a Ø18 nozzle's Ø20.8
# flange -- the flange drops straight through it -- and the Ø23 nose is 4.4mm
# too fat to enter a Ø18 bore. Mixing sizes gives you no clamping whatsoever,
# so the files are named to make that impossible to do by accident.
SIZES := 23 18
SIZED := nozzle coupon sleeve ring
sizes: | $(EXPDIR)
	@for d in $(SIZES); do \
	  echo "--- base Ø$$d : nozzle_d$$d + coupon_d$$d + sleeve_d$$d + ring_d$$d ---"; \
	  $(OSCAD) -o $(EXPDIR)/nozzle_d$$d.stl -D base_d=$$d \
	           -D 'render_part="nozzle"' $(SCAD) 2>&1 | sed -n 's/^ECHO: /  /p'; \
	  for p in coupon sleeve ring; do \
	    $(OSCAD) -o $(EXPDIR)/$${p}_d$${d}.stl -D base_d=$$d \
	             -D "render_part=\"$${p}\"" $(SCAD) >/dev/null 2>&1; \
	  done; \
	done

# The aperture outline is generated, not drawn. This regenerates it from the
# top-down photo and rewrites the APERTURE block in nozzle.scad. trace_side
# reports the cone's proportions from the side photo -- height_ratio and tip_d
# are set by hand from its output, so read it, do not just run it.
trace:
	@python3 trace/trace.py
	@echo
	@python3 trace/trace_side.py

open: $(PREVDIR)/assembly.png
	@open $<

clean:
	rm -rf $(PREVDIR) $(EXPDIR)
