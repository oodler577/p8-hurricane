#!/usr/bin/env perl
use strict;
use warnings;

# Deterministic 35-track D64: PRG, Gilbert SEQ, then optional NAME=PATH SEQs.
my ($output,$program,$storm,@extra)=@ARGV;
die "usage: $0 OUTPUT.d64 PROGRAM.prg HF.GILBERT [NAME=PATH ...]\n" unless defined $storm;
my @files=([$program,'HURRICANE',0x82],[$storm,'HF.GILBERT',0x81]);
my %names=('HURRICANE'=>1,'HF.GILBERT'=>1);
for (@extra) {
    my ($name,$path)=split /=/,$_,2;
    die "invalid extra file specification\n" unless defined($path) && $name =~ /^[A-Z0-9_.-]{1,16}$/;
    die "duplicate filename: $name\n" if $names{$name}++;
    push @files,[$path,$name,0x81];
}
my $directory_count=int((@files+7)/8);
die "too many directory entries\n" if $directory_count>18;
my @sectors=(0,map { $_<=17 ? 21 : $_<=24 ? 19 : $_<=30 ? 18 : 17 } 1..35);
my @offset;my $size=0;
for (1..35) { $offset[$_]=$size;$size+=$sectors[$_]*256; }
my $disk="\0"x$size;
my @available=map { my $t=$_;map { [$t,$_] } 0..$sectors[$t]-1 } grep { $_!=18 } 1..35;
my %used; $used{"18,$_"}=1 for 0..$directory_count;
sub put_sector { my ($t,$s,$data)=@_;die 'bad sector length' unless length($data)==256;substr($disk,$offset[$t]+$s*256,256,$data); }
sub read_bytes { open my $fh,'<:raw',$_[0] or die "$_[0]: $!";local $/;return <$fh> // ''; }
my @directories=map { "\0"x256 } 1..$directory_count;
for my $i (0..$#directories) { substr($directories[$i],0,2,$i<$#directories ? pack('CC',18,$i+2) : pack('CC',0,255)); }
my $entry=0;
for my $item (@files) {
    my ($path,$name,$type)=@$item;
    my $data=read_bytes($path);
    my $blocks=int((length($data)+253)/254) || 1;
    die "disk full\n" if $blocks>@available;
    my @chain=splice @available,0,$blocks;
    for my $index (0..$#chain) {
        my ($t,$s)=@{$chain[$index]};
        $used{"$t,$s"}=1;
        my $chunk=substr($data,$index*254,254);
        my $link=$index<$#chain ? pack('CC',@{$chain[$index+1]}) : pack('CC',0,length($chunk)+1);
        put_sector($t,$s,$link.$chunk."\0"x(254-length($chunk)));
    }
    my $directory=int($entry/8);
    my $base=($entry%8)*32;
    $entry++;
    substr($directories[$directory],$base+2,3,pack('CCC',$type,@{$chain[0]}));
    substr($directories[$directory],$base+5,16,$name."\xa0"x(16-length($name)));
    substr($directories[$directory],$base+30,2,pack('v',$blocks));
}
for my $i (0..$#directories) { put_sector(18,$i+1,$directories[$i]); }
my $bam=pack('CCCC',18,1,0x41,0)."\0"x252;
for my $t (1..35) {
    my ($count,@bits)=(0,0,0,0);
    for my $s (0..$sectors[$t]-1) {
        next if $used{"$t,$s"};
        $count++;$bits[int($s/8)]|=1<<($s%8);
    }
    substr($bam,4*$t,4,pack('CCCC',$count,@bits));
}
substr($bam,144,16,'HURRICANE PROG8'."\xa0");
substr($bam,160,11,"\xa0\xa0HT\xa02A\xa0\xa0\xa0\xa0");
put_sector(18,0,$bam);
open my $out,'>:raw',$output or die "$output: $!";
print {$out} $disk;
close $out or die "$output: $!";
print "$output ($size bytes)\n";
