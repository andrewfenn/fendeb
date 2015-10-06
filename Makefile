#! /usr/bin/make -f
SHELL=/bin/sh

DESTDIR?=/usr/local
prefix?=${DESTDIR}

# files that need mode 755
EXEC_FILES=bin/fendeb bin/fendeb-env bin/fendeb-create bin/fendeb-build bin/fendeb-update bin/fendeb-login

# files that need mode 644
MAN_FILE=man1/fendeb.1

all:
	@echo "usage: make install     -> installs fendeb and man pages"
	@echo "       make install-man -> installs man pages only"
	@echo "       make install-app -> installs fendeb only"
	@echo "       make gen-doc     -> generates the man pages"
	@echo "       make uninstall"
	@echo "       make uninstall-man"
	@echo "       make clean"

install-app:
	install -d -m 0755 $(prefix)/bin
	install -m 0755 $(EXEC_FILES) $(prefix)/bin
	install -d -m 0755 /etc/bash_completion.d
	install -m 0644 contrib/autocomplete.sh /etc/bash_completion.d/fendeb

gen-doc:
	cd man && \
	make gen

install-man:
	install -d -m 0755 $(prefix)/man
	cd man && \
	install -d -m 0755 $(prefix)/man/man1 && \
	install -m 0644 $(MAN_FILE) $(prefix)/man/man1 && \
	mandb $(prefix)/man/man1

install: install-app install-man

uninstall-app:
	test -d $(prefix)/bin && \
	cd $(prefix) && \
	rm -f $(EXEC_FILES)
	rm -f /etc/bash_completion.d/fendeb

uninstall-man:
	test -d $(prefix)/man && \
	cd $(prefix)/man && \
	rm -f $(MAN_FILE)
	mandb -f $(prefix)/man/$(MAN_FILE)
	rmdir --ignore-fail-on-non-empty $(prefix)/man/man1

uninstall: uninstall-app uninstall-man

clean:
	cd man && make clean
