#!/usr/bin/env perl
use v5.14;
use autodie;
use Parse::CSV;
use List::MoreUtils "uniq";
use JSON::PP 'encode_json';

my $geo = { type => "FeatureCollection", features => [ ] };

my $fh;
open $fh, "<:utf8", "data/post_atm_location.csv";

my $csv = Parse::CSV->new(
    handle => $fh,
    names  => ["city", "district", "serial", "description", "tel", "addr", "longitude", "latitude", "x1","x2","x3","x4","position"]
);

while (my $row = $csv->fetch) {
    push @{$geo->{features}}, {
        type => "Feature",
        geometry => {
            type => "Point",
            coordinates => [ $row->{longitude}, $row->{latitude} ]
        },
        properties => {
            'marker-symbol' => "bank",
            'marker-size' => 'small',
            name => $row->{description},
            address => "$row->{city} $row->{district} $row->{addr}",
            machines => join(",", uniq grep { $_ } @{$row}{"position", "x1", "x2", "x3", "x4"}),
        }
    };
    ;
}
if ($csv->errstr) {
    say "ERROR: ".$csv->errstr;
}

open my $out, ">", "data/post_atm_location.geojson";
print $out JSON::PP->new->utf8->pretty->encode($geo);
