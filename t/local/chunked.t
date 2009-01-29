#!/usr/bin/perl

use strict;
use warnings;

use Config;
use HTTP::Daemon;
use Test::More;
# use Time::HiRes qw(sleep);
our $CRLF;
use Socket qw($CRLF);

our $LOGGING = 0;

our @TESTS = (
              {
               expect => 629,
               comment => "traditional, unchunked POST request",
               raw => "POST /cgi-bin/redir-TE.pl HTTP/1.1
User-Agent: UNTRUSTED/1.0
Content-Type: application/x-www-form-urlencoded
Content-Length: 629
Host: localhost

JSR-205=0;font_small=15;png=1;jpg=1;alpha_channel=256;JSR-82=0;JSR-135=1;mot-wt=0;JSR-75-pim=0;pointer_motion_event=0;camera=1;free_memory=455472;heap_size=524284;cldc=CLDC-1.1;canvas_size_y=176;canvas_size_x=176;double_buffered=1;color=65536;JSR-120=1;JSR-184=1;JSR-180=0;JSR-75-file=0;push_socket=0;pointer_event=0;nokia-ui=1;java_platform=xxxxxxxxxxxxxxxxx/xxxxxxx;gif=1;midp=MIDP-1.0 MIDP-2.0;font_large=22;sie-col-game=0;JSR-179=0;push_sms=1;JSR-172=0;font_medium=18;fullscreen_canvas_size_y=220;fullscreen_canvas_size_x=176;java_locale=de;video_encoding=encoding=JPEG&width=176&height=182encoding=JPEG&width=176&height=220;"
              },
              {
               expect => 8,
               comment => "chunked with illegal Content-Length header; tiny message",
               raw => "POST /cgi-bin/redir-TE.pl HTTP/1.1
Host: localhost
Content-Type: application/x-www-form-urlencoded
Content-Length: 8
Transfer-Encoding: chunked

8
icm.x=u2
0

",
              },
              {
               expect => 868,
               comment => "chunked with illegal Content-Length header; medium sized",
               raw => "POST /cgi-bin/redir-TE.pl HTTP/1.1
Host:dev05
Connection:close
Content-Type:application/x-www-form-urlencoded
Content-Length:868
transfer-encoding:chunked

364
JSR-205=0;font_small=20;png=1;jpg=1;JSR-82=0;JSR-135=1;mot-wt=0;JSR-75-pim=0;http=1;pointer_motion_event=0;browser_launch=1;free_memory=733456;user_agent=xxxxxxxxx/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;heap_size=815080;cldc=CLDC-1.0;canvas_size_y=182;canvas_size_x=176;double_buffered=1;NAVIGATION PRESS=20;JSR-184=0;JSR-120=1;color=32768;JSR-180=0;JSR-75-file=0;RIGHT SOFT KEY=22;NAVIGATION RIGHT=5;KEY *=42;push_socket=0;pointer_event=0;KEY #=35;KEY NUM 9=57;nokia-ui=0;KEY NUM 8=56;KEY NUM 7=55;KEY NUM 6=54;KEY NUM 5=53;gif=1;KEY NUM 4=52;NAVIGATION UP=1;KEY NUM 3=51;KEY NUM 2=50;KEY NUM 1=49;midp=MIDP-2.0 VSCL-1.1.0;font_large=20;KEY NUM 0=48;sie-col-game=0;JSR-179=0;push_sms=1;JSR-172=0;NAVIGATION LEFT=2;LEFT SOFT KEY=21;font_medium=20;fullscreen_canvas_size_y=204;fullscreen_canvas_size_x=176;https=1;NAVIGATION DOWN=6;java_locale=en-DE;
0

",
              },
              {
               expect => 1104,
               comment => "chunked correctly, size ~1k; base for the big next test",
               raw => "POST /cgi-bin/redir-TE.pl HTTP/1.1
User-Agent: UNTRUSTED/1.0
Content-Type: application/x-www-form-urlencoded
Host: localhost:80
Transfer-Encoding: chunked

450
JSR-205=0;font_small=15;png=1;jpg=1;jsr184_dithering=0;CLEAR/DELETE=-8;JSR-82=0;alpha_channel=32;JSR-135=1;mot-wt=0;JSR-75-pim=0;http=1;pointer_motion_event=0;browser_launch=1;BACK/RETURN=-11;camera=1;free_memory=456248;user_agent=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;heap_size=524284;cldc=CLDC-1.1;canvas_size_y=176;canvas_size_x=176;double_buffered=1;NAVIGATION PRESS=-5;JSR-184=1;JSR-120=1;color=65536;JSR-180=0;JSR-75-file=0;RIGHT SOFT KEY=-7;NAVIGATION RIGHT=-4;KEY *=42;push_socket=0;pointer_event=0;KEY #=35;KEY NUM 9=57;nokia-ui=1;KEY NUM 8=56;KEY NUM 7=55;KEY NUM 6=54;KEY NUM 5=53;java_platform=xxxxxxxxxxxxxxxxx/xxxxxxx;KEY NUM 4=52;gif=1;KEY NUM 3=51;NAVIGATION UP=-1;KEY NUM 2=50;KEY NUM 1=49;midp=MIDP-1.0 MIDP-2.0;font_large=22;KEY NUM 0=48;sie-col-game=0;JSR-179=0;push_sms=1;JSR-172=0;NAVIGATION LEFT=-3;LEFT SOFT KEY=-6;jsr184_antialiasing=0;font_medium=18;fullscreen_canvas_size_y=220;fullscreen_canvas_size_x=176;https=1;NAVIGATION DOWN=-2;java_locale=de;video_encoding=encoding=JPEG&width=176&height=182encoding=JPEG&width=176&height=220;
0

"
              },
              {
               expect => 1104*1024,
               comment => "chunked with many chunks",
               raw => ("POST /cgi-bin/redir-TE.pl HTTP/1.1
User-Agent: UNTRUSTED/1.0
Content-Type: application/x-www-form-urlencoded
Host: localhost:80
Transfer-Encoding: chunked

".("450
JSR-205=0;font_small=15;png=1;jpg=1;jsr184_dithering=0;CLEAR/DELETE=-8;JSR-82=0;alpha_channel=32;JSR-135=1;mot-wt=0;JSR-75-pim=0;http=1;pointer_motion_event=0;browser_launch=1;BACK/RETURN=-11;camera=1;free_memory=456248;user_agent=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;heap_size=524284;cldc=CLDC-1.1;canvas_size_y=176;canvas_size_x=176;double_buffered=1;NAVIGATION PRESS=-5;JSR-184=1;JSR-120=1;color=65536;JSR-180=0;JSR-75-file=0;RIGHT SOFT KEY=-7;NAVIGATION RIGHT=-4;KEY *=42;push_socket=0;pointer_event=0;KEY #=35;KEY NUM 9=57;nokia-ui=1;KEY NUM 8=56;KEY NUM 7=55;KEY NUM 6=54;KEY NUM 5=53;java_platform=xxxxxxxxxxxxxxxxx/xxxxxxx;KEY NUM 4=52;gif=1;KEY NUM 3=51;NAVIGATION UP=-1;KEY NUM 2=50;KEY NUM 1=49;midp=MIDP-1.0 MIDP-2.0;font_large=22;KEY NUM 0=48;sie-col-game=0;JSR-179=0;push_sms=1;JSR-172=0;NAVIGATION LEFT=-3;LEFT SOFT KEY=-6;jsr184_antialiasing=0;font_medium=18;fullscreen_canvas_size_y=220;fullscreen_canvas_size_x=176;https=1;NAVIGATION DOWN=-2;java_locale=de;video_encoding=encoding=JPEG&width=176&height=182encoding=JPEG&width=176&height=220;
"x1024)."0

")
              },
             );


my $can_fork = $Config{d_fork} ||
  (($^O eq 'MSWin32' || $^O eq 'NetWare') and
   $Config{useithreads} and $Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/);

my $tests = @TESTS;
my $tport = 8333;

my $tsock = IO::Socket::INET->new(LocalAddr => '0.0.0.0',
                                  LocalPort => $tport,
                                  Listen    => 1,
                                  ReuseAddr => 1);
if (!$can_fork) {
  plan skip_all => "This system cannot fork";
}
elsif (!$tsock) {
  plan skip_all => "Cannot listen on 0.0.0.0:$tport";
}
else {
  close $tsock;
  plan tests => $tests;
}

sub mywarn ($) {
  return unless $LOGGING;
  my($mess) = @_;
  open my $fh, ">>", "http-daemon.out"
    or die $!;
  my $ts = localtime;
  print $fh "$ts: $mess\n";
  close $fh or die $!;
}


my $pid;
if ($pid = fork) {
  sleep 4;
  for my $t (0..$#TESTS) {
    my $test = $TESTS[$t];
    my $raw = $test->{raw};
    $raw =~ s/\r?\n/$CRLF/mg;
    if (0) {
      open my $fh, "| socket localhost $tport" or die;
      print $fh $test;
    }
    use IO::Socket::INET;
    my $sock = IO::Socket::INET->new(
                                     PeerAddr => "127.0.0.1",
                                     PeerPort => $tport,
                                    ) or die;
    if (0) {
      for my $pos (0..length($raw)-1) {
        print $sock substr($raw,$pos,1);
        sleep 0.001;
      }
    } else {
      print $sock $raw;
    }
    local $/;
    my $resp = <$sock>;
    close $sock;
    my($got) = $resp =~ /\r?\n\r?\n(\d+)/s;
    is($got,
       $test->{expect},
       "[$test->{expect}] $test->{comment}",
      );
  }
  wait;
} else {
  die "cannot fork: $!" unless defined $pid;
  my $d = HTTP::Daemon->new(
                            LocalAddr => '0.0.0.0',
                            LocalPort => $tport,
                            ReuseAddr => 1,
                           ) or die;
  mywarn "Starting new daemon as '$$'";
  my $i;
  LISTEN: while (my $c = $d->accept) {
    my $r = $c->get_request;
    mywarn sprintf "headers[%s] content[%s]", $r->headers->as_string, $r->content;
    my $res = HTTP::Response->new(200,undef,undef,length($r->content).$CRLF);
    $c->send_response($res);
    $c->force_last_request; # we're just not mature enough
    $c->close;
    undef($c);
    last if ++$i >= $tests;
  }
}



# Local Variables:
# mode: cperl
# cperl-indent-level: 2
# End:
