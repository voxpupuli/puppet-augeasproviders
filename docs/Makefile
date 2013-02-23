MAKE_MD = examples.md

all: $(MAKE_MD) $(patsubst %.md, %.html, $(wildcard *.md ../*.md) $(MAKE_MD))

examples.md: examples_header.md examples/*.md
	cat examples_header.md > examples.md
	for f in examples/*.md; do \
		f=`basename $$f .md` ; \
		echo "* [$$f provider](#$$f-provider)" ; \
	done >> examples.md
	echo >> examples.md
	cat examples/*.md >> examples.md

%.html: %.md
	pandoc -o `basename $@` -f markdown -t html -c buttondown.css -S $<

.PHONY: clean
clean:
	rm -f *.html $(MAKE_MD)
