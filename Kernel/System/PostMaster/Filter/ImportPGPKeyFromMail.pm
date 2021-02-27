# --
# Copyright (C) 2017 - 2021 Perl-Services.de, http://perl-services.de
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

    # Try to get message & encryption method.
    my $Message;
    my $ContentType;
    my $EncryptionMethod = '';

    if ( $Mail{Body} =~ /\A[\s\n]*^-----BEGIN PGP MESSAGE-----/m ) {
        $Message          = $Mail{Body};
        $ContentType      = $Mail{'Content-Type'} || '';
        $EncryptionMethod = 'PGP';
    }
    else {
        CONTENT:
        for my $Content ( @{ $Mail{Attachment} } ) {
            if ( $Content->{Content} =~ /\A[\s\n]*^-----BEGIN PGP MESSAGE-----/m ) {
                $Message          = $Content->{Content};
                $ContentType      = $Content->{ContentType} || '';
                $EncryptionMethod = 'PGP';
                last CONTENT;
            }
        }
    }

    if ( $EncryptionMethod eq 'PGP' && $ContentType =~ m{application/(?: pgp | octet-stream )}xsm ) {

        my $CryptObject = $Kernel::OM->Get('Kernel::System::Crypt::PGP');

        my %Decrypt = $CryptObject->Decrypt( Message => $Message );

        return if !$Decrypt{Successful};

        my $ParserObject = Kernel::System::EmailParser->new( %{$Self}, Email => $Decrypt{Data} );

        $Mail{Attachment} = [ $ParserObject->GetAttachments() ];
    }

    return 1 if !$Mail{Attachment};

    my @KeyFiles = grep{ $_->{Filename} =~ m{\.asc \z}ismx }@{ $Mail{Attachment} };

    return 1 if !@KeyFiles;

    for my $KeyFile ( @KeyFiles ) {
        next if $KeyFile->{Content} =~ m{PGP \s+ SIGNATURE}xms;

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
