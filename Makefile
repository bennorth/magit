PREFIX  ?= /usr/local
datarootdir ?= $(PREFIX)/share
lispdir ?= $(datarootdir)/emacs/site-lisp/magit
infodir ?= $(datarootdir)/info
docdir  ?= $(datarootdir)/doc/magit

LOADDEFS_FILE ?= magit-autoloads.el
LOADDEFS_DIR  ?= $(lispdir)

ELS  = magit-utils.el
ELS += magit-section.el
ELS += magit-git.el
ELS += magit-mode.el
ELS += magit-popup.el
ELS += magit-process.el
ELS += magit-core.el
ELS += magit-diff.el
ELS += magit-apply.el
ELS += magit-log.el
ELS += magit-wip.el
ELS += magit.el
ELS += magit-sequence.el
ELS += magit-stash.el
ELS += magit-backup.el
ELS += magit-commit.el
ELS += magit-remote.el
ELS += magit-bisect.el
ELS += magit-blame.el
ELS += magit-ediff.el
ELS += magit-extras.el
ELCS = $(ELS:.el=.elc)

CP    ?= install -p -m 644
MKDIR ?= install -p -m 755 -d
RMDIR ?= rm -rf

MAKEINFO     ?= makeinfo
INSTALL_INFO ?= $(shell \
  hash ginstall-info 2> /dev/null\
  && echo ginstall-info\
  || echo install-info)

EFLAGS ?= -L ../git-modes -L ../cl-lib -L ../dash
EMACS  ?= emacs
BATCH   = $(EMACS) $(EFLAGS) -batch -Q -L .
BATCHE  = $(BATCH) -eval
BATCHC  = $(BATCH) -eval "(setq with-editor-emacsclient-executable nil)" \
  -f batch-byte-compile

VERSION=$(shell \
  test -e .git\
  && git describe --tags --dirty 2> /dev/null\
  || $(BATCHE) "(progn\
  (fset 'message (lambda (&rest _)))\
  (load-file \"magit-version.el\")\
  (princ magit-version))")

.PHONY: lisp
lisp: $(ELCS) loaddefs

.PHONY: all
all: lisp magit-version.el docs

.PHONY: help
help:
	$(info Getting Help)
	$(info ============)
	$(info )
	$(info make help             - show brief help)
	$(info )
	$(info Build)
	$(info =====)
	$(info )
	$(info make                  - build elisp files)
	$(info make lisp             - ditto)
	$(info make all              - build elisp files and documentation)
	$(info make docs             - generate documentation)
	$(info )
	$(info Install)
	$(info =======)
	$(info )
	$(info make install          - install elisp files and documentation)
	$(info make install-lisp     - install elisp files)
	$(info make install-docs     - install documentation)
	$(info make install-script   - install shell script)
	$(info make install-all      - install elisp files, script, and docs)
	$(info )
	$(info Test)
	$(info ====)
	$(info )
	$(info make test             - run tests)
	$(info make test-interactive - run tests interactively)
	$(info )
	$(info Release Managment)
	$(info =================)
	$(info )
	$(info make authors          - regenerate the AUTHORS.md file)
	$(info make dist             - create old-school tarball)
	$(info make marmalade        - create marmalade tarball)
	@printf "\n"

%.elc: %.el
	@$(BATCHC) $<

# Not a phony target, but needs to run *every* time.
.PHONY: magit-version.el
magit-version.el:
	@printf "Generating magit-version.el\n"
	@printf ";;; magit-version.el --- the Magit version you are using\n\n" > $@
	@printf "(setq magit-version \""$(VERSION)"\")\n\n" >> $@
	@printf "(provide 'magit-version)\n\n" >> $@
	@printf ";; Local Variables:\n" >> $@
	@printf ";; version-control: never\n" >> $@
	@printf ";; no-byte-compile: t\n" >> $@
	@printf ";; no-update-autoloads: t\n" >> $@
	@printf ";; coding: utf-8\n" >> $@
	@printf ";; End:\n" >> $@
	@printf ";;; magit-version.el ends here\n" >> $@

.PHONY: loaddefs
loaddefs: $(LOADDEFS_FILE)

$(LOADDEFS_FILE): $(ELS)
	@printf "Generating magit-autoloads.el\n"
	@$(BATCHE) "(progn\
	(fset 'message (lambda (&rest _)))\
	(setq vc-handled-backends nil)\
	(defvar generated-autoload-file nil)\
	(let ((generated-autoload-file \"$(CURDIR)/$(LOADDEFS_FILE)\")\
	      (make-backup-files nil))\
	  (update-directory-autoloads \".\")))"

