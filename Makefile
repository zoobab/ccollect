#
# 2006-2008 Nico Schottelius (nico-ccollect at schottelius.org)
# 
# This file is part of ccollect.
#
# ccollect is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# ccollect is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with ccollect. If not, see <http://www.gnu.org/licenses/>.
#
# Initially written on Fri Jan 13 12:13:08 CET 2006
#
# FIXME: add prefix-support?
#

INSTALL=install
CCOLLECT_SOURCE=ccollect
CCOLLECT_DEST=ccollect
LN=ln -sf
ASCIIDOC=asciidoc
DOCBOOKTOTEXI=docbook2x-texi
DOCBOOKTOMAN=docbook2x-man
XSLTPROC=xsltproc
XSL=/usr/share/xml/docbook/stylesheet/nwalsh/html/docbook.xsl
A2X=a2x

prefix=/usr/packages/ccollect-git
bindir=${prefix}/bin
destination=${bindir}/${CCOLLECT_DEST}

mandest=${prefix}/man/man1
manlink=/usr/local/man/man1

path_dir=/usr/local/bin
path_destination=${path_dir}/${CCOLLECT_DEST}

# where to publish
host=localhost
dir=/home/users/nico/privat/rechner/netz/seiten/www.nico.schottelius.org/src/software/ccollect
docdir=${dir}/documentation

#
# Asciidoc will be used to generate other formats later
#
MANDOCS  = doc/man/ccollect.text 			\
	doc/man/ccollect_add_source.text 		\
	doc/man/ccollect_analyse_logs.text 		\
	doc/man/ccollect_delete_source.text		\
	doc/man/ccollect_logwrapper.text			\
	doc/man/ccollect_list_intervals.text

DOCS     = ${MANDOCS} doc/ccollect.text

#
# Doku
#
HTMLDOCS = ${DOCS:.text=.html}
DBHTMLDOCS = ${DOCS:.text=.htm}

# texi is broken currently, don't know why xslt things complain yet
TEXIDOCS = ${DOCS:.text=.texi}
TEXIDOCS = 

# fop fails here, so disable it for now
PDFDOCS  =  ${DOCS:.text=.pdf}
PDFDOCS  = 

MANPDOCS = ${MANDOCS:.text=.1}

DOCBDOCS = ${DOCS:.text=.docbook}

DOC_ALL  = ${HTMLDOCS} ${DBHTMLDOCS} ${TEXIDOCS} ${MANPDOCS} ${PDFDOCS}

#
# End user targets
#
all:
	@echo "----------- ccollect make targets --------------"
	@echo "documentation:    generate HTMl, Texinfo and manpage"
	@echo "html:             only generate HTML"
	@echo "info:             only generate Texinfo"
	@echo "man:              only generate manpage{s}"
	@echo "install:          install ccollect to ${prefix}"

html: ${HTMLDOCS}
htm: ${DBHTMLDOCS}
info: ${TEXIDOCS}
man: ${MANPDOCS} 
pdf: ${PDFDOCS} 
documentation: ${DOC_ALL}

install: install-link install-manlink

install-link: install-script
	${LN} ${destination} ${path_destination}

install-script:
	${INSTALL} -D -m 0755 ${CCOLLECT_SOURCE} ${destination}

install-man: man
	${INSTALL} -d -m 0755 ${mandest}
	${INSTALL} -D -m 0644 doc/man/*.1 ${mandest}

install-manlink: install-man
	${INSTALL} -d -m 0755 ${manlink}
	for man in ${mandest}/*; do ${LN} $$man ${manlink}; done

#
# Tools
#
TOOLS2=ccollect_add_source
TOOLS2 += ccollect_analyse_logs

TOOLS=ccollect_add_source 		\
		ccollect_analyse_logs	\
		ccollect_delete_source	\
		ccollect_list_intervals \
		ccollect_logwrapper		\
		ccollect_list_intervals

# Stick to posix
TOOLSMAN1 = $(TOOLS:ccollect=doc/man/ccollect)
TOOLSMAN = $(TOOLSMAN1:=.text)

TOOLSFP = $(subst ccollect,tools/ccollect,$(TOOLS)) 

## FIXME: posix make: shell? =>

t2:
	echo $(TOOLS) - $(TOOLSFP)
	echo $(TOOLSMAN)
	echo $(TOOLSFP)
	

# docbook gets .htm, asciidoc directly .html
%.htm: %.docbook
	${XSLTPROC} -o $@ ${XSL} $<

%.html: %.text %.docbook
	${ASCIIDOC} -n -o $@ $<

%.html: %.text
	${ASCIIDOC} -n -o $@ $<

%.docbook: %.text
	${ASCIIDOC} -n -b docbook -o $@ $<

%.texi: %.docbook
	${DOCBOOKTOTEXI} --to-stdout $< > $@

#%.mandocbook: %.text
#	${ASCIIDOC} -b docbook -d manpage -o $@ $<

#%.man: %.mandocbook
#	${DOCBOOKTOMAN} --to-stdout $< > $@

#%.man: %.text
%.1: %.text
	${A2X} -f manpage $<

%.pdf: %.text
	${A2X} -f pdf $<


#
# Developer targets
#
pub:
	git push
	git push github

publish-doc: documentation
	@echo "Transferring files to ${host}"
	@chmod a+r ${DOCS} ${DOC_ALL}
	@tar c ${DOCS} ${DOC_ALL} | ssh ${host} "cd ${dir}; tar xv"

#
# Distribution
#
clean:
	rm -f ${DOC_ALL}
	rm -f doc/man/*.[0-9] doc/man/*.xml doc/*.fo doc/man/*.fo

distclean: clean
	rm -f ${DOCBDOCS}

#
# Be nice with the users and generate documentation for them
#
dist: distclean documentation

/tmp/ccollect:
	mkdir -p /tmp/ccollect

test: $(CCOLLECT_SOURCE) /tmp/ccollect
	cd ./conf/sources/; for s in *; do CCOLLECT_CONF=../ ../../ccollect daily "$$s"; done
	touch /tmp/ccollect/$$(ls /tmp/ccollect | head -n1).ccollect-marker
	CCOLLECT_CONF=./conf ./ccollect -a daily
	touch /tmp/ccollect/$$(ls /tmp/ccollect | head -n1).ccollect-marker
	CCOLLECT_CONF=./conf ./ccollect -a -p daily
