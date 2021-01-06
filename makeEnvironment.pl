#!/usr/bin/perl
use strict;
use JSON;
use MIME::Base64;
use File::Path;
use Scalar::Util qw(reftype);
use utf8;

my $resourceBase  = "_resources.json";
my $inputFile     = $ARGV[0];
(my $resourceFile = $inputFile) =~ s/(\.)[^.]*/$resourceBase/;

die ("You must supply an input file.")                      unless $inputFile;
die ("The supplied input file '$inputFile' does not exist") unless -f $inputFile;

my $deckData      = decode_json(loadData($inputFile));
my $resourceData  = decode_json(loadData($resourceFile));
my $global        = getGlobals($resourceData); 
my $template      = loadTemplate($global->{'environmentTemplate'});
my $substitutions = loadSubstitutionTable() ;
my $exportArea    = $global->{'extraBleed'} ? 'extraBleedBox' : 'cardborder';

for my $card ( @{$deckData->{'cards'}}) {
	my $resources;
	my $id = $card->{'identifier'};

	if ( defined ($resourceData->{$id}) ) {
		$resources = $resourceData->{$id};
	}
	my $thisCardData = makeSubstitutions($template,$card,$resources,$substitutions,$resourceData->{'artBy'},$global->{'resourceDir'});
	my $cardSVGFileName = $global->{'svgDir'} . $card->{'identifier'} . '.svg';
	open CARDOUT,">$cardSVGFileName";
	binmode (CARDOUT, ":utf8");
	print CARDOUT $thisCardData;
	close CARDOUT;

	my $cardPNGFileName = $global->{'pngDir'} . $card->{'identifier'} . '_qty' . $card->{'count'} . '.png';
	my $cmd = 'inkscape -g --actions="select:cardName;StrokeToPath;export-id:' . $exportArea . ';export-type:png;export-filename:' . $cardPNGFileName. ';export-do;FileSave;FileQuit" ' . $cardSVGFileName;
	print "Running command '$cmd'\n";
	if ( open CMD,"$cmd 2>&1|" ) {
		while ( my $line = <CMD> ) {
			print $line;
		}
	} else {
		print "Unable to execute '$cmd' : $!\n";
	}
}

#######################
##### Subroutines #####
#######################
sub loadData($) {
	my $deckDataFile = shift;

	if ( $deckDataFile =~ m/^\s*$/ ) {
		print "You must supply a suitable input file\n";
		exit;
	}
	my $deckDataContents;
	open my $dataHandle, '<', $deckDataFile or die "Can't open template file '$deckDataFile' : $!";
	read($dataHandle, $deckDataContents, -s $dataHandle);	
	return($deckDataContents);
}

sub loadTemplate($) {
	my $templateFile = shift;
	my $templateContents;
	my $templateHandle;

	open my $templateHandle, '<', $templateFile or die "Can't open template file '$templateFile' : $!";
	read($templateHandle, $templateContents, -s $templateHandle);	
	return($templateContents);
}

sub loadSubstitutionTable() {
	my $table;
	my $base;
	my $font = '<flowSpan style="-inkscape-font-specification:HeroesAndVillains;font-family:HeroesAndVillains;font-weight:normal;font-style:normal;font-stretch:normal;font-variant:normal;fill:#COLOR" id="flowSpan1985">SUBSTITUTE</flowSpan>';

	## Black Icons	
	($base = $font) =~ s/COLOR/000000/;
	($table->{'multiply'} = $base) =~ s/SUBSTITUTE/chr hex '0d7'/ge;;

	## Bluie Icons
	($base = $font) =~ s/COLOR/0000FF/;
	($table->{'hicon'} = $base)    =~ s/SUBSTITUTE/chr hex 124/ge;
	return($table);
}

