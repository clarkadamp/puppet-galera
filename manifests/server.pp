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
  $cluster_name        = 'wsrep',
  $client_package_name = 'MariaDB-client',
  $master_ip           = false,
  $mysql_bind_address  = '0.0.0.0',
  $root_password       = undef,
  $server_package_name = 'MariaDB-Galera-server',
  $service_name        = 'mysql',
  $wsrep_bind_address  = '0.0.0.0',
  $wsrep_sst_username  = 'wsrep_user',
  $wsrep_sst_password  = 'wsrep_pass',
  $wsrep_sst_access    = '%',
  $wsrep_sst_method    = 'mysql_dump'
) {

  class { 'galera::repo':
    before => Class['mysql::client','mysql::server']
  }

  class { '::mysql::client':
    package_name => $client_package_name
  }
 
  class { '::mysql::server':
    package_name   => $server_package_name,
    service_name   => $service_name,
    root_password  => $root_password,
    users          => {
      "${wsrep_sst_username}@${wsrep_sst_access}" => {
          ensure        => 'present',
          password_hash => mysql_password($wsrep_sst_password),
        }
    }
  }
  
  case $hardwaremodel {
    "i386", "i686": { $galeralibdir = "lib" }
    "x86_64":       { $galeralibdir = "lib64" }
    default:        { fail("Hardware not supported") }
  }

  file { '/var/run/mysqld/':
    ensure  => directory,
    mode    => '0755',
    owner   => 'mysql',
    group   => 'mysql',
    require => Package['mysql-server'],
    before  => Service['mysqld']
  }

  file { '/etc/mysql/conf.d/wsrep.cnf' :
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => $root_group,
    content => template('galera/wsrep.cnf.erb'),
    require => File['/etc/mysql/conf.d/'],
    notify  => Service['mysqld']
  }

  file { '/etc/init.d/mysql' :
    ensure  => present,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => template('galera/mysql.erb'),
    require => Package['mysql-server'],
    before  => Service['mysqld']
  }

  if $wsrep_sst_method == 'rsync' {
    package { 'rsync':
     ensure => present,
     before  => Service['mysqld']
    }
  }
 
}
