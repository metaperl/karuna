package Local::DBIx::DBH;

use strict;
use warnings;

use base qw(DBIx::DBH);


sub fluxflex {

    $main::sharedssl      = 'disable';
    my $port = 3306;

    my $host = 'karuna.mysql.fluxflex.com';
    my $username = 'karuna';
    my $password = 'ghOwJ266QgI';

    my $config = DBIx::DBH->new(

        username => $username,
        password => $password,

        dsn => {
            driver  => 'mysql',
            dbname  => 'karuna',
            port    => $port,
            host    => $host,
        },
        attr => { RaiseError => 1 }
    );
}


sub pgshared {

    $main::sharedssl      = 'disable';
    my $port = $main::sharedport || 5432;

    my $host = $main::sharedhost || 'localhost';
    my $username = $main::sharedusername || 'postgres';
    my $password = $main::sharedpassword || 'postgres';

    my $config = DBIx::DBH->new(

        username => $username,
        password => $password,

        dsn => {
            driver  => 'Pg',
            dbname  => 'biotrackthc',
            port    => $port,
            sslmode => $main::sharedssl,
            host    => $host,
        },
        attr => { RaiseError => 1 }
    );
}

1;
