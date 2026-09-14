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
PARTS := body cap cap_out net_out widener collet_nut spanner spanner_w test
# Everything that gets a PNG preview (parts + the multi-part views).
VIEWS := body cap cap_out net_out widener collet_nut spanner spanner_w test assembly section section_zoom clamp_section

# --- render settings ---------------------------------------------------------
COLOR := --colorscheme=Tomorrow
ISO   := --camera=0,0,0,68,0,22,0 --viewall --autocenter --imgsize=750,600

PREVIEWS := $(addprefix $(PREVDIR)/,$(addsuffix .png,$(VIEWS)))
STLS     := $(addprefix $(EXPDIR)/,$(addsuffix .stl,$(PARTS)))
TMFS     := $(addprefix $(EXPDIR)/,$(addsuffix .3mf,$(PARTS)))

.DEFAULT_GOAL := all
.PHONY: all renders exports customer clean open $(PARTS)

all: renders exports
renders: $(PREVIEWS)
exports: $(STLS) $(TMFS)

# convenience: `make body` builds that part's preview + exports
$(PARTS): %: $(PREVDIR)/%.png $(EXPDIR)/%.stl $(EXPDIR)/%.3mf

# --- previews ----------------------------------------------------------------
# generic single-part isometric preview
$(PREVDIR)/%.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) $(ISO) -D 'render_part="$*"' $(SCAD)

# widener: looking down into the mouth so the profile + internal helical tabs show
$(PREVDIR)/widener.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) --imgsize=750,650 \
	    --camera=0,0,0,52,0,20,0 --viewall --autocenter -D 'render_part="widener"' $(SCAD)

# clamp_section: collet + nut + hose, sectioned (overrides generic rule)
$(PREVDIR)/clamp_section.png: $(SCAD) | $(PREVDIR)
	$(OSCAD) -o $@ $(COLOR) --projection=ortho --imgsize=800,760 \
	    --camera=0,0,55,90,0,0,0 --viewall --autocenter -D 'render_part="clampdemo"' $(SCAD)

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

# --- customer variant --------------------------------------------------------
# One customer, one door thickness, one folder -- WITHOUT touching the defaults
# in bulkhead.scad (door_thickness there is still the untested TODO placeholder).
#
#     make customer DOOR=20      -> export/customer-20mm/{stl,3mf} + previews
#
# Only `body` actually changes with DOOR (barrel_len = door_thickness +
# inside_thread_len); the accessories are emitted unchanged so a customer gets a
# complete, self-contained kit in one folder.
DOOR      ?= 20
CUSTDIR   := $(EXPDIR)/customer-$(DOOR)mm
CUSTPARTS := body cap widener collet_nut cap_out net_out spanner spanner_w
CUSTD     := -D 'door_thickness=$(DOOR)'

customer: $(SCAD)
	mkdir -p $(CUSTDIR)
	for p in $(CUSTPARTS); do \
	    $(OSCAD) -o $(CUSTDIR)/$$p.stl -D "render_part=\"$$p\"" $(CUSTD) $(SCAD) || exit 1; \
	    $(OSCAD) -o $(CUSTDIR)/$$p.3mf -D "render_part=\"$$p\"" $(CUSTD) $(SCAD) || exit 1; \
	done
	$(OSCAD) -o $(CUSTDIR)/body.png $(COLOR) $(ISO) -D 'render_part="body"' $(CUSTD) $(SCAD)
	$(OSCAD) -o $(CUSTDIR)/section.png $(COLOR) --projection=ortho --imgsize=900,820 \
	    --camera=0,0,20,90,0,0,0 --viewall --autocenter -D 'render_part="section"' $(CUSTD) $(SCAD)

# --- housekeeping ------------------------------------------------------------
$(PREVDIR) $(EXPDIR):
	mkdir -p $@

open: $(PREVDIR)/assembly.png
	open $(PREVDIR)/assembly.png

clean:
	rm -rf $(PREVDIR) $(EXPDIR)
