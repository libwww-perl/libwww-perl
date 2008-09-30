#!perl -w

use Test;
plan tests => 8;

use HTTP::Status qw(:constants :is status_message);

ok(HTTP_OK, 200);

ok(is_info(HTTP_CONTINUE));
ok(is_success(HTTP_ACCEPTED));
ok(is_error(HTTP_BAD_REQUEST));
ok(is_redirect(HTTP_MOVED_PERMANENTLY));

ok(!is_success(HTTP_NOT_FOUND));

ok(status_message(0), undef);
ok(status_message(200), "OK");
