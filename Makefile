
dist:
	(cd ..; find lwp \! -name '*~' \! -type d -print | gtar +files-from - +create +file lwp.tar ; gzip -c lwp.tar > lwp.tar.gz)
