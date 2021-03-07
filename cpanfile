use strict;
use warnings;

on 'configure' => sub {
    requires 'ExtUtils::MakeMaker';
    requires 'Getopt::Long';
    requires 'File::Copy';
};

on 'runtime' => sub {
    requires 'perl' => '5.008001';
    requires 'strict';
    requires 'warnings';
    requires 'base';
    requires 'Digest::MD5';
    requires 'Encode' => '2.12';
    requires 'Encode::Locale';
    requires 'File::Listing' => '6';
    requires 'HTML::Entities';
    requires 'HTML::HeadParser';
    requires 'HTTP::Cookies' => '6';
    requires 'HTTP::Date' => '6';
    requires 'HTTP::Negotiate' => '6';
    requires 'HTTP::Request' => '6';
    requires 'HTTP::Request::Common' => '6';
    requires 'HTTP::Response' => '6';
    requires 'HTTP::Status' => '6.07';
    requires 'IO::Select';
    requires 'IO::Socket';
    requires 'LWP::MediaTypes' => '6';
    requires 'MIME::Base64' => '2.1';
    requires 'Net::FTP' => '2.58';
    requires 'Net::HTTP' => '6.18';
    requires 'Scalar::Util';
    requires 'Try::Tiny';
    requires 'URI' => '1.10';
    requires 'URI::Escape';
    requires 'WWW::RobotRules' => '6';
    suggests 'Authen::NTLM' => '1.02';
    suggests 'IO::Socket::INET';
    suggests 'LWP::Protocol::https' => '6.02';
    suggests 'Data::Dump' => '1.13';
};

on 'test' => sub {
    requires 'HTTP::Daemon' => '6.12';
    requires 'Test::Fatal';
    requires 'Test::More', '0.96';
    requires 'Test::RequiresInternet';
    requires 'FindBin';
    requires 'Test::Needs';
    recommends 'Test::LeakTrace';
};

on 'develop' => sub {
    requires 'Authen::NTLM' => '1.02';
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::EOL' => '2.00';
    requires 'Test::LeakTrace' => '0.16';
    requires 'Test::MinimumVersion';
    requires 'Test::Mojibake';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::Portability::Files';
    requires 'Test::Spelling';
    requires 'Test::Version';
};
