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
	-perl -w getAndPrint-local.pl

getAndStore-local:
	-perl -w getAndStore-local.pl

getAndPrint-http:
	-perl -w getAndPrint-http.pl

getAndStore-http:
	-perl -w getAndStore-http.pl

timeout:
	-perl -w timeout-http.pl

post:
	-perl -w post-http.pl

get:
	-perl -w get-http.pl

moved:
	-perl -w moved.pl

autoload:
	-perl -w autoload.pl
