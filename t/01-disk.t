#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

plan skip_all => 'run tools/build.sh first' unless -f 'build/hurricane.d64';
sub slurp { open my $f, '<:raw', $_[0] or die $!; local $/; return <$f>; }
my $disk=slurp('build/hurricane.d64');
is(length($disk),174848,'standard 35-track D64 size');
my @sectors=(0,map { $_<=17 ? 21 : $_<=24 ? 19 : $_<=30 ? 18 : 17 } 1..35);
my @offset; my $n=0;
for (1..35) { $offset[$_]=$n; $n+=$sectors[$_]*256; }
sub sector { return substr($disk,$offset[$_[0]]+256*$_[1],256); }
my $dir=sector(18,1);
my %allocated=('18,0'=>1,'18,1'=>1);
for my $index (0,1) {
    my $e=substr($dir,$index*32,32);
    my ($type,$t,$s)=unpack('CCC',substr($e,2,3));
    is($type,$index==0 ? 0x82 : 0x81, $index==0 ? 'program is closed PRG' : 'storm is closed SEQ');
    my $data='';my $blocks=0;
    while ($t) {
        die "invalid chain: $t/$s" if $t<1 || $t>35 || $s>=$sectors[$t] || $allocated{"$t,$s"}++;
        my $b=sector($t,$s);
        ($t,$s)=unpack('CC',$b);
        $data.=$t ? substr($b,2) : substr($b,2,$s-1);
        $blocks++;
    }
    is($blocks,unpack('v',substr($e,30,2)),'directory block count matches chain');
    is($data,slurp($index==0 ? 'build/hurricane.prg' : 'data/HF.GILBERT'),'file bytes preserved exactly');
}
my $bam=sector(18,0);
my $consistent=1;
for my $t (1..35) {
    my ($free,@bits)=unpack('CCCC',substr($bam,$t*4,4));
    my $actual=0;
    for my $s (0..$sectors[$t]-1) {
        my $isfree=($bits[int($s/8)]>>( $s%8 ))&1;
        $actual+=$isfree;
        $consistent=0 if $isfree==!!$allocated{"$t,$s"};
    }
    $consistent=0 if $actual!=$free;
}
ok($consistent,'BAM agrees with every allocated and free sector');
done_testing();
