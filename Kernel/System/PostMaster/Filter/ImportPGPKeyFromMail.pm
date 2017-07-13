# --
# Copyright (C) 2017 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::PostMaster::Filter::ImportPGPKeyFromMail;

use strict;
use warnings;

use Kernel::System::EmailParser;

use List::Util qw(first);

our @ObjectDependencies = qw(
    Kernel::System::Ticket
    Kernel::System::Log
    Kernel::System::Crypt::PGP
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{Debug} = $Param{Debug} || 0;

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $PGPObject    = $Kernel::OM->Get('Kernel::System::Crypt::PGP');

    my $UserID = $ConfigObject->Get('PostmasterUserID') || 1;

    # check needed stuff
    for my $Needed (qw(JobConfig GetParam)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message => "Need $Needed!",
            );
            return;
        }
    }

    my %Mail = %{ $Param{GetParam} || {} };

    return 1 if !$Mail{Attachment};

    my @KeyFiles = grep{ $_->{Filename} =~ m{\.asc \z}ismx }@{ $Mail{Attachment} };

    return 1 if !@KeyFiles;

    $LogObject->Log( Priority => error => Message => $Kernel::OM->Get('Kernel::System::Main')->Dump( \@KeyFiles ) );
    $LogObject->Log( Priority => error => Message => $Kernel::OM->Get('Kernel::System::Main')->Dump( $Mail{Attachment} ) );

    for my $KeyFile ( @KeyFiles ) {
        $PGPObject->KeyAdd(
            Key => $KeyFile->{Content},
        );
    }

    my $DynamicFieldName = $ConfigObject->Get('ImportPGPKeyFromMail::SetDynamicField');
    if ( $DynamicFieldName ) {
        $Param{GetParam}->{'X-OTRS-DynamicField-' . $DynamicFieldName} = 1;
    }

    return 1;
}

1;
