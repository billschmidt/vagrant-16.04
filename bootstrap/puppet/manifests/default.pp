include nginx

class sethostname {
    file { "/etc/hostname":
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0644',
        content => "${fqdn}\n",
        notify  => Exec["set-hostname"],
    }
    exec { "set-hostname":
        command => '/bin/hostname -F /etc/hostname',
        unless  => "/usr/bin/test `hostname` = `/bin/cat /etc/hostname`",
    }
}

class sshconfig {
    # the public key for the vagrant insecure key
    file { "/home/ubuntu/.ssh/authorized_keys":
        ensure => file,
        owner => ubuntu,
        group => ubuntu,
        mode => 'a=,u=rw',
        content => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key",
    }
}

include sethostname, sshconfig

# all the PHP stuff
class { '::php::globals':
    php_version => '7.1',
}->
class { '::php':
    ensure       => latest,
    manage_repos => true,
    fpm          => true,
    composer     => true,
    pear         => true,
    settings     => {
        'PHP/post_max_size'       => '128M',
        'PHP/upload_max_filesize' => '64M',
        'Date/date.timezone'      => 'America/Chicago'
    },
    extensions   => {
        curl     => { },
        gd       => { },
        intl     => { },
        imap     => { },
        mcrypt   => { },
        ssh2     => { },
        pspell   => { },
        recode   => { },
        tidy     => { },
        xmlrpc   => { },
        json     => { },
        pgsql    => { },
        mbstring => { },
        mysql    => { }, # might be causing an issue with a mysql.so warning
    },
}

exec {"pear install Mail":
    command => "/usr/bin/pear install Mail",
    require => [
        Class['::php'],
        Package['php-pear'],
    ]
}
exec {"pear install Mail_Mime":
    command => "/usr/bin/pear install Mail_Mime",
    require => [
        Class['::php'],
        Package['php-pear'],
    ]
}


php::fpm::pool { $fqdn:
    user => 'ubuntu',
    group => 'ubuntu',
    listen => $fpm_socket,
    listen_owner => 'www-data',
    listen_group => 'www-data',
    pm => 'dynamic',
    pm_max_children => 5,
    pm_start_servers => 2,
    pm_min_spare_servers => 1,
    pm_max_spare_servers => 3,
    chdir => '/',
}

# Postgresql 9.6
class { 'postgresql::globals':
    manage_package_repo => true,
    version             => '9.6',
}

class { 'postgresql::server':
    listen_addresses => '*',
    ipv4acls         => [
        'local  all  all                            trust',
        'host   all  all  192.168.0.0  255.255.0.0  trust',
        'host   all  all  127.0.0.1    255.255.0.0  trust',
    ],
}

postgresql::server::db { $db_name:
    user     => $db_name,
    password => postgresql_password($db_name, 'vagrant'),
}

postgresql::server::extension { 'uuid-ossp':
    database => $db_name,
    ensure => 'present',
}

#npm, grunt
class npm_grunt {
    exec { 'grunt':
        command => "/usr/bin/npm install -g grunt-cli --save-dev --no-bin-links",
    }
    exec { 'bower':
        command => "/usr/bin/npm install -g bower --no-bin-links",
    }
    exec { 'path':
        command => '/bin/echo "export PATH=/usr/local/lib/node_modules/grunt-cli/bin:/usr/local/lib/node_modules/bower/bin:$PATH" >> /home/ubuntu/.bashrc',
    }
    file { 'node-symlink':
        path => "/usr/bin/node",
        target => "/usr/bin/nodejs",
        ensure => link,
    }
}
include npm_grunt
