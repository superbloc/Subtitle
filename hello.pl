#!C:/strawberry/perl/bin/perl.exe

use strict;
use CGI qw(escapeHTML);

my $cgi = CGI->new;

print $cgi->header;
print "<h1>coucou</h1>";
