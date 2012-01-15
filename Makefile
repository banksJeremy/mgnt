all:
	mkdir -p dist/
	coffee -o dist/ --compile .

clean:
	rm -rf dist/
