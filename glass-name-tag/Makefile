# =============================================================================
#  nametag.scad -- previews, exports, and the printable plates
# =============================================================================
#  Usage:
#    make            # measure + previews + the plates
#    make plates     # just the build plates (export/plate*.3mf) -- the deliverable
#    make tags       # every name as its own STL, at each bite setting
#    make grid       # the all-names contact sheet
#    make renders    # the style / font comparison sheets
#    make test       # geometry tests -- placement, grip, one-piece, glass clearance
#    make measure    # what each name's ink ACTUALLY does vs what the font claims
#    make weld       # how much material holds each name onto its bar
#    make one N=Grace   # a single tag, preview + STL
#    make clean      # remove generated previews/ and export/
#
#  The Python steps cache into ink.json / bridges.json, so re-runs are cheap.
#  Both caches are keyed by everything that can move the geometry, so changing
#  the font or size invalidates them on its own.
# =============================================================================

SCAD    := nametag.scad
OSCAD   := openscad
PREVDIR := previews
EXPDIR  := export

# textmetrics is still behind a flag in OpenSCAD; the model uses it only for
# the UNMEASURED fallback path, but it has to be enabled for the file to parse.
FLAGS := --enable=textmetrics

.DEFAULT_GOAL := all
.PHONY: all plates grid renders test measure weld tags one clean open

all: grid plates

# The deliverable: every name packed onto full build plates.
plates: $(SCAD) plate.py names.txt
	@python3 plate.py

# Every name at once -- the only way to see whether a style survives the SET
# rather than the two names it was designed against.
grid: $(SCAD) grid.py names.txt
	@python3 grid.py

# Style x font contact sheets.
renders: $(SCAD) compare.py
	@python3 compare.py

test:
	@python3 tests/run.py

# The measurement the whole model rests on: the font's declared descent against
# what the glyphs actually do. They disagree by up to 9mm depending on the name.
measure:
	@python3 measure.py $$(cat names.txt | tr '\n' ' ')

# "It will not snap at the tails" is a claim about a cross-section, so measure
# it off the mesh rather than assert it.
weld:
	@python3 weld.py

# Every name as its own STL, at each bite setting, into export/bite<X>/.
# Verified as they are written: one body, and clear of the glass.
tags:
	@python3 tags.py

# make one N=Grace
N ?= Grace
one: | $(PREVDIR) $(EXPDIR)
	@python3 -c "import measure,bridges,compare,os,json; \
ic=measure.load_cache(); bc=bridges.load_cache(); \
names=[l.strip() for l in open('names.txt') if l.strip()]; \
sd=max(measure.measure(n,'Great Vibes',15,0.15,cache=ic)['drop'] for n in names); \
compare.tag_png('$(PREVDIR)/$(N).png','$(N)','Great Vibes',15,'rail',sd,0.15,ic,bc); \
measure.save_cache(ic); bridges.save_cache(bc); print('$(PREVDIR)/$(N).png')"

$(PREVDIR) $(EXPDIR):
	@mkdir -p $@

open: grid
	@open $(PREVDIR)/all_rail.png

clean:
	rm -rf $(PREVDIR) $(EXPDIR) ink.json bridges.json
