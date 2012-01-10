#!C:/strawberry/perl/bin/perl.exe

use strict;
use CGI qw(escapeHTML);
use Data::Dumper;
use LWP::UserAgent;
use HTML::Parser;
use Archive::Extract;
use HTML::Template;
use URL::Encode qw(url_encode);

my $cgi = CGI->new;
my $subtitleSite = 'http://www.tvsubtitles.net';
my $searchValue = $cgi->param('tvshow');
my $catalog = "tvshows.html";
my $insideSearchArea = 0;
my $insideLink = 0;
my @optionList = ();

my $ua = LWP::UserAgent->new(max_redirect => 0);

print $cgi->header();
my $template = HTML::Template->new(filename => 'subtitle.html');
&getAllCatalog();
$template->param(catalogue => \@optionList);

if(defined $searchValue && !($searchValue =~ /^\s*$/gi)){
	$template->param(SEARCHING => 1);
	$template->param(search_value => escapeHTML($searchValue));
	my $downloadLink = escapeHTML($searchValue);
	$downloadLink =~ s/tvshow/download/gi;
	$downloadLink =~ s/\./-fr\./gi;
	#print "${subtitleSite}/$downloadLink<br/>\n";
	
	my $resp = $ua->head("${subtitleSite}/$downloadLink");
	#print $resp->status_line, "<br/>\n";
	
	my $fileLocation = $resp->header('Location');
	$fileLocation =~ m/[\w\/\-\s_]+\/([\w\.\-\s_]+)$/gi;
	my $filename = $1;
	$filename =~ m/([\w\.\-\s_]+)\..+$/gi;
	my $fileDirectory = $1;
	
	#print "filename : ", $filename, "<br/>\n";
	
	unless (-d $fileDirectory){
	
	$resp = $ua->get("${subtitleSite}/$fileLocation");
	#print $resp->status_line, "<br/>\n";
	open my $FH, "> $filename" or die "unable to create file $filename\n";
	binmode $FH;
	print $FH $resp->content;
	close $FH;
	
	
	my $archive = Archive::Extract->new(archive => $filename);
	unlink $filename if($archive->extract(to => $fileDirectory));
	}
	
	opendir my $DFH, "$fileDirectory" or die "unable to open directory $fileDirectory\n";
	my @tab = grep {-f "$fileDirectory/$_"} readdir($DFH);
	close $DFH;
	
	my @subtitleList = ();
	map {push @subtitleList, {subtitle_file => escapeHTML($_), subtitle_view => "subtitleView.pl?fileName=" . url_encode(escapeHTML($_)) . "&fileDir=".url_encode($fileDirectory)}} @tab;
	$template->param(subtitles => \@subtitleList);
}

print $template->output;

sub getAllCatalog
{
	my $response = $ua->get("${subtitleSite}/$catalog");
	my $parser = HTML::Parser->new(api_version => 3);
	$parser->handler(start => \&start1, 'tagname, attr, self');
	$parser->parse($response->content);
}

sub start
{
	my ($tagname, $attr, $parse) = @_;
	$insideSearchArea = ($tagname eq 'table' && $attr->{id} eq 'table5') unless $insideSearchArea;
	$insideLink = $tagname eq 'a' unless $insideLink;
	return unless ($insideLink && $insideSearchArea && $tagname eq 'a');
	print '<option value="', $attr->{href}, '">';
	$parse->handler(text => sub{if($insideLink){print shift,"</option>\n"}}, 'text');
	$parse->handler(end => sub{my ($tagname, $parse) = @_; $parse->eof if $tagname eq 'table'; $insideLink = ($tagname ne 'a') if $insideLink}, 'tagname, self');
}

sub start1
{
	my ($tagname, $attr, $parse) = @_;
	my %hash = ();
	$insideSearchArea = ($tagname eq 'table' && $attr->{id} eq 'table5') unless $insideSearchArea;
	$insideLink = $tagname eq 'a' unless $insideLink;
	return unless ($insideLink && $insideSearchArea && $tagname eq 'a');
	$hash{'cat_value'} = $attr->{href};
	$parse->handler(text => sub{if($insideLink){$hash{'cat_label'}=escapeHTML(shift)}}, 'text');
	$parse->handler(end => sub{my ($tagname, $parse) = @_; $parse->eof if $tagname eq 'table'; $insideLink = ($tagname ne 'a') if $insideLink}, 'tagname, self');
	push @optionList, \%hash;
}