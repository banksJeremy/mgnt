all:
	mkdir -p dist/
	coffee --compile . dist/

clean:
	rm -rf dist/
