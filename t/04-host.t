#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Digest::SHA qw(sha256_hex);
my $temp=tempdir(CLEANUP=>1);
sub write_bytes { open my $f,'>:raw',$_[0] or die $!;print {$f} $_[1];close $f; }
sub read_bytes { open my $f,'<:raw',$_[0] or die $!;local $/;return <$f> // ''; }
sub command {
    my (@args)=@_;
    my $pid=fork();die $! unless defined $pid;
    if (!$pid) {
        open STDOUT,'>',"$temp/output" or die $!;
        open STDERR,'>&',\*STDOUT or die $!;
        exec $^X,'tools/disk.pl',@args;die $!;
    }
    waitpid($pid,0);return $?>>8;
}
write_bytes("$temp/prg",pack('v',0x0801).'P8');
write_bytes("$temp/storm","END\r");
ok(command()!=0,'reject missing arguments');
ok(command("$temp/no.d64","$temp/missing","$temp/storm")!=0,'reject missing input');
ok(!-e "$temp/no.d64",'failed build leaves no disk');
for my $bad ('../BAD','TOO-LONG-FILENAME-1','HAS SPACE','BAD,SEQ','') {
    ok(command("$temp/no.d64","$temp/prg","$temp/storm","$bad=$temp/storm")!=0,"reject unsafe name [$bad]");
}
ok(command("$temp/no.d64","$temp/prg","$temp/storm","HF.GILBERT=$temp/storm")!=0,'reject duplicate name');
write_bytes("$temp/huge","X"x180000);
ok(command("$temp/full.d64","$temp/huge","$temp/storm")!=0,'reject disk overflow');
ok(!-e "$temp/full.d64",'disk-full build leaves no partial image');

my @sizes=(0,1,253,254,255,507,508,509,4096,65535);
my @inputs=([$temp.'/prg','HURRICANE',0x82],[$temp.'/storm','HF.GILBERT',0x81]);
my @extra;
for my $i (0..$#sizes) {
    my $name=sprintf('HF.B%02d',$i);
    my $path="$temp/file$i";
    my $data=join('',map { chr(($_*37+$i)%256) } 0..$sizes[$i]-1);
    write_bytes($path,$data);
    push @inputs,[$path,$name,0x81];push @extra,"$name=$path";
}
is(command("$temp/a.d64","$temp/prg","$temp/storm",@extra),0,'build multi-directory boundary fixture');
is(command("$temp/b.d64","$temp/prg","$temp/storm",@extra),0,'repeat identical build');
my $disk=read_bytes("$temp/a.d64");
is(length($disk),174848,'fixed standard disk size');
is(sha256_hex($disk),sha256_hex(read_bytes("$temp/b.d64")),'byte-for-byte reproducible image');
my @sectors=(0,map { $_<=17 ? 21 : $_<=24 ? 19 : $_<=30 ? 18 : 17 } 1..35);
my @offset;my $n=0;
for (1..35) { $offset[$_]=$n;$n+=$sectors[$_]*256; }
sub sector {
    my ($t,$s)=@_;
    die "invalid sector $t/$s" unless $t>=1 && $t<=35 && $s<$sectors[$t];
    return substr($disk,$offset[$t]+$s*256,256);
}
my %used=('18,0'=>1);
my @entries;my ($t,$s)=(18,1);my $directory_count=0;
while ($t) {
    die 'directory cycle' if $used{"$t,$s"}++;
    my $d=sector($t,$s);$directory_count++;
    for my $i (0..7) {
        my $entry=substr($d,$i*32,32);
        push @entries,$entry if ord(substr($entry,2,1));
    }
    ($t,$s)=unpack('CC',$d);
}
is($directory_count,2,'directory extends past eight files');
is(scalar @entries,scalar @inputs,'all directory entries present');
for my $i (0..$#inputs) {
    my ($path,$name,$expected_type)=@{$inputs[$i]};
    my $entry=$entries[$i];
    my ($type,$t,$s)=unpack('CCC',substr($entry,2,3));
    is($type,$expected_type,"$name file type");
    (my $actual_name=substr($entry,5,16)) =~ s/\xa0+$//;
    is($actual_name,$name,"$name disk name");
    my $bytes='';my $blocks=0;
    while ($t) {
        die 'file overlaps an allocated sector' if $used{"$t,$s"}++;
        my $d=sector($t,$s);($t,$s)=unpack('CC',$d);$blocks++;
        $bytes.=$t ? substr($d,2) : substr($d,2,$s-1);
    }
    is($bytes,read_bytes($path),"$name bytes survive sector boundaries");
    is($blocks,unpack('v',substr($entry,30,2)),"$name block count");
}
my $bam=sector(18,0);
my $valid=1;
for my $t (1..35) {
    my ($expected_free,@bits)=unpack('CCCC',substr($bam,$t*4,4));
    my $free=0;
    for my $s (0..23) {
        my $bit=($bits[int($s/8)]>>($s%8))&1;
        if ($s<$sectors[$t]) {
            $free+=$bit;
            $valid=0 if $bit==!!$used{"$t,$s"};
        } else { $valid=0 if $bit; }
    }
    $valid=0 if $free!=$expected_free;
}
ok($valid,'BAM matches extended directory and every used/free/invalid sector');
done_testing();
