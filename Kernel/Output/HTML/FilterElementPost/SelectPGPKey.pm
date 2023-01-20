# --
# Copyright (C) 2017 - 2023 Perl-Services.de, https://www.perl-services.de/
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
            Core.Config.Set( 'SecuritySelectFunction', function() {
                var SecSelect = $('#EmailSecurityOptions');
                if ( !SecSelect.get(0) ) {
                    return;
                }
                else if ( Core.Config.Get('SecuritySelected') == 1 ) {
                    return;
                }

                var FormData = {
                    TicketID: $('input[name="TicketID"]').val(),
                    Dest: $('#Dest').val(),
                    Customers: new Array(), 
                };

                $('input[name^="CustomerQueue_"]').each( function( i, v ) {
                    FormData.Customers.push( $(v).val() );
                });

                $('input[name^="CcCustomerQueue_"]').each( function( i, v ) {
                    FormData.Customers.push( $(v).val() );
                });

                $.ajax({
                    type: 'POST',
                    url: Core.Config.Get('Baselink') + 'Action=AgentCheckPGPKeyExists',
                    data: {
                        SecData: JSON.stringify( FormData ),
                    },
                    success: function( response ) {
                        if ( response.KeyExists ) {
                            var SecSelect = $('#EmailSecurityOptions');
                            SecSelect.val( 'PGP::-::Encrypt' );
                            SecSelect.trigger('redraw.InputField');
                            Core.Config.Set('SecuritySelected', 1);
                        }
                    }
                });
            });

            var SelectFunction = Core.Config.Get( 'SecuritySelectFunction');
            Core.App.Ready( function() {
                SelectFunction();
            });

            Core.App.Subscribe( 'Event.AJAX.FormUpdate.Callback', Core.Config.Get( 'SecuritySelectFunction' ) );
        |,
    );

    return 1;
}

1;
