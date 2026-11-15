#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Copy qw(copy);
use lib 't/lib';
use HurricaneTest qw(require_emulator run_emulator);
use Fixtures qw(write_cases);
my $temp=require_emulator();
copy('data/HF.GILBERT',"$temp/hf.gilbert") or die $!;
my @cases=write_cases($temp);
my $ram=run_emulator('files');
is(ord(substr($ram,0x2fe,1)),0xa5,'file torture completed');
for my $i (0..$#cases) {
    is(ord(substr($ram,0xca00+$i,1)),$cases[$i][2],"compiled importer: $cases[$i][0]");
}
my ($checks,$failures,$first)=unpack('v3',substr($ram,0x2f0,6));
ok($checks>=80,"$checks C64 file checks executed");
is($failures,0,"file checks passed (first failure $first)");
$ram=run_emulator('stress');
is(ord(substr($ram,0x2fe,1)),0xa5,'model/math/render stress completed');
($checks,$failures,$first)=unpack('v3',substr($ram,0x2f0,6));
ok($checks>=7000,"$checks compiled C64 stress assertions executed");
is($failures,0,"stress checks passed (first failure $first)");
done_testing();
