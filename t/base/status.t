use HTTP::Status;

print "1..7\n";

if (200 == RC_OK) {
    print "ok 1\n";
}

if (is_success(RC_ACCEPTED)) {
    print "ok 2\n";
}

if (is_error(RC_BAD_REQUEST)) {
    print "ok 3\n";
}

if (is_redirect(RC_MOVED_PERMANENTLY)) {
    print "ok 4\n";
}

if (is_success(RC_NOT_FOUND)) {
    print "not ok 5\n";
} else {
    print "ok 5\n";
}

$mess = status_message(0);

if (defined $mess) {
    print "not ok 6\n";
} else {
    print "ok 6\n";
}

$mess = status_message(200);

if ($mess =~ /ok/i) {
    print "ok 7\n";
}

