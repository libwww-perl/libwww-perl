#
# Makefile for LWP tests
#

TESTS=	getAndPrint-local \
	getAndStore-local \
	getAndPrint-http \
	getAndStore-http \
	timeout \
	post \
	get \
	moved \
	autoload

tests: $(TESTS)

getAndPrint-local:
	-perl -I../blib -w getAndPrint-local.pl

getAndStore-local:
	-perl -I../blib -w getAndStore-local.pl

getAndPrint-http:
	-perl -I../blib -w getAndPrint-http.pl

getAndStore-http:
	-perl -I../blib -w getAndStore-http.pl

timeout:
	-perl -I../blib -w timeout-http.pl

post:
	-perl -I../blib -w post-http.pl

get:
	-perl -I../blib -w get-http.pl

moved:
	-perl -I../blib -w moved.pl

autoload:
	-perl -I../blib -w autoload.pl

