#!/usr/bin/perl

# this is a rudimentary test script for now; once the number of tests stops
# changing every time I touch it, I'll add in TAP compliance

use 5.10.0;
use strict;
use warnings;
use Data::Dumper;

$ENV{AA_RC} = "test.aarc";
# if argv exists, just run that; we're not really testing, rather just using
# this script to set up AA_RC for convenience
if (@ARGV) {
    exec("./aa", @ARGV);
}

open(STDERR, ">", "/dev/null");

@ARGV = ($ENV{AA_RC});

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

my $count;
sub run_test {
    my ($t, $er) = @_;
    my $fwt = $t; $fwt =~ s/ .*//; chomp($fwt); # first word of test command
    $count++;
    $er = '' if $er eq "\n";
    my $rc = `./aa $t`;
    print ( $count % 5 == 0 ? "($fwt)" : "." );
    if ($rc ne $er) {
        say "";
        chomp($t); chomp($rc); chomp($er);
        print "fail:\n\ttest   = $t\n\texpect = $er\n\tgot    = $rc\n";
    }
}
