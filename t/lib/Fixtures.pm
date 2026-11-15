package Fixtures;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK=qw(cases write_cases);
sub cases {
    my $record="07 PM 09 10 1988\r80\r66.5\r15.7\r0\r";
    my $valid=$record."END\r";
    my @cases=(
        ['CR',$valid,1,1],
        ['LF',($valid =~ s/\r/\n/gr),1,1],
        ['CRLF',($valid =~ s/\r/\r\n/gr),1,1],
        ['no final newline',($valid =~ s/\r$//r),1,1],
        ['whitespace after END',$valid." \r\n",1,1],
        ['END directly after latitude',($valid =~ s/0\rEND/END/r),1,1],
        ['empty file','',0,0],
        ['missing END',$record,0,0],
        ['END without observation',"END\r",0,0],
        ['hour 13',($valid =~ s/^07/13/r),0,0],
        ['February 30',($valid =~ s/09 10 1988/02 30 1988/r),0,0],
        ['fractional wind',($valid =~ s/\r80\r/\r80.5\r/r),0,0],
        ['wind above bound',($valid =~ s/\r80\r/\r301\r/r),0,0],
        ['west below map',($valid =~ s/66.5/44.9/r),0,0],
        ['west above map',($valid =~ s/66.5/110.1/r),0,0],
        ['north below map',($valid =~ s/15.7/4.9/r),0,0],
        ['north above map',($valid =~ s/15.7/45.1/r),0,0],
        ['coordinate junk',($valid =~ s/66.5/66.5JUNK/r),0,0],
        ['overlong line',("X"x41)."\rEND\r",0,0],
        ['embedded NUL',($valid =~ s/66.5/66\0.5/r),0,0],
        ['high-bit input',($valid =~ s/66.5/66\x80.5/r),0,0],
        ['nonzero separator',($valid =~ s/\r0\r/\r1\r/r),0,0],
        ['junk after END',$valid."JUNK\r",0,0],
        ['second END',$valid."END\r",0,0],
        ['leading blank',"\r".$valid,0,0],
        ['129 observations',($record x 129)."END\r",0,0],
        ['exactly full import buffer',("X"x8192),0,0],
        ['oversized import buffer',("X"x8193),0,0],
        ['128 observations',($record x 128)."END\r",1,128],
        ['truncated record',"07 PM 09 10 1988\r80\r66.5\r",0,0],
        ['trailing zero precision',($valid =~ s/15.7/15.70/r),1,1],
        ['unsupported precision',($valid =~ s/15.7/15.71/r),0,0],
        ['blank between records',$record."\r".$valid,0,0],
        ['all map and wind lower bounds',($valid =~ s/80\r66.5\r15.7/0\r45\r5/r),1,1],
        ['all map and wind upper bounds',($valid =~ s/80\r66.5\r15.7/300\r110\r45/r),1,1],
        ['negative wind',($valid =~ s/\r80\r/\r-1\r/r),0,0],
    );
    return @cases;
}
sub write_cases {
    my ($dir)=@_;
    my @cases=cases();
    for my $i (0..$#cases) {
        open my $f,'>:raw',sprintf('%s/hf.c%02d',$dir,$i) or die $!;
        print {$f} $cases[$i][1];
    }
    return @cases;
}
1;
