bin_PROGRAMS = sentech-viewer

gresource_file = sentech.gresource.xml
resource_files = $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies $(gresource_file))
resources.c: $(gresource_file) $(resource_files)
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) --target=$@ --sourcedir=. --generate-source $<

BUILT_SOURCES = resources.c

sentech_viewer_SOURCES = \
	$(BUILT_SOURCES) \
	main.vala \
	window.vala \
	colorspaces.c

sentech_viewer_CPPFLAGS = $(SENTECH_VIEWER_CFLAGS)

sentech_viewer_VALAFLAGS = \
	--target-glib=2.38 \
	--vapidir=$(top_srcdir)/vapi \
	--gresources $(gresource_file) \
	--pkg gdk-3.0 \
	--pkg gtk+-3.0 \
	--pkg posix \
	--pkg aravis

sentech_viewer_LDADD = $(SENTECH_VIEWER_LIBS)

-include $(top_srcdir)/git.mk
