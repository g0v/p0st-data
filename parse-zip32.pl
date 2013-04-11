#!/usr/bin/env perl

use v5.16;
use utf8;
use autodie;

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

open my $fh, "<:utf8", "data/Zip32_10202.txt";

my @rules;
while (<$fh>) {
    chomp;

    ## A few entry has "( comment )" at the very end... trim those.
    s!號\(.+\z!號!;

    my $line = $_;

    my ($number,$city_district,$street,$constraint) = m!\A(\d{5}) (\S{1,7}) \s* (\S+) \s+ (.+) \z!x or die "Not Match: $line\n";

    $constraint =~ s!\s+\z!!;
    $constraint =~ s!\A\s+!!;

    if ($constraint eq "") {
        ($constraint, $street) = ($street, undef);
    }


    given($constraint) {
        # when ("全") {
        # }
        # when ("單全") {
        # }
        # when ("雙全") {
        # }
        # when (/\A (\d+) ([號鄰]) \z/x) {
        # }
        # when (/\A (\d+) ([巷弄樓])全 \z/x) {
        # }
        # when (/\A (\d+)巷 ([單雙]) 全 \z/x) {
        # }
        # when (/\A ([單雙連]) \s+ (\d+)號以([上下])/x) {
        # }
        # when (/\A (\d+)巷 ([單雙]) \s+ (\d+)號以([上下])/x) {
        # }
        # when (/\A ([單雙連]) \s* (\d+)號 至 \s* (\d+)號 \z/x) {
        # }
        # when (/^([單雙]) \s+ (\d+)巷以([上下])/x) {
        # }
        default {
            # $constraint =~ s!\((.+)\)?\z!(.+)!;

            $constraint =~ s!\s+! \\s+ !g;
            $constraint =~ s!\d+! (\\d+) !g;
            $constraint =~ s![單雙]! ([單雙]) !g;
            $constraint =~ s!以[上下]! (以[上下]) !g;
            $constraint =~ s!\A\s+!!;
            $constraint =~ s!\s+! !g;

            say $constraint;
            # say "$number -- $city_district -- $street -- [$constraint]";
        }
    }
}
