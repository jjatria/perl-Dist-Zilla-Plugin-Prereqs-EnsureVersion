package Dist::Zilla::Plugin::Prereqs::EnsureVersion;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with 'Dist::Zilla::Role::InstallTool';

use namespace::autoclean;

use Config::IOD::Reader;
use File::HomeDir;

sub setup_installer {
    my ($self) = @_;

    state $pmversions = do {
        my $path = File::HomeDir->my_home . "/pmversions.ini";
        my $hoh = Config::IOD::Reader->new->read_file($path);
        $hoh->{GLOBAL} // {};
    };

    my $prereqs_hash = $self->zilla->prereqs->as_string_hash;

    for my $phase (sort keys %$prereqs_hash) {
        for my $rel (sort keys %{$prereqs_hash->{$phase}}) {
            my $versions = $prereqs_hash->{$phase}{$rel};
            for my $mod (sort keys %$versions) {
                my $ver = $versions->{$mod};
                my $minver = $pmversions->{$mod};
                next unless defined $minver;
                if (version->parse($minver) > version->parse($ver)) {
                    $self->log_fatal([
                        "Prerequisite %s is below minimum version (%s vs %s)",
                        $mod, $ver, $minver]);
                }
            }
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Make sure that prereqs have minimum versions

=for Pod::Coverage .+

=head1 SYNOPSIS

In F<~/pmversions.ini>:

 Log::Any::IfLOG=0.07
 File::Write::Rotate=0.28

In F<dist.ini>:

 [Prereqs::EnsureVersion]


=head1 DESCRIPTION

This plugin will check versions specified in prereqs. First you create
F<~/pmversions.ini> containing list of modules and their mininum versions. Then,
the plugin will check all prereqs against this list. If minimum version is not
met (e.g. the prereq says 0 or a smaller version) then the build will be
aborted.

Ideas for future version: ability to blacklist certain versions, specify version
ranges, e.g.:

 Module::Name = 1.00-2.00, != 1.93


=head1 SEE ALSO

L<Dist::Zilla::Plugin::MinimumPrereqs>

There are some plugins on CPAN related to specifying/detecting Perl's minimum
version, e.g.: L<Dist::Zilla::Plugin::MinimumPerl>,
L<Dist::Zilla::Plugin::Test::MinimumVersion>.