sub makeSubstitutions($$$$) {
	my $thisCardData = shift;
	my $card         = shift;
	my $resources    = shift;
	my $table        = shift;
	my $globalArtBy  = shift;
	my $imageDir     = shift;	
	
	my $artBy = defined($resources->{'artBy'}) ? $resources->{'artBy'} : $globalArtBy;
	$card->{'flavorText'} =~ s/{br}/ /gi;

	$thisCardData =~ s/{TITLE}/$card->{'title'}/;
	
	if ( reftype($card->{'body'}) eq 'ARRAY' ) {
		my $count = 1;
		my $bodyBlock;
		for my $bodyLine ( @{$card->{'body'}} ) {
			$bodyBlock .= qq|<flowPara id="body$count" style="font-size:5.14px">$bodyLine</flowPara>\n<flowPara style="font-size:5.14px" id="newline$count"/>|;
			$count++;
		}
		
		$thisCardData =~ s/<flowPara id="body1" style="font-size:5.14px">{BODY} <\/flowPara>/$bodyBlock/;
	} else {
		$thisCardData =~ s/{BODY}/$card->{'body'}/;	
	}
	

	$thisCardData =~ s/{FLAVOR}/$card->{'flavorText'}/;
	if ($artBy !~ m/^\s*$/) {
		$thisCardData =~ s/{ART_BY_DISPLAY}/inline/;
		$thisCardData =~ s/{ART_BY}/$artBy/;
	}

	if ( defined $card->{'hitpoints'} ) {
		$thisCardData =~ s/{HP_DISPLAY}/inline/;
		$thisCardData =~ s/{HP}/$card->{'hitpoints'}/;
	} else {
		$thisCardData =~ s/{HP_DISPLAY}/none/;
	}
	if ( $card->{'keywords'} ) {
		my $keywordList = join(',',@{$card->{'keywords'}});
		$thisCardData =~ s/{KEYWORD_DISPLAY}/inline/;
		$thisCardData =~ s/{KEYWORDS}/$keywordList/;
	} else {
		$thisCardData =~ s/{KEYWORD_DISPLAY}/none/;
	}
	
	if ( $resources->{'image'} ) {
		my $imageData = getBase64($imageDir . $resources->{'image'});
		$thisCardData =~ s/{{CARD_IMAGE_DISPLAY}}/inline/;
		$thisCardData =~ s/{CARD_IMAGE_BASE64}/$imageData/;
	} else {
		$thisCardData =~ s/{{CARD_IMAGE_DISPLAY}}/none/;
	}

	$thisCardData =~ s/{[hH]\s*\*\s*(\d+)}/{H}$table->{'multiply'}$1/g;
	$thisCardData =~ s/{[hH]\s*([\-\+])\s*(\d+)}/{H}$1$2/g;
	$thisCardData =~ s/{[hH]}/$table->{'hicon'}/g;

	return($thisCardData);
}

sub getBase64($) {
	my $imageFile = shift;

	my $imageContents;
	open my $imageHandle, '<', $imageFile or die "Can't image template file '$imageFile' : $!";
	binmode $imageHandle;
	read($imageHandle, $imageContents, -s $imageHandle);
	return(encode_base64($imageContents));
}

sub getGlobals($) {
	my $resrouceData = shift;
	my $settings = decode_json(loadData('global.json'));

	for my $item ( keys(%{$resourceData}) ) {
		next if reftype($resourceData->{$item}) eq 'HASH';
		$settings->{$item} = $resourceData->{$item};
	}
	
	if ( $settings->{'svgDir'} ) {
		$settings->{'svgDir'} =~ s/\\/\//g;
		mkpath($settings>{'svgDir'}) unless -d $settings->{'svgDir'};
	}
	if ( !	($settings->{'svgDir'}  && -d $settings->{'svgDir'}) ) {
		$settings->{'svgDir'} = '.';
	}
	$settings->{'svgDir'} .= '/' unless $settings->{'svgDir'} =~ m/\/$/;

	if ( $settings->{'pngDir'} ) {
		$settings->{'pngDir'} =~ s/\\/\//g;
		mkpath($settings->{'pngDir'}) unless -d $settings->{'pngDir'};
	}
	if ( ! ($settings->{'pngDir'}  && -d $settings->{'pngDir'}) ) {
		$settings->{'pngDir'} = '.';
	}
	$settings->{'pngDir'} .= '/' unless $settings->{'pngDir'} =~ m/\/$/;
	
	if ( $settings->{'resourceDir'} ) {
		$settings->{'resourceDir'} =~ s/\\/\//g;
	}
	if ( ! ($settings->{'resourceDir'}  && -d $settings->{'resourceDir'}) ) {
		die "Unable to locate resource directory " . $settings->{'resourceDir'} . "\n";
	}
	$settings->{'resourceDir'} .= '/' unless $settings->{'resourceDir'} =~ m/\/$/;
	
	return($settings);
}
