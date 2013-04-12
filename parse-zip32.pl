#!/usr/bin/env perl

use v5.16;
use utf8;
use autodie;
use JSON;

binmode STDOUT, ":utf8";
# binmode STDERR, ":utf8";

open my $fh, "<:utf8", "data/Zip32_10202.txt";

my %SideConstraint = (
    "單" => "Odd",
    "雙" => "Even",
    "連" => ""
);

my @rules;

while (<$fh>) {
    chomp;

    ## A few entry has "( comment )" at the very end... trim those.
    s!號\(.+\z!號!;

    my $line = $_;

    my ($zipcode, $adm, $adm3, $constraint) = m!\A(\d{5}) (\S{1,7}) \s* (\S+) \s+ (.+) \z!x or die "Not Match: $line\n";
    my $zone;

    $constraint =~ s!\s+\z!!;
    $constraint =~ s!\A\s+!!;
    $constraint =~ s!\s+!!g;

    my $constraint_original = $constraint;

    if ($constraint eq "") {
        ($constraint, $adm3) = ($adm3, undef);
    }

    $constraint =~ s! (\d+) 之 (\d+) !$1-$2!xg;
    $constraint =~ s! (\d)至 !$1號至!xg;

    my @zone;

    my %number_subject = (
        Door => 1,
        Lane => 1,
        Alley => 1,
    );

    my $constraint_processed = "";

    if ($constraint =~ s!\A (\d+)巷 !!x) {
        $constraint_processed .= $&;
        push @zone, "LaneEq[$1]";
        delete $number_subject{Lane};
    }
    if ($constraint =~ s!\A (\d+)弄 !!x) {
        $constraint_processed .= $&;
        push @zone, "AlleyEq[$1]";
        delete @number_subject{qw(Lane Alley)};

    }
    if ($constraint =~ s!\A (\d+)號 \z!!x) {
        $constraint_processed .= $&;
        push @zone, "DoorEq[$1]";
        delete @number_subject{qw(Door Lane Alley)};
    }

    if ($constraint eq "全") {
        push(@zone => "Whatever");
    }
    elsif ($constraint =~ s!\A (?<side> [單雙])全 \z!!x) {
        if (keys %number_subject) {
            my $side = $SideConstraint{ $+{side} };
            push @zone, "(" . join(" | " => map { "${side}${_}" } keys %number_subject) . ")";
        }
    }
    elsif ($constraint =~ s!\A (?<side> [單雙連]) (?<num> \d+)[號巷] 以上 \z!!x) {
        die "No side?" unless defined $+{side};
        delete $number_subject{Alley};

        my $side = $SideConstraint{ $+{side} };
        push @zone, "(" . join(" | " => map { "${side}${_}Range[$+{num},*]" } keys %number_subject ) . ")";
    }
    elsif ($constraint =~ s!\A (?<side> [單雙連]) (?<num> \d+)[號巷] 以下 \z!!x) {
        die "No side?" unless defined $+{side};
        delete $number_subject{Alley};

        my $side = $SideConstraint{ $+{side} };
        push @zone, "(" . join(" | " => map { "${side}${_}Range[*,$+{num}]" } keys %number_subject ) . ")";
    }
    elsif ($constraint =~ s!\A (?<side> [單雙連]) (?<num1> \d+)號 至 (?<num2> \d+)號\z!!x) {
        die "No side?" unless defined $+{side};

        my $side = $SideConstraint{ $+{side} };
        push @zone, "${side}Range[$+{num1},$+{num2}]";
    }

    pop @zone if $zone[-1] eq "Whatever" && @zone > 1;

    $zone = join " & " => @zone;

    $zone = "FAIL" unless @zone;

    # $constraint =~ s!\A ([單雙連]) !!x;

    # given($constraint) {
    #     when ("全") {
    #         $zone = "Door | Lane | Lane"
    #     }
    #     when ("單全") {
    #         $zone = "OddDoor | OddLane | OddAlley"
    #     }
    #     when ("雙全") {
    #         $zone = "EvenDoor | EvenLane | EvenAlley"
    #     }
    #     when (/\A (\d+ (?: 之(\d+))? ) 號 \z/x) {
    #         my $n = $1 . ($2 ? "-$2" : "");
    #         $zone = "DoorEq[$n]";
    #     }

    #     when (/\A (?<lane> \d+)巷 (?<num> \d+ (?:之 (?<p> \d+))? ) 號 \z/x) {
    #         my $n = $+{num} . ( defined($+{p}) ? "-$+{p}" : "" );
    #         $zone = "LaneEq[$1] & DoorEq[$n]";
    #     }

    #     when (/\A (\d+) 巷全 \z/x) {
    #         $zone = "LaneEq[$1]";
    #     }

    #     when (/\A (\d+) 弄全 \z/x) {
    #         $zone = "AlleyEq[$1]";
    #     }

    #     # when (/\A (\d+) 鄰 \z/x) {
    #     # }

    #     when (/\A (?<num> \d+)巷 (?<side> [單雙]) 全 \z/x) {
    #         my $z = $+{side} ? ($+{side} eq "單" ? "OddDoor" : "EvenDoor") : "AnyDoor";
    #         $z = "AnyLane & $z";
    #         $zone = $z;
    #     }

    #     when (/\A (?<side> [單雙連]) (?<num> \d+ (?: 之(?<p> \d+))? )號 以(?<ud> [上下])/x) {
    #         my $z = $+{side} eq "單" ? "OddDoor" : $+{side} eq "雙" ? "EvenDoor" : "AnyDoor";
    #         $z .= $+{ud} eq "上" ? "Gte" : "Lte";
    #         $z .= "[$+{num}]" . ($+{p} ? "-$+{p}" : "");
    #         $zone = $z;
    #     }

    #     when (/\A (?<lane> \d+)巷 (?<side> [單雙連]) (?<num> \d+)號 以(?<ud> [上下])/x) {
    #         my $z .= "LaneEq[$+{lane}] & ";
    #         $z .= $+{side} eq "單" ? "OddDoor" : $+{side} eq "雙" ? "EvenDoor" : "AnyDoor";
    #         $z .= $+{ud} eq "上" ? "Gte" : "Lte";
    #         $z .= "[$+{num}]";
    #     }

    #     when (/\A (?<side> [單雙連]) (?<num1> \d+)[號巷] 至 (?<num2> \d+)[號巷] \z/x) {
    #         my $z = $+{side} eq "單" ? "OddDoor" : $+{side} eq "雙" ? "EvenDoor" : "AnyDoor";
    #         $z .= "Range[$+{num1},$+{num2}]";
    #         $zone = $z;
    #     }

    #     when (/^(?<side> [單雙連]) (?<num> \d+)巷 以(?<ud> [上下])/x) {
    #         my $z = $+{side} eq "單" ? "OddLane" : $+{side} eq "雙" ? "EvenLane" : "AnyLane";
    #         $z .= $+{ud} eq "上" ? "Gte" : "Lte";
    #         $z .= "[$+{num}]";
    #         $zone = $z;
    #     }

    #     default {
    #         $zone = "?: $constraint";

            # $constraint =~ s!\((.+)\)?\z!(.+)!;
            # $constraint =~ s!\d+! (\\d+) !g;
            # $constraint =~ s![單雙]! ([單雙]) !g;
            # $constraint =~ s!以[上下]! (以[上下]) !g;
            # $constraint =~ s![弄巷號]! ([弄巷號]) !g;
            # $constraint =~ s!\A\s+!!;
            # $constraint =~ s!\s+! !g;

    #     }
    # }

    # say "$number -- $city_district -- $street -- $constraint";
    my ($adm1, $adm2) = $adm =~ m!( .+ [縣市] | 釣魚台 | 南海島) ( .+ [市鄉鎮區島] | 釣魚台)!x;

    die "Fail to extract adm1 and adm2: $adm\n" unless $adm1 && $adm2;
    push @rules, {
        zip  => $zipcode,
        adm1 => $adm1,
        adm2 => $adm2,
        adm3 => $adm3,
        zone => $zone,
        _constraint => $constraint_original
    };
}

for (@rules) {
    say JSON::to_json($_);
}


__END__

Validation experession

postifx

  ~Odd
  ~Even

  ~Eq[n]
  ~Range[a,b]
  ~Range[a,*]     # gte a
  ~Range[*,b]     # lte b
  ~OddRange[a,b]
  ~EvenRange[a,b]

Door = 門牌號碼

  DoorOdd    := 門牌號碼 為奇數
  DoorEven   := 門牌號碼 為偶數
  DoorEq[42] := 門牌號碼 等於 43

Lane = 巷

Alley = 弄

Floor = 樓

