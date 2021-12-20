use strict;
use warnings;
use Test::More;

use File::Temp;
use LWP::UserAgent;
use LWP::Simple;
require LWP::Protocol::file;

my $src = File::Temp->new("src-XXXXXXXXX");
my $dst = File::Temp->new("dst-XXXXXXXXX");

$src->printflush("Test\n");
$src->close;

is LWP::Simple::getstore("file:$src", $dst), 200,
    "Successful getstore into a File::Temp object";

$dst->seek(0,0);
is $dst->getline, "Test\n",
    "getstore mirrored into the \$dst filehandle";

TODO: { local $TODO = "mirror should support filehandles";
$dst = File::Temp->new("dst-XXXXXXXXX");
$src->printflush(''); # update timestamp
is LWP::Simple::mirror("file:$src", $dst), 200,
    "Successful getstore into a File::Temp object";

$dst->seek(0,0);
is $dst->getline, "Test\n",
    "getstore mirrored into the \$dst filehandle";
}

$dst = File::Temp->new("dst-XXXXXXXXX");
my $res = LWP::UserAgent->new
    ->get("file:$src", ':content_file' => $dst);

$dst->seek(0,0);
is $dst->getline, "Test\n",
    "\$ua->get with :content_file into the \$dst filehandle";

done_testing;
