# SotMCardBuilder

Requirements:

The folling software must be installed:
    - Perl
    - Inkscape

The following Perl modules must be installed:
    - JSON;
    - MIME::Base64;
    - File::Path;
    - Scalar::Util qw(reftype);

Of these, JSON may be the only one that is not a core module.  Any missing 
modules can be found on CPAN (https://www.cpan.org/) and installed using 
your preferred Perl Package Manager.  If you are not familiar with CPAN and 
perl modules, check out https://www.cpan.org/modules/INSTALL.html.

The following font from the resources directory in this repository must be 
installed:
    - HeroesAndVillains.ttf

The following fonts must be installed.  They are available from Blambot 
(https://blambot.com/) under certain conditions.
    - Red State Blue State
    - Crash Landing
    - Armor Piercing


Usage:

Place makeEnvironment.pl, global.json and EnvironmentDeck.TEMPLATE.svg in
the same directory.  Create an input file based on the formatting used
by the SotM Steam Workshop Engine Documentation (link provided below) and
run the following command:

	perl makeEnvironment.pl INPUT_JSON

THe SotM Steam Workshop Engine documentation can be found at:	
https://docs.google.com/document/d/e/2PACX-1vRvUNq-KAWwLdvQmhjpFp-dC6s7ZJqogQJFIFfCZrhJ6_kuS9yi5KG-OmEU3g2NqsB0zkMS0KPtTC5V/pub#h.2j9mjytugv41.

Not all fields in the above document are required.  See the sample files 
for the minimum required fields.

If images are desired on the final cards you must also create a resources 
JSON file, which shares the same base name as the input JSON file, but instead 
ends with '_resources.json'.   See the sample files for an example.


