# Makefile for the LWP library

html:
	pod2html *.pm LWP/*.pm LWP/Protocol/*.pm bin/get bin/mirror

install:
	perl ./install-lwp

dist:
	perl ./make-dist
