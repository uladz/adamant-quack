#!/usr/bin/env perl

#use strict;
#use warnings;
use YAML::XS;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

## Tab with # spaces.
my $opt_loot_file = "";
my $opt_loot_file2 = "";
my $opt_boss_file = "";
my $opt_exec = "";
my $opt_append = 0;
my $opt_man = 0;
my $opt_help = 0;

## Read and parse the tool command line.
GetOptions(
  "loot|l|i=s" => \$opt_loot_file,
  "loot2|l2|i2=s" => \$opt_loot_file2,
  "boss|output|b|i=s" => \$opt_boss_file,
  "exec|x=s" => \$opt_exec,
  "append|a" => \$opt_append,
  "help|?" => \$opt_help,
  "man" => \$opt_man)
  or pod2usage(2);
pod2usage(1) if $opt_help;
pod2usage(-exitval => 0, -verbose => 2) if $opt_man;

## Check inputs.
pod2usage("$0: LOOT input file is missing.") if $opt_loot_file eq "";

## Load master LOOT YAML file.
my $file = $opt_boss_file;
if ($file ne "") {
  print "Converting \"".$opt_loot_file."\"...\n";
}
my $ul = YAML::XS::LoadFile($opt_loot_file);

## Load and merge in second LOOT file.
my $ul2 = ();
my $replaced_cnt = 0;
if ($opt_loot_file2 ne "") {
  print "Merging in \"".$opt_loot_file2."\"...\n";
  $ul2 = YAML::XS::LoadFile($opt_loot_file2);
  for (@{$ul2->{plugins}}) {
    my $name2 = $_->{name};
    my $tags2 = $_->{tag};
    next unless defined $tags2;
    for (@{$ul->{plugins}}) {
      my $name = $_->{name};
      if ($name eq $name2) {
        if ($file ne "") {
          print "  + user tags \"".$name."\"\n";
        }
        $_->{tag} = ();
        $replaced_cnt++;
        last;
      }
    }
  }
}

## Output to a file or console if file is not specified.
my $f;
if ($file ne "") {
  open $f, ($opt_append ? ">>" : ">"), $file or die $!;
}
else {
  $f = *STDOUT;
}

## Convert LOOT file into BOSS file format.
my $input_cnt = 0;
my $output_cnt = 0;
for ((@{$ul->{plugins}}, @{$ul2->{plugins}})) {
  $input_cnt++;
  my $name = $_->{name};
  my $tags = $_->{tag};
  if (!defined $tags) {
    $ignored_cnt++;
    next;
  }
  print $f "$name"."\n";
  print $f " TAG: {{BASH: ";
  my $ptag = undef;
  for (@{$tags}) {
    print $f $ptag.", " if defined $ptag;
    if (ref($_) eq "HASH") {
      $ptag = $_->{name};
    }
    else {
      $ptag = $_;
    }
  }
  print $f $ptag if defined $ptag;
  print $f "}}"."\n";
  $output_cnt++;
}
if ($file ne "") {
  close $f;
  print "Output \"".$file."\":\n";
  print "  written ".$output_cnt." record(s)\n";
  print "  ignored ".$ignored_cnt." record(s)\n";
  print "  replaced ".$replaced_cnt." record(s)\n";
}

## Run external command after conversion.
if ($opt_exec ne "") {
  if ($file ne "") {
    print "Starting \"".$opt_exec."\"...\n";
  }
  system($opt_exec);
}
if ($file ne "") {
  print "Done.\n"
}

__END__

=head1 NAME

LOOT to BOSS file format converter.

=head1 SYNOPSIS

loot2boss [options]

=head1 OPTIONS

=over 8

=item B<-loot>

LOOT masterlist input file in YAML format.

=item B<-boss>

BOSS masterlist output file in text format. If not specified then output will
be printed to console.

=item B<-exec>

Program to execute after conversion. Does nothing if not specified.

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

This program will read the given input file in YAML format, which is expected
to be a LOOT generated masterfile, extract BASHed tags for all listed plugins 
and covert it into BOSS proprietary text file format, that is accaptable by
older version of Wrye Bash utility or its forked version like Wrye Flash.

=cut
