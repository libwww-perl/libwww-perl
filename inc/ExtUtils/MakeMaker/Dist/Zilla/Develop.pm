package ExtUtils::MakeMaker::Dist::Zilla::Develop;
BEGIN {
  $ExtUtils::MakeMaker::Dist::Zilla::Develop::AUTHORITY = 'cpan:DOY';
}
{
  $ExtUtils::MakeMaker::Dist::Zilla::Develop::VERSION = '0.03';
}
use strict;
use warnings;
# ABSTRACT: create bare-bones Makefile.PL files for use with dzil

use ExtUtils::MakeMaker ();


sub import {
    warn <<'EOF';

  ********************************* WARNING **********************************

  This module uses Dist::Zilla for development. This Makefile.PL will let you
  run the tests, but you are encouraged to install Dist::Zilla and the needed
  plugins if you intend on doing any serious hacking.

  ****************************************************************************

EOF

    ExtUtils::MakeMaker->export_to_level(1, @_);
}

{
    package # hide from PAUSE
        MY;

    my $message;
    BEGIN {
        $message = <<'MESSAGE';

  ********************************* ERROR ************************************

  This module uses Dist::Zilla for development. This Makefile.PL will let you
  run the tests, but should not be used for installation or building dists.
  Building a dist should be done with 'dzil build', installation should be
  done with 'dzil install', and releasing should be done with 'dzil release'.

  ****************************************************************************

MESSAGE
        $message =~ s/^(.*)$/\t\$(NOECHO) echo "$1";/mg;
    }

    sub install {
        return <<EOF;
install:
$message
\t\$(NOECHO) echo "Running dzil install for you...";
\t\$(NOECHO) dzil install
EOF
    }

    sub dist_core {
        return <<EOF;
dist:
$message
\t\$(NOECHO) echo "Running dzil build for you...";
\t\$(NOECHO) dzil build
EOF
    }
}


1;

__END__

=pod

=head1 NAME

ExtUtils::MakeMaker::Dist::Zilla::Develop - create bare-bones Makefile.PL files for use with dzil

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  # Makefile.PL
  use ExtUtils::MakeMaker::Dist::Zilla::Develop;
  WriteMakefile(NAME => 'Foo::Bar');

=head1 DESCRIPTION

L<Dist::Zilla> makes developing modules much easier by generating all kinds of
boilerplate files, saving authors from having to write them by hand, but in
some cases this can make developing more inconvenient. The most prominent
example of this is with C<Makefile.PL> files - although the majority of
distributions can be hacked on just by editing the files in a source control
checkout and using C<prove> for testing, for some this isn't sufficient. In
particular, distributions which use an auto-generated test suite and
distributions which use XS both need special handling at build time before they
will function, and with Dist::Zilla, this means running C<dzil build> and
rebuilding after every change. This is tedious!

This module provides an alternative. Create a minimal C<Makefile.PL> in source
control which handles just enough functionality for basic development (it can
be as minimal as just what is in the L</SYNOPSIS>, but can also contain
commands to generate your test suite, for example), and tell Dist::Zilla to
replace it with a real C<Makefile.PL> when you're actually ready to build a
real distribution. To do this, make sure you're still using the
L<MakeMaker|Dist::Zilla::Plugin::MakeMaker> plugin, either directly or through
a pluginbundle like L<@Basic|Dist::Zilla::PluginBundle::Basic>, and add the
C<exclude_filename = Makefile.PL> option to your F<dist.ini> where you use
C<[GatherDir]>.

In addition, this module also intercepts the C<install> and C<dist> rules in
the generated Makefile to run the appropriate Dist::Zilla commands
(C<dzil install> and C<dzil build>). This allows users to continue to use the
C<perl Makefile.PL && make && make install> set of commands, and have the
correct thing continue to happen.

Note that if you're using this module to ease testing of an XS distribution,
you'll need to account for your module not containing a C<$VERSION> statement
(assuming you're using the L<PkgVersion|Dist::Zilla::Plugin::PkgVersion>
plugin). To do this, you should use an XSLoader invocation similar to this:

  BEGIN {
      XSLoader::load(
          'Foo::Bar',
          $Foo::Bar::{VERSION} ? ${ $Foo::Bar::{VERSION} } : ()
      );
  }

This ensures that the C<$Foo::Bar::VERSION> glob isn't created if it didn't
exist initially, since this can confuse XSLoader.

=head1 BUGS

No known bugs.

Please report any bugs to GitHub Issues at
L<https://github.com/doy/extutils-makemaker-dist-zilla-develop/issues>.

=head1 SEE ALSO

L<ExtUtils::MakeMaker>

L<Dist::Zilla>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc ExtUtils::MakeMaker::Dist::Zilla::Develop

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/ExtUtils-MakeMaker-Dist-Zilla-Develop>

=item * Github

L<https://github.com/doy/extutils-makemaker-dist-zilla-develop>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ExtUtils-MakeMaker-Dist-Zilla-Develop>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ExtUtils-MakeMaker-Dist-Zilla-Develop>

=back

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
