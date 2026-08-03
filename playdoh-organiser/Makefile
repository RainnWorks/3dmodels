# =============================================================================
#  organiser.scad -- render previews + export the printable parts
# =============================================================================
#  Usage:
#    make            # everything: all previews + STL/3MF exports
#    make renders    # just the PNG previews
#    make exports    # just the STL + 3MF files
#    make styles     # the four stack_style comparison previews
#    make weigh      # material volume of every style, for comparing filament
#    make tray       # the main part: its preview + STL + 3MF
#    make open       # render + open the tray preview (macOS)
#    make clean      # remove generated previews/ and export/
#  Re-runs only when organiser.scad changes.
# =============================================================================

SCAD    := organiser.scad
OSCAD   := openscad
PREVDIR := previews
EXPDIR  := export

# The only printable part -- print one per layer of pots.
PARTS  := tray
# The four ways of carrying the tray above -- rendered side by side to compare.
STYLES := pots posts rails walls
# The two ways a cell can hold a pot.
CELLS  := hang nest cup
# Everything that gets a PNG preview (parts + the extra views).
VIEWS  := tray pot stack section detail bearing \
          $(addprefix stack_,$(STYLES)) $(addprefix cells_,$(CELLS))

# --- render settings ---------------------------------------------------------
# --render forces full (CGAL) geometry: the grid of collars + frusta overflows
# the fast preview CSG normaliser, which would export a blank image.
COLOR := --render --colorscheme=Tomorrow
ISO   := --camera=0,0,0,68,0,20,0 --viewall --autocenter --imgsize=820,700

PREVIEWS := $(addprefix $(PREVDIR)/,$(addsuffix .png,$(VIEWS)))
STLS     := $(addprefix $(EXPDIR)/,$(addsuffix .stl,$(PARTS)))
TMFS     := $(addprefix $(EXPDIR)/,$(addsuffix .3mf,$(PARTS)))

.DEFAULT_GOAL := all
.PHONY: all renders exports styles weigh clean open $(PARTS)

all: renders exports
renders: $(PREVIEWS)
exports: $(STLS) $(TMFS)
styles: $(addprefix $(PREVDIR)/stack_,$(addsuffix .png,$(STYLES)))

# convenience: `make tray` builds that part's preview + exports
$(PARTS): %: $(PREVDIR)/%.png $(EXPDIR)/%.stl $(EXPDIR)/%.3mf

# --- previews ----------------------------------------------------------------
# generic single-part isometric preview
$(PREVDIR)/%.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) $(ISO) -D 'render_part="$*"' $(SCAD)

# One loaded-tower preview per stacking style. These have to be *explicit* rules
# -- a `stack_%.png` pattern rule loses to the generic `%.png` one above, which
# would render render_part="stack_pots" and quietly emit a blank image.
define STYLE_PREVIEW
$(PREVDIR)/stack_$(1).png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $$@ $(COLOR) $(ISO) \
	    -D 'render_part="stack"' -D 'stack_style="$(1)"' $(SCAD)
endef
$(foreach s,$(STYLES),$(eval $(call STYLE_PREVIEW,$(s))))

# Same again for the three cell styles. Each holds the pot at a different height
# up its body, so each needs its own camera Z to frame the joint.
CAMZ_hang := 55
CAMZ_nest := 60
CAMZ_cup  := 60
define CELL_PREVIEW
$(PREVDIR)/cells_$(1).png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $$@ $(COLOR) --projection=o --camera=0,0,$(CAMZ_$(1)),90,0,0,260 \
	    --imgsize=900,860 \
	    -D 'render_part="slice"' -D 'cell_style="$(1)"' $(SCAD)
endef
$(foreach c,$(CELLS),$(eval $(call CELL_PREVIEW,$(c))))

# section: ortho cut straight through the pots, to read how the trays seat
$(PREVDIR)/section.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) --projection=o \
	    --camera=0,0,0,90,0,0,0 --viewall --autocenter --imgsize=900,760 \
	    -D 'render_part="section"' $(SCAD)

# detail: tight ortho on one cell at the tray-to-tray joint -- the collar, the
# deck, the frustum sitting in the lid recess. The drawing that matters.
$(PREVDIR)/detail.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) --projection=o --camera=0,0,52,90,0,0,150 \
	    --imgsize=900,700 -D 'render_part="slice"' $(SCAD)

# bearing: low angle right at a joint, showing the plate sitting on the lid rims
# -- with no posts, that annulus IS what holds the tray up.
$(PREVDIR)/bearing.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) --camera=0,0,50,78,0,22,150 --imgsize=900,650 \
	    -D 'render_part="stack"' $(SCAD)

# tray: looking down, so the grid + collars read clearly
$(PREVDIR)/tray.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) --camera=0,0,0,55,0,20,0 --viewall --autocenter \
	    --imgsize=820,700 -D 'render_part="tray"' $(SCAD)

# --- exports -----------------------------------------------------------------
$(EXPDIR)/%.stl: $(SCAD) | $(EXPDIR)
	$(OSCAD) -o $@ -D 'render_part="$*"' $(SCAD)

$(EXPDIR)/%.3mf: $(SCAD) | $(EXPDIR)
	$(OSCAD) -o $@ -D 'render_part="$*"' $(SCAD)

# --- filament comparison -----------------------------------------------------
# Solid volume of a tray in each style x deck_style, so the filament cost of a
# choice is a number rather than a guess. Walls print near-solid at these
# thicknesses, so volume x 1.24 g/cm3 is a fair PLA estimate.
weigh: $(SCAD) | $(EXPDIR)
	@printf '%-24s %10s %8s\n' 'cells / stack' 'volume' 'PLA'
	@for c in $(CELLS); do for s in $(STYLES); do \
	    $(OSCAD) -o $(EXPDIR)/.weigh.stl --export-format binstl \
	        -D "render_part=\"tray\"" -D "cell_style=\"$$c\"" \
	        -D "stack_style=\"$$s\"" $(SCAD) 2>/dev/null; \
	    python3 weigh.py "$$c / $$s" $(EXPDIR)/.weigh.stl; \
	done; done; rm -f $(EXPDIR)/.weigh.stl

# --- housekeeping ------------------------------------------------------------
$(PREVDIR) $(EXPDIR):
	mkdir -p $@

open: $(PREVDIR)/tray.png
	open $(PREVDIR)/tray.png

clean:
	rm -rf $(PREVDIR) $(EXPDIR)
