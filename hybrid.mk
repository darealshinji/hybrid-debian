INSTALL_FILE    = install -m644 -D
INSTALL_DIR     = install -m755 -d
INSTALL_PROGRAM = install -m755 -D

CP    = cp -rf
RM    = rm -rf
RMDIR = rmdir
QMAKE = qmake
MAKE  = make

# prefix is hardcoded in the wrapper scripts
PREFIX = /usr


all:
	$(QMAKE)
	$(MAKE)

install:
	$(INSTALL_DIR)     $(DESTDIR)$(PREFIX)/bin
	$(INSTALL_DIR)     $(DESTDIR)$(PREFIX)/share/applications
	$(INSTALL_DIR)     $(DESTDIR)$(PREFIX)/share/hybrid-common
	$(INSTALL_DIR)     $(DESTDIR)$(PREFIX)/share/icons/hicolor
	$(INSTALL_PROGRAM) framecounter        $(DESTDIR)$(PREFIX)/bin
	$(INSTALL_PROGRAM) hybrid              $(DESTDIR)$(PREFIX)/bin
	$(INSTALL_PROGRAM) hybrid-qt46         $(DESTDIR)$(PREFIX)/bin
	$(INSTALL_PROGRAM) hybrid-qt5          $(DESTDIR)$(PREFIX)/bin
	$(INSTALL_PROGRAM) install-hybrid.sh   $(DESTDIR)$(PREFIX)/share/hybrid-common
	$(INSTALL_FILE)    run-hybrid          $(DESTDIR)$(PREFIX)/share/hybrid-common
	$(INSTALL_FILE)    hybrid.desktop      $(DESTDIR)$(PREFIX)/share/applications
	$(INSTALL_FILE)    hybrid-qt46.desktop $(DESTDIR)$(PREFIX)/share/applications
	$(INSTALL_FILE)    hybrid-qt5.desktop  $(DESTDIR)$(PREFIX)/share/applications
	$(CP)              icons/*             $(DESTDIR)$(PREFIX)/share/icons/hicolor

uninstall:
	cd $(DESTDIR)$(PREFIX)/bin && $(RM) framecounter hybrid hybrid-qt46 hybrid-qt5
	cd $(DESTDIR)$(PREFIX)/share/applications && \
		$(RM) hybrid.desktop hybrid-qt46.desktop hybrid-qt5.desktop
	$(RM) $(DESTDIR)$(PREFIX)/share/hybrid-common
	$(RMDIR) $(DESTDIR)$(PREFIX)/bin
	$(RMDIR) $(DESTDIR)$(PREFIX)/share/applications
	$(RMDIR) $(DESTDIR)$(PREFIX)/share/hybrid-common
	$(RMDIR) $(DESTDIR)$(PREFIX)/share/icons

clean:
	[ ! -f Makefile ] || $(MAKE) clean

distclean: clean
	[ ! -f Makefile ] || $(MAKE) distclean

