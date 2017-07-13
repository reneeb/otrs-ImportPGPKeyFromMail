# --
# Copyright (C) 2017 Perl-Services.de, http://www.perl-services.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterElementPost::SelectPGPKey;

use strict;
use warnings;

use List::Util qw(first);

our @ObjectDependencies = qw(
    Kernel::Output::HTML::Layout
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{UserID} = $Param{UserID};

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # get template name
    my $Templatename = $Param{TemplateFile} || '';
    return 1 if !$Templatename;
    return 1 if !$Param{Templates}->{$Templatename};

    $LayoutObject->AddJSOnDocumentComplete(
        Code => q|
            Core.Config.Set( 'PGPKeySelectFunction', function() {
                var PGPSelect = $('#CryptKeyID');
                if ( !PGPSelect.get(0) ) {
                    return;
                }
                else if ( Core.Config.Get('PGPKeySelected') == 1 ) {
                    return;
                }

                var CryptOptions = $('#CryptKeyID option');
                if ( CryptOptions.length == 2 && CryptOptions[1].value.match( /^PGP::Detached/ ) ) {
                    PGPSelect.val( CryptOptions[1].value );
                    PGPSelect.trigger('redraw.InputField');
                    $('#CryptKeyID_Search ~ div > div[class="Remove"] > a').bind( 'click', function() {
                        Core.Config.Set('PGPKeySelected', 1);
                    });
                }
            });

            var SelectFunction = Core.Config.Get( 'PGPKeySelectFunction');
            SelectFunction();

            Core.App.Subscribe( 'Event.AJAX.FormUpdate.Callback', Core.Config.Get( 'PGPKeySelectFunction' ) );
        |,
    );

    return 1;
}

1;
