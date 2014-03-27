# Class: galera::server
#
# manages the installation of the mysql wsrep and galera.
# manages the package, service, wsrep.cnf
#
# Parameters:
#  [*config_hash*]         - hash of config parameters that need to be set.
#  [*enabled*]             - Defaults to true, boolean to set service ensure.
#  [*manage_service*]      - Boolean dictating if mysql::server should manage the service.
#  [*root_group]           - use specified group for root-owned files.
#  [*package_ensure*]      - Ensure state for package. Can be specified as version.
#  [*galera_package_name*] - The name of the galera package.
#  [*wsrep_package_name*]  - The name of the wsrep package.
#  [*libaio_package_name*] - The name of the libaio package.
#  [*libssl_package_name*] - The name of the libssl package.
#  [*wsrep_deb_name*]      - The name of wsrep .deb file.
#  [*galera_deb_name*]     - The name of galera .deb file.
#  [*wsrep_deb_name*]      - The URL to download the wsrep .deb file.
#  [*galera_deb_name*]     - The URL to download the galera .deb file.
#  [*galera_package_name*] - The name of the Galera package.
#  [*wsrep_package_name*]  - The name of the WSREP package.
#  [*cluster_name*]        - Logical cluster name. Should be the same for all nodes.
#  [*master_ip*]           - IP address of the group communication system handle.
#    The first node in the cluster should be left as the default (false) until the cluster is formed.
#    Additional nodes in the cluster should have an IP address set to a node in the cluster.
#  [*wsrep_sst_username*]  - Username used by the wsrep_sst_auth authentication string.
#    Used to secure the communication between cluster members.
#  [*wsrep_sst_password*]  - Password used by the wsrep_sst_auth authentication string.
#    Used to secure the communication between cluster members.
#  [*wsrep_sst_method*]    - WSREP state snapshot transfer method.
#    Defaults to 'mysqldump'.  Note: 'rsync' is the most widely tested.
#
# Requires:
#
# Sample Usage:
# class { 'mysql::server::galera':
#   config_hash => {
#     'root_password' => 'root_pass',
#   },
#    cluster_name       => 'galera_cluster',
#    master_ip          => false,
#    wsrep_sst_username => 'ChangeMe',
#    wsrep_sst_password => 'ChangeMe',
#    wsrep_sst_method   => 'rsync'
#  }
#
class galera::server (
  $client_package_name = 'MariaDB-client',
  $config_hash         = {},
  $enabled             = true,
  $manage_service      = true,
  $root_group          = $mysql::root_group,
  $package_ensure      = $mysql::package_ensure,
  $wsrep_bind_address  = '0.0.0.0',
  $cluster_name        = 'wsrep',
  $master_ip           = false,
  $pidfile             = '/var/run/mysqld.pid',
  $server_package_name = 'MariaDB-Galera-server',
  $service_name        = 'mysql',
  $wsrep_sst_username  = 'wsrep_user',
  $wsrep_sst_password  = 'wsrep_pass',
  $wsrep_sst_method    = 'mysql_dump'
) inherits mysql {

  class { 'galera::repo':
    before  => Package['mysql_client'],
  }

  package { $server_package_name:
    ensure   => present,
    require  => Class['galera::repo'],
  }

  case $hardwaremodel {
    "i386", "i686": { $galeralibdir = "lib" }
    "x86_64":       { $galeralibdir = "lib64" }
    default:        { fail("Hardware not supported") }
  }

  $config_class = { 'mysql::config' => $config_hash }

  create_resources( 'class', $config_class )

  file { '/etc/mysql/conf.d/wsrep.cnf' :
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => $root_group,
    content => template('galera/wsrep.cnf.erb'),
    notify  => Service['mysqld']
  }

  file { '/etc/init.d/mysql' :
    ensure  => present,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => template('galera/mysql.erb'),
    require => Package[$server_package_name],
  }
  
  package { 'rsync':
    ensure   => present,
    before   => File['/etc/mysql/conf.d/wsrep.cnf'],
  }

  file { '/var/run/mysqld':
    ensure  => directory,
    mode    => 0755,
    owner   => mysql,
    group   => mysql,
    require => Package[$server_package_name],
    before  => Service['mysqld'],
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  if $manage_service {
    Service['mysqld'] -> Exec<| title == 'set_mysql_rootpw' |>
    service { 'mysqld':
      ensure   => $service_ensure,
      name     => 'mysql',
      enable   => $enabled,
      require  => [ File['/etc/init.d/mysql'] , File['/etc/mysql/conf.d/wsrep.cnf'] ],
    }

    database_user { "${wsrep_sst_username}@%":
        password_hash   => mysql_password($wsrep_sst_password)
    } 
  }


}
