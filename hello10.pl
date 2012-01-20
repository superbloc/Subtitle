#!C:/strawberry/perl/bin/perl.exe

use strict;
use CGI qw(escapeHTML);

my $cgi = CGI->new;

print $cgi->header;
sleep(10);
print "<h1>coucou avec 10 secondes de retard</h1>";
