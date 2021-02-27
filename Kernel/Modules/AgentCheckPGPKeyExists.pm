# --
# Copyright (C) 2016 - 2021 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentCheckPGPKeyExists;

use strict;
use warnings;

use Mail::Address;

use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get ticket object
    my $LogObject       = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject      = $Kernel::OM->Get('Kernel::System::Main');
    my $JSONObject      = $Kernel::OM->Get('Kernel::System::JSON');
    my $ParamObject     = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject    = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');


    my $Data = $JSONObject->Decode(
        Data => $ParamObject->GetParam( Param => 'SecData' ) // '{}'
    );

    if ( !$Data || !$Data->{Customers} || !@{ $Data->{Customers} || [] } || !$ConfigObject->Get('PGP') ) {
        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => '{}',
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    my $PGPObject = $Kernel::OM->Get('Kernel::System::Crypt::PGP');

    my @SearchAddresses = ();
    for my $Customer ( @{ $Data->{Customers} || [] } ) {
        push @SearchAddresses, Mail::Address->parse($Customer);
    }

    my %Result;

    ADDRESS:
    for my $Address ( @SearchAddresses ) {
        my @PublicKeys = $PGPObject->PublicKeySearch(
            Search => $Address->address(),
        );

        if ( @PublicKeys ) {
            $Result{KeyExists} = 1;
            last ADDRESS;
        }
    }

    return $LayoutObject->Attachment(
        ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
        Content     => $JSONObject->Encode( Data => \%Result ),
        Type        => 'inline',
        NoCache     => 1,
    );

}

1;
