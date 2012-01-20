#!C:/strawberry/perl/bin/perl.exe

use strict;
use CGI qw(escapeHTML);

my $cgi = CGI->new;
my $value = $cgi->param('data');
my @wordList = ("a", "abac", "abbe", "abalone", "crise", "suite", "toto", "titi");

if(defined $value && !($value =~ /^\s+$/gi)){
	my @result = map {"'" . $_ . "'"} grep {/^$value/gi} @wordList;
	print $cgi->header;
	print "[", join(',', @result), "]";
}
