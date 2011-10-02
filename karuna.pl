#!/usr/bin/env perl

use strict;
use warnings;

use autodie qw/:all/;

use Data::Dumper;
use File::Basename 'dirname';
use File::Spec;

use lib join '/', File::Spec->splitdir( dirname(__FILE__) ), 'lib';

use Mojolicious::Lite;

use DBI;
DBI->trace(1);
use SQL::Interp qw/:all/;

app->defaults( layout => 'cam' );

helper da => sub {
    use Local::DB;

    my $da = Local::DB->new->da;
};

helper customer => sub {
    my ( $self, $email ) = @_;

    #die "E:$email:";

    $self->da->sqlrowhash( sql_interp "SELECT * FROM users WHERE email = ",
        \$email );
};

helper dumper => sub {
    my ( $self, @struct ) = @_;
    Dumper( \@struct );
};

plugin 'Authentication' => {
    'session_key' => 'wickedapp',
    'load_user'   => sub {
        my ( $self, $email ) = @_;
        $self->customer($email);
    },
    'validate_user' => sub {
        my ( $self, $email, $password, $extradata ) = @_;
        my $C = $self->customer($email);
        return undef unless scalar keys %$C;

        $password eq $C->{password} ? $email : undef;
    },
};

get '/' => sub {
    my $self = shift;

    my $msg;

    use Cwd;
    my $c = getcwd;

    app->log->debug("CWD:$c.");

    $self->render( template => 'index' );

};

get '/register' => sub {
    shift->render( template => 'register' );
};

get '/logout' => sub {
    my ($self) = @_;
    $self->logout;
    $self->redirect_to('/');
};

post '/register_eval' => sub {
    my $self = shift;

    my $E = $self->param('email');
    my $C = $self->customer($E);

    scalar keys %$C
      or return $self->render(
        text => sprintf "Email '%s' does not belong to a customer",
        $E
      );

    use Digest::SHA qw/sha512_base64/;
    my $P = sha512_base64( $self->param('password') );

    my $rows = $self->da->do(
        sql_interp(
            "UPDATE customers SET password=",
            \$P, "WHERE email = ", \$E
        )
    );

    $self->redirect_to('/');

};

under sub {
    my ($self) = @_;
    return 1
      if $self->authenticate( $self->param('email'), $self->param('password') );
    $self->redirect_to('/');
};

any '/root' => sub {
    my $self = shift;

    my $E = $self->param('email');
    my $U = $self->customer($E);

    warn $self->dumper( $E, $U );

        my $sponsored = $self->da->sqlarrayhash("
    SELECT
      *
    FROM
      users
    WHERE
      sponsor_id=$U->{id}
    "
        );

    $self->session->{user} = $U;

    $self->stash( user => $U );
    $self->stash( sponsored => $sponsored );
    $self->render( template => 'root' );

};

# Start the Mojolicious command system
app->secret('thc')->start;

__END__

=head1 NAME

store.pl - webstore

=head1 SYNOPSIS

  $ store.pl daemon --reload

=head1 DESCRIPTION

TBD.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
