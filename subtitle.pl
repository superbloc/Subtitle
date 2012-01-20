#!C:/strawberry/perl/bin/perl.exe

use strict;
use CGI qw(escapeHTML);
use Data::Dumper;
use LWP::UserAgent;
use HTML::Parser;
use Archive::Extract;
use HTML::Template;
use URL::Encode qw(url_encode);
use XML::Simple;

my $cgi = CGI->new;
my $subtitleSite = 'http://www.tvsubtitles.net';
my $dataDirectory = 'subtitles';
my $searchValue = $cgi->param('tvshow');
my $season = $cgi->param('season');
my $seasonSearchValue = $cgi->param('tv');
my $catalog = "tvshows.html";
my $insideSearchArea = 0;
my $insideLink = 0;
my @optionList = ();

my $ua = LWP::UserAgent->new(max_redirect => 0);

print $cgi->header();
my $template = HTML::Template->new(filename => 'subtitle.html');

unless (-f "$dataDirectory/tvShows.txt"){
	&getAllCatalog();
	&saveTvShowList();
}
@optionList = @{&getTvShowList()};

$template->param(catalogue => \@optionList);

if(defined $searchValue && !($searchValue =~ /^\s*$/gi)){
	if(defined $season && !($season =~ /^\s*$/gi)){
		$searchValue =~ s/(tvshow-\d+-)(\d+)(\.html)/${1}${season}${3}/gi;
	}
	$template->param(SEARCHING => 1);
	$template->param(search_value => escapeHTML($searchValue));
	my $downloadLink = escapeHTML($searchValue);
	$downloadLink =~ s/tvshow/download/gi;
	$downloadLink =~ s/\./-fr\./gi;
	
	my $resp = $ua->head("${subtitleSite}/$downloadLink");
	
	my $fileLocation = $resp->header('Location');
	$fileLocation =~ m/[\w\/\-\s_]+\/([\w\.\-\s_]+)$/gi;
	my $filename = $1;
	$filename =~ m/([\w\.\-\s_]+)\..+$/gi;
	my $fileDirectory = "${dataDirectory}/$1";
	
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

sub saveTvShowList
{	
	open my $FH, "> ${dataDirectory}/tvShows.txt" or die "unable to open ${dataDirectory}/tvShows.txt\n";
	foreach(@optionList){
		print $FH $_->{'cat_label'}, "@", $_->{'cat_value'},"\n";
	}
	close $FH;
}

sub getTvShowList
{
	open my $FH, "< ${dataDirectory}/tvShows.txt" or die "unable to open ${dataDirectory}/tvShows.txt\n";
	my @tvShowList = ();
	while(<$FH>){
		chomp;
		my @datas = split '@';
		push @tvShowList, {"cat_value" => $datas[1], "cat_label" => $datas[0]};
	}
	close $FH;
	return \@tvShowList;
}