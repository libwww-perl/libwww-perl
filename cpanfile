requires "AnyDBM_File" => "0";
requires "Carp" => "0";
requires "Data::Dump" => "1.13";
requires "Data::Dump::Trace" => "0";
requires "Digest::MD5" => "0";
requires "Encode" => "2.21";
requires "Encode::Locale" => "1";
requires "Exporter" => "5.57";
requires "Fcntl" => "0";
requires "File::Listing" => "0";
requires "File::Spec" => "0";
requires "Getopt::Long" => "0";
requires "Getopt::Std" => "0";
requires "HTML::Entities" => "0";
requires "HTML::FormatPS" => "0";
requires "HTML::FormatText" => "0";
requires "HTML::HeadParser" => "0";
requires "HTML::Parse" => "0";
requires "HTTP::Config" => "0";
requires "HTTP::Cookies" => "0";
requires "HTTP::Date" => "6";
requires "HTTP::Headers::Util" => "0";
requires "HTTP::Negotiate" => "0";
requires "HTTP::Request" => "0";
requires "HTTP::Request::Common" => "0";
requires "HTTP::Response" => "0";
requires "HTTP::Status" => "0";
requires "IO::Compress::Bzip2" => "2.021";
requires "IO::Select" => "0";
requires "IO::Socket" => "0";
requires "IO::Uncompress::Bunzip2" => "2.021";
requires "LWP::MediaTypes" => "6";
requires "MD5" => "0";
requires "MIME::Base64" => "2.1";
requires "Mail::Internet" => "0";
requires "Net::FTP" => "0";
requires "Net::HTTP" => "0";
requires "Net::NNTP" => "0";
requires "URI" => "1.10";
requires "URI::Escape" => "0";
requires "URI::Heuristic" => "0";
requires "WWW::RobotRules" => "0";
requires "base" => "0";
requires "integer" => "0";
requires "perl" => "5.008001";
requires "strict" => "0";
requires "vars" => "0";
suggests "Authen::NTLM" => "1.02";
suggests "CPAN::Config" => "0";
suggests "HTTP::GHTTP" => "0";
suggests "IO::Socket::INET" => "0";
suggests "LWP::Protocol::https" => "6.02";

on 'test' => sub {
  requires "File::Temp" => "0";
  requires "FindBin" => "0";
  requires "HTTP::Daemon" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::More" => "0";
  requires "Test::RequiresInternet" => "0";
  requires "URI::URL" => "0";
  requires "WWW::RobotRules::AnyDBM_File" => "0";
  requires "perl" => "5.008001";
  requires "utf8" => "0";
  requires "warnings" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "5.008";
};

on 'configure' => sub {
  suggests "JSON::PP" => "2.27300";
};

on 'develop' => sub {
  requires "Test::CPAN::Changes" => "0.19";
};
