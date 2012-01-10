#!C:/strawberry/perl/bin/perl.exe

use HTML::Parser;
use Data::Dumper;
use LWP::UserAgent;
use strict;


my $ua = LWP::UserAgent->new;
my $response = $ua->get("http://www.tvsubtitles.net/tvshows.html");
my $insideSearchArea = 0;
my $insideLink = 0;

my $parser = HTML::Parser->new(api_version => 3);

$parser->handler(start => \&start, 'tagname, attr, self');
$parser->parse($response->content);

sub start
{
	local ($tagname, $attr, $parse) = @_;
	$insideSearchArea = ($tagname eq 'table' && $attr->{id} eq 'table5') unless $insideSearchArea;
	$insideLink = $tagname eq 'a' unless $insideLink;
	return unless ($insideLink && $insideSearchArea && $tagname eq 'a');
	print '<option value="', $attr->{href}, '">';
	$parse->handler(text => sub{if($insideLink){print shift,"</option>\n"}}, 'text');
	$parse->handler(end => sub{my ($tagname, $parse) = @_; $parse->eof if $tagname eq 'table'; $insideLink = ($tagname ne 'a') if $insideLink}, 'tagname, self');
}

