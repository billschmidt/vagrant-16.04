class nginx {
  # make sure nginx is installed
  package { 'nginx':
    ensure => 'present',
  }

  package { 'nginx-extras':
    ensure => 'present',
  }

  file { 'vagrant-log':
      path => "${synced_folder}/log",
      ensure => directory,
  }

  # make sure nginx is running
  service { 'nginx':
    ensure => running,
    require => [
      File['vagrant-log'],
      Package['nginx']
    ],
  }

  exec { 'sendfile':
      command => "/bin/sed -i 's/sendfile on/sendfile off/g' /etc/nginx/nginx.conf",
      require => Package['nginx'],
  }

  # virtual host file
  file { 'vagrant-nginx':
    path => "/etc/nginx/sites-available/${fqdn}",
    ensure => file,
    require => Package['nginx'],
    content => template('nginx/web.nginx.erb'),
  }

  # symlink available to sites-enabled to enable it
  file { 'vagrant-nginx-enable':
    path => "/etc/nginx/sites-enabled/${fqdn}",
    target => "/etc/nginx/sites-available/${fqdn}",
    ensure => link,
    notify => Service['nginx'],
    require => [
      File['vagrant-nginx'],
    ],
  }
}
