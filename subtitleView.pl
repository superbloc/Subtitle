#!C:/strawberry/perl/bin/perl.exe

use strict;
use CGI qw(escapeHTML);
use URL::Encode qw(url_decode);

my $cgi = CGI->new;
my $fileName = $cgi->param("fileName");
my $fileDir = $cgi->param("fileDir");

print $cgi->header;
print $cgi->start_html;

if(defined $fileName && !($fileName =~ /^\s+$/gi)){
	my $file = url_decode($fileName);
	my $directory = url_decode($fileDir);
	#print "'$directory'/'$fileName'\n";
	open my $FH, "<$directory/$fileName" or die "Unable to open $fileName\n";
	while(<$FH>){
		chomp;
		print $_, "<br/>";
	}
	close $FH;
}

print $cgi->end_html;