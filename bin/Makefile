# Make an alias for the ua script.

UA = request

all: GET HEAD POST

GET: $(UA)
	ln -s $(UA) GET

HEAD: $(UA)
	ln -s $(UA) HEAD

POST: $(UA)
	ln -s $(UA) POST

PUT: $(UA)
	ln -s $(UA) PUT

clean:
	rm -f GET HEAD POST PUT

install:
	@echo You must copy the files yourself
