#!/usr/bin/perl

# this is a rudimentary test script for now; once the number of tests stops
# changing every time I touch it, I'll add in TAP compliance

# you'll probably need at least the "args" command in your path for this to
# work, and maybe some others I missed.

use 5.10.0;
use strict;
use warnings;
use Data::Dumper;

# ----------------------------------------------------------------------
# setup

# setup test rc file
if (@ARGV and $ARGV[0] eq "-f") {
    # this allows you to say "./test.pl -f someother.rc command args"
    shift;
    $ENV{AA_RC} = shift;
}
$ENV{AA_RC} ||= "test.aarc";

# setup other env vars
$ENV{AA_BIN} = "$ENV{PWD}/__";
$ENV{EDITOR} = "vim";   # don't worry, no editor is actually invoked
$ENV{PATH} = "$ENV{PWD}/test-helpers:" . $ENV{PATH};

# run single test (usually manually) if argv exists
if (@ARGV) {
    exec($ENV{AA_BIN}, @ARGV);
}

# count number of tests in test rc file and declare TAP plan
my $plan = `grep -c '^#> ' < $ENV{AA_RC}`;
chomp($plan);
say "1..$plan";

# prepare to read the test rc
@ARGV = ($ENV{AA_RC});

open(STDERR, ">", "/dev/null");

# ----------------------------------------------------------------------

my ($t, $er);   # test, expected result
while (<>) {
    last if /^__END__/;
    next unless /^#[>#] /;
    if (s/^#\> //) {
        if ($t) {
            run_test($t, $er);
            $er = '';
        }
        $t = $_;
    }
    if (s/^## //) {
        $er .= $_;
    }
}

# finish up the straggler
if ($t) {
    run_test($t, $er);
}

# ----------------------------------------------------------------------

my $count;
sub run_test {
    my ($t, $er) = @_;

    # some kludges for now
    $er =~ s(/home/sitaram)(/home/$ENV{USER})g;

    my $fwt = $t; $fwt =~ s/ .*//; chomp($fwt); # first word of test command
    $count++;
    $er = '' if $er eq "\n";
    my $rc = `$ENV{AA_BIN} $t`;
    if ($ENV{HARNESS_ACTIVE}) {
        say ( $rc eq $er ? "ok $count" : "not ok $count" );
        return;
    }
    # print ( $count % 5 == 0 ? "($fwt)" : "." );
    if ($rc ne $er) {
        say "";
        chomp($t); chomp($rc); chomp($er);
        print "test $count fail:\n\ttest   = $t\n\texpect = $er\n\tgot    = $rc\n";
    }
}