.PHONY: docs
docs: magit.info dir

%.info: %.texi
	@$(MAKEINFO) $< -o $@

dir: magit.info
	@$(INSTALL_INFO) --dir=$@ $<

CONTRIBUTORS_URL = https://github.com/magit/magit/graphs/contributors
define AUTHORS_HEADER
Authors
=======

Also see $(CONTRIBUTORS_URL).
Names below are sorted alphabetically.

Author
------

- Marius Vollmer <marius.vollmer@gmail.com>

Maintainer
----------

- Jonas Bernoulli <jonas@bernoul.li>

Retired Maintainers
-------------------

- Nicolas Dudebout <nicolas.dudebout@gatech.edu>
- Peter J. Weisberg <pj@irregularexpressions.net>
- Phil Jackson <phil@shellarchive.co.uk>
- Rémi Vanicat <vanicat@debian.org>
- Yann Hodique <yann.hodique@gmail.com>

Contributors
------------

endef
export AUTHORS_HEADER

# Not a phony target, but needs to run *every* time.
.PHONY: AUTHORS.md
AUTHORS.md: .mailmap
	@printf "Generating AUTHORS.md..."
	@test -d .git \
		&& (printf "$$AUTHORS_HEADER\n" > $@ \
			&& git log --pretty=format:'- %aN <%aE>' | sort -u >> $@ \
			&& printf "done\n" ; ) \
		|| printf "FAILED (non-fatal)\n"

.PHONY: authors
authors: AUTHORS.md

.PHONY: install
install: install-lisp install-docs

.PHONY: install-all
install-all: install-lisp install-docs install-script

.PHONY: install-lisp
install-lisp: lisp
	$(MKDIR) $(DESTDIR)$(lispdir)
	$(CP) $(ELS) $(ELCS) magit-version.el $(DESTDIR)$(lispdir)
	$(MKDIR) $(DESTDIR)$(LOADDEFS_DIR)
	$(CP) $(LOADDEFS_FILE) $(DESTDIR)$(LOADDEFS_DIR)/$(LOADDEFS_FILE)

.PHONY: install-docs
install-docs: docs
	$(MKDIR) $(DESTDIR)$(infodir)
	$(CP) magit.info $(DESTDIR)$(infodir)
	$(INSTALL_INFO) --info-dir=$(DESTDIR)$(infodir) $(DESTDIR)$(infodir)/magit.info
	$(MKDIR) $(DESTDIR)$(docdir)
	$(CP) AUTHORS.md $(DESTDIR)$(docdir)

.PHONY: test
test:
	@$(BATCHE) "(progn\
	(require 'cl) \
	(put 'flet 'byte-obsolete-info nil))" \
	-l magit-tests.el -f ert-run-tests-batch-and-exit

.PHONY: test-interactive
test-interactive:
	@$(EMACS) $(EFLAGS) -Q -L "." --eval "(progn\
	(require 'cl)\
	(put 'flet 'byte-obsolete-info nil)\
	(load-file \"magit-tests.el\")\
	(ert t))"

.PHONY: clean
clean:
	@echo "Cleaning"
	@$(RM) $(ELCS) $(LOADDEFS_FILE) magit-version.el *.tar.gz *.tar
	@$(RMDIR) magit-$(VERSION)
	@test ! -e .git || $(RM) magit.info

DIST_FILES  = $(ELS) magit-version.el Makefile AUTHORS.md
DIST_FILES += README.md magit.texi magit.info dir

ELPA_FILES  = $(ELS) magit-pkg.el magit.info dir AUTHORS.md

.PHONY: dist
dist: magit-$(VERSION).tar.gz

magit-$(VERSION).tar.gz: $(DIST_FILES)
	$(MKDIR) magit-$(VERSION)
	$(CP) $(DIST_FILES) magit-$(VERSION)
	tar -cvz --mtime=./magit-$(VERSION) -f magit-$(VERSION).tar.gz magit-$(VERSION)
	$(RMDIR) magit-$(VERSION)

.PHONY: marmalade
marmalade: magit-$(VERSION).tar

magit-$(VERSION).tar: $(ELPA_FILES)
	$(MKDIR) magit-$(VERSION)
	$(CP) $(ELPA_FILES) magit-$(VERSION)
	tar -cv --mtime=./magit-$(VERSION) -f magit-$(VERSION).tar magit-$(VERSION)
	$(RMDIR) magit-$(VERSION)
