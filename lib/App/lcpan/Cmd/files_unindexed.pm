package App::lcpan::Cmd::files_unindexed;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use File::chdir;

require App::lcpan;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'List unindexed files',
    description => <<'_',

This subcommand lists authors' files that are unindexed and are candidates for
deletion if you want to keep a minimal mini CPAN mirror (which only contains the
latest/indexed releases).

To delete you, you can use something like:

    % lcpan files-unindexed | xargs -n 100 rm

_
    args => {
        %App::lcpan::common_args,
        #exclude_dev_releases => {
        #    schema => 'If true, will skip filenames that resemble dev/trial releases',
        #    schema => 'bool',
        #},
        # XXX include_authors (include certain authors only)
        # XXX exclude_authors (exclude certain authors)
        # XXX include_author_pattern (include only authors matching pattern)
        # XXX exclude_author_pattern (exclude authors matching pattern)
    },
};
sub handle_cmd {
    require File::Find;

    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    # load all indexed releases into a hash, for quick checking
    my %indexed_files;
    my $sth = $dbh->prepare("SELECT name FROM file");
    $sth->execute;
    while (my ($fname) = $sth->fetchrow_array) {
        $indexed_files{$fname}++;
    }

    my @res;

    local $CWD = "$state->{cpan}/authors/id";

    File::Find::find(
        {
            wanted => sub {
                return unless -f;
                return if $indexed_files{$_};

                my $relpath = "$File::Find::dir/$_";
                $relpath =~ s!\A\./!!;

                # skip CHECKSUMS
                return if $relpath =~ m!\A./../[^/]+/CHECKSUMS\z!;

                push @res, "$state->{cpan}/authors/id/$relpath";
            },
            #follow_fast => 1,
        },
        ".",
    );

    [200, "OK", \@res];
}

1;
# ABSTRACT:
