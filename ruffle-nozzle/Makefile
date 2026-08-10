# =============================================================================
#  nozzle.scad -- render previews + export the printable parts
# =============================================================================
#  Usage:
#    make            # everything: all previews + STL/3MF exports
#    make renders    # just the PNG previews
#    make exports    # just the STL + 3MF files
#    make test       # geometry tests -- do the three parts actually fit?
#    make size D=20  # the whole set at some other base diameter
#    make compare    # the side-by-side previews (model vs the source photo)
#    make overhangs  # what each part asks of the printer, from the meshes
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
# Plus the aperture test print -- not a part so much as a question. It is the
# top 16mm, so ~1/3 of the layers, and it exists to settle slot_grow in two or
# three goes rather than two or three full nozzles.
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
.PHONY: all renders exports test size compare overhangs trace clean open $(PARTS) $(EXTRA)

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

# binstl, not the ASCII default: same geometry, about a fifth of the bytes, and
# these are committed.
$(EXPDIR)/%.stl: $(SCAD) | $(EXPDIR)
	$(OSCAD) -o $@ --export-format binstl -D 'render_part="$*"' $(SCAD)

$(EXPDIR)/%.3mf: $(SCAD) | $(EXPDIR)
	$(OSCAD) -o $@ -D 'render_part="$*"' $(SCAD)

# per-part shortcut: `make nozzle`
$(PARTS) $(EXTRA): %: $(PREVDIR)/%.png $(EXPDIR)/%.stl

test:
	@python3 tests/run.py

# "No supports needed" is a claim about geometry, so measure it rather than
# assert it -- this reads the exported meshes back.
overhangs: exports
	@python3 overhangs.py

# Composites that OpenSCAD cannot make alone -- model against the photo it was
# traced from, and the three rotations that show the slot is on one flank.
COMPARES := $(addprefix $(PREVDIR)/,rotate.png compare_top.png)
compare: $(COMPARES)
$(COMPARES): $(SCAD) compare.py | $(PREVDIR)
	@python3 compare.py

# base_d is settled at 23 (see README), so there is ONE set of exports and no
# suffixes to mix up. This is here for the other case -- fitting a particular
# bag, say -- and it deliberately builds the WHOLE set, because the coupler is
# sized from base_d and a nozzle from one diameter will not clamp in a ring
# from another.
#   make size D=20
D ?= 23
size: | $(EXPDIR)
	@echo "--- base Ø$(D): nozzle + coupon + sleeve + ring ---"
	@$(OSCAD) -o $(EXPDIR)/nozzle_d$(D).stl --export-format binstl -D base_d=$(D) \
	          -D 'render_part="nozzle"' $(SCAD) 2>&1 | sed -n 's/^ECHO: /  /p'
	@for p in coupon sleeve ring; do \
	  $(OSCAD) -o $(EXPDIR)/$${p}_d$(D).stl --export-format binstl -D base_d=$(D) \
	           -D "render_part=\"$${p}\"" $(SCAD) >/dev/null 2>&1; \
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
