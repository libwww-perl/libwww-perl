use HTTP::Status;

print "1..7\n";

if (200 == RC_OK) {
    print "ok 1\n";
}

if (isSuccess(RC_ACCEPTED)) {
    print "ok 2\n";
}

if (isError(RC_BAD_REQUEST)) {
    print "ok 3\n";
}

if (isRedirect(RC_MOVED_PERMANENTLY)) {
    print "ok 4\n";
}

if (isSuccess(RC_NOT_FOUND)) {
    print "not ok 5\n";
} else {
    print "ok 5\n";
}

$mess = statusMessage(0);

if (defined $mess) {
    print "not ok 6\n";
} else {
    print "ok 6\n";
}

$mess = statusMessage(200);

if ($mess =~ /ok/i) {
    print "ok 7\n";
}

