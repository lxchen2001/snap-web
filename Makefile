PROG_PREV = ./dist/build/ahaskellcnorg/ahaskellcnorg
EXTRA_TEST_LIB = ./dist/build/ahaskellcnorg/ahaskellcnorg-tmp
DIST=dist
SITE=_site

default: build-dev

clean:
	rm -rf $(DIST)

hlint:
	hlint src/ tests/ --report

###########################
## DEVELOPMENT
## 
###########################
conf-dev:
	cabal --flags="development" configure

build-dev: conf-dev
	cabal -v build

test:
	cabal --enable-tests configure
	cabal build
	cabal test

p:
	$(PROG_PREV) -p 9900 @dev

bp: build-dev p
rp: clean build-dev p

###########################
## PRODUCTION
##
###########################

build: 
	cabal configure
	cabal build

rebuild: clean build

preview:
	$(PROG_PREV) -p 9900 @prod


##
##       1. create new dir _sites
##       2. compress HTML
##       3. combine & compress JS; replace related links in templates.
##       4. generate main.css via lessc; replace related links in templates.
## 

markdownJS=Markdown.Converter.js Markdown.Sanitizer.js Markdown.Editor.js
markdownMergeJS=markdown.js

create-site: 
	rm -rf $(SITE)
	mkdir -p $(SITE)/log
	mkdir -p $(SITE)/static/css
	cp snaplet.cfg $(SITE)
	cp -r snaplets data $(SITE)
	cp -r static/img $(SITE)/static/img
	cp -r static/js $(SITE)/static/js
	## Uglify JavaScripts
	cd $(SITE)/static/js && for x in *.js ; do \
		uglifyjs $$x > $$x.min.js ; \
		mv -f $$x.min.js $$x ; \
	done
	## Merge Markdown JS
	cd $(SITE)/static/js && for x in $(markdownJS) ; do \
		cat $$x >> $(markdownMergeJS); \
		echo >> $(markdownMergeJS); \
		rm $$x ; \
	done
	## Generate CSS from LESS files
	lessc --compress static/less/bootstrap.less > $(SITE)/static/css/main.css
	## compress TPL files
	for x in `find $(SITE)/ -name '*.tpl' ` ; do \
		perl -i -p -e  's/[\r\n]+|[ ]{2}|<!--(.|\s)*?--.*>//gs' $$x ; \
		perl -i -p -e  's/<!--(.|\s)*?-->//gs' $$x ; \
	done

	cp $(PROG_PREV) $(SITE)

####################### Doc

doc:
	cabal haddock --executable
