SHELL=/bin/sh

# files that need mode 644
MAN_FILE=man1/fendeb.1

all:
	@echo "usage: make man"
	@echo "       make clean"
man:
	install -d -m 0755 man1
	pandoc -s \
        -w man fendeb.1.md \
        -o  $(MAN_FILE)
clean:
	rm -f $(MAN_FILE)
	rmdir man1 --ignore-fail-on-non-empty
