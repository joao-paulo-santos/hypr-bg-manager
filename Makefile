PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
DOCDIR = $(PREFIX)/share/doc/hypr-bg-manager

SCRIPT = hypr-bg-manager.sh
TARGET = hypr-bg-manager

.PHONY: install uninstall

install:
	install -Dm755 $(SCRIPT) $(DESTDIR)$(BINDIR)/$(TARGET)
	install -Dm644 README.md $(DESTDIR)$(DOCDIR)/README.md

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/$(TARGET)
	rm -rf $(DESTDIR)$(DOCDIR)