#!/usr/bin/perl

use strict;
use warnings;

sub create_tmp_dir{
  `mkdir -p tmp/`;
}

sub convert_file_to_linux{
  my ($filename) = @_;
  my $cmd = "cat $filename | iconv -f sjis -t utf8 | tr \$'\x0d' \$'\n' > tmp/$filename.uft8";
  `$cmd`; 
}

sub get_schema_info{
  my ($schema_file) = @_;
  open my $fh,"<".$schema_file;
  my $line = <$fh>;
  chomp $line;
  return (split(/\t/,$line,-1));
}

sub main{
  if(@ARGV != 2){
    die('./bin/convert.pl <filename> <schema>');
  }

  my ($csv_file,$schema_file) = ($ARGV[0],$ARGV[1]);

  create_tmp_dir();
  convert_file_to_linux($csv_file);
  my @columns = get_schema_info($schema_file);

  use Data::Dumper;
  print Dumper(@columns);

  return 1;
}

&main;
