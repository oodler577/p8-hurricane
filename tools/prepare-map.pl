#!/usr/bin/env perl
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use JSON::PP;
my $source=shift or die "usage: $0 ORIGINAL_HUR1.prg\n";
open my $f,'<:raw',$source or die $!;local $/;my $original=<$f>;
die 'expected original HUR1 graphics file' unless length($original)==10004 && substr($original,0,2) eq "\0\x80";
my $payload=substr($original,2);
my ($bitmap,$matrix)=('','');
for my $cell (0..999) {
    my $screen=ord(substr($payload,8000+$cell,1));
    my @colors=(1,$screen>>4,$screen&15,ord(substr($payload,9000+$cell,1))&15);
    # Match the photographed cyan land/grid while retaining the original pixels.
    @colors=map { $_==5 ? 3 : $_ } @colors;
    my @rows;my %frequency;
    for my $y (0..7) {
        my $byte=ord(substr($payload,$cell*8+$y,1));
        my @pixels;
        for my $pair (0..3) {
            my $color=$colors[($byte>>(6-$pair*2))&3];
            push @pixels,$color,$color;$frequency{$color}+=2;
        }
        push @rows,\@pixels;
    }
    # VIC-II hires permits two colours in each 8x8 cell. Preserve the two
    # dominant original colours; only crowded coastline/title cells are reduced.
    my @rank=sort { $frequency{$b}<=>$frequency{$a} || $a<=>$b } keys %frequency;
    my $bg=$rank[0];my $fg=$rank[1]//($bg==6 ? 3 : 6);
    $matrix.=chr(($fg<<4)|$bg);
    for my $row (@rows) {
        my $byte=0;
        for my $x (0..7) { $byte|=128>>$x if $row->[$x]==$fg; }
        $bitmap.=chr($byte);
    }
}
sub packbits {
    my ($raw)=@_;my $out='';my $i=0;
    while ($i<length($raw)) {
        my $run=1;
        $run++ while $run<128 && $i+$run<length($raw) && substr($raw,$i,1) eq substr($raw,$i+$run,1);
        if ($run>=3) { $out.=chr(257-$run).substr($raw,$i,1);$i+=$run;next; }
        my $start=$i;$i+=$run;
        while ($i<length($raw) && $i-$start<128) {
            my $r=1;
            $r++ while $r<3 && $i+$r<length($raw) && substr($raw,$i,1) eq substr($raw,$i+$r,1);
            last if $r>=3;
            $i++ ;
        }
        $out.=chr($i-$start-1).substr($raw,$start,$i-$start);
    }
    return $out;
}
mkdir 'data/artwork' unless -d 'data/artwork';
for my $item (['bitmap',$bitmap],['matrix',$matrix]) {
    open my $out,'>:raw',"data/artwork/map-$item->[0].rle" or die $!;
    my $encoded=packbits($item->[1]);print {$out} $encoded;
    print "$item->[0]: ",length($item->[1])," -> ",length($encoded)," bytes\n";
}
open my $manifest,'>','data/artwork/provenance.json' or die $!;
print {$manifest} JSON::PP->new->canonical->pretty->encode({
    original_title=>"Skipper Jim's Hurricane Tracking Chart",
    original_author=>'James R. Brown',
    source_file=>'HUR1 (from the user-supplied original D64)',
    source_sha256=>sha256_hex($original),
    transformation=>'Original bitmap expanded from multicolour, green mapped to cyan, two dominant colours retained per hires cell, PackBits compressed. No original executable code included.',
    bitmap_sha256=>sha256_hex($bitmap),
    matrix_sha256=>sha256_hex($matrix)
});
