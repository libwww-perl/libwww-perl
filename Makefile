# Makefile for the LWP library

install:
	@echo "Copy lib/LWP to your perl library directory"
	@echo "Something like 'cp -r lib/LWP /local/lib/perl5'"
	@echo "Make sure you have installed URI::URL"

dist:
	./make-dist

