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

#app->defaults( layout => 'cam' );

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

        if ( $password eq $C->{password} ) {
            $self->session->{user} = $C;
            $email;
        }
        else {
            undef;
        }
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
    shift->render( template => 'registercode' );
};

post '/registerflower' => sub {
    my ($self) = @_;

    my $email = $self->param('email');

    my $row = $self->da->sqlrowhash( "
    SELECT
      *
    FROM
      users
    WHERE
      email='$email'
    "
    );

    app->log->debug( $self->dumper( ROW => $row ) );

    if ( scalar keys %$row ) {
        $self->render( template => 'register', %$row );
    }
    else {
        $self->redirect_to('/');
    }
};

get '/logout' => sub {
    my ($self) = @_;
    $self->logout;
    $self->redirect_to('/');
};

post '/register_eval' => sub {
    my $self = shift;

    my @param = $self->param;
    my %param = map { $_ => $self->param($_) } @param;

    delete $param{password_again};

    my $rows = $self->da->do( sql_interp( "INSERT INTO users", \%param ) );

    $self->redirect_to('/');

};

under sub {
    my ($self) = @_;
    return 1
      if (
        $self->authenticate( $self->param('email'), $self->param('password') )
        or $self->session->{user} );
    app->log->debug('Authentication FAILED');
    $self->redirect_to('/');
};

any '/root' => sub {
    my $self = shift;

    my $U = $self->session->{user};
    warn $self->dumper($U);

    my $sponsored = $self->da->sqlarrayhash( "
    SELECT
      *
    FROM
      users
    WHERE
      sponsor_id=$U->{id}
    "
    );

    $self->stash( user      => $U );
    $self->stash( sponsored => $sponsored );
    $self->render( template => 'root' );

};

any '/view/:id' => sub {
    my ($self) = @_;

    my $id = $self->param('id');

    my $viewed = $self->da->sqlrowhash( "
    SELECT
      *
    FROM
      users
    WHERE
      id=$id
    "
    );

    my $sponsored = $self->da->sqlarrayhash( "
    SELECT
      *
    FROM
      users
    WHERE
      sponsor_id=$id
    "
    );

    $self->stash( user      => $viewed );
    $self->stash( sponsored => $sponsored );
    $self->render( template => 'view' );

};

any '/add' => sub {
    my ($self) = @_;

    my $U = $self->session->{user};

    # my $viewed = $self->da->sqlrowhash( "
    # SELECT
    #   *
    # FROM
    #   users
    # WHERE
    #   id=$id
    # "
    # );

    # my $sponsored = $self->da->sqlarrayhash( "
    # SELECT
    #   *
    # FROM
    #   users
    # WHERE
    #   sponsor_id=$id
    # "
    # );

    # $self->stash( user      => $viewed );
    # $self->stash( sponsored => $sponsored );
    $self->render( template => 'add' );

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
