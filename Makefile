all: docs
	mkdir -p dist/
	coffee -o dist/ --compile .
	test/mgnt.base.generated.spec.c > test/mgnt.base.generated.spec.js

docs:
	docco *.coffee

clean:
	rm -rf dist/ docs/
