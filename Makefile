all:
	mkdir -p dist/
	coffee -o dist/ --compile .
	docco *.coffee

clean:
	rm -rf dist/ docs/
