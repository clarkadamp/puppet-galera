class galera::repo (
 $mirror  = "mirror.aarnet.edu.au" ,
 $version = "5.5",
) {
  case $::osfamily {
    'Debian': {
      include apt

      apt::key { 'MariaDb':
        ensure     => $ensure,
        key        => 'cbcb082a1bb943db',
        key_server => 'keyserver.ubuntu.com',
      }

      apt::source { 'MariaDb':
        ensure   => $ensure,
        location => "http://${mirror}/pub/MariaDB/repo/5.5/ubuntu/",
        release  => $::lsbdistcodename,
        require  => Apt::Key['MariaDb'],
      }

      Exec['apt_update'] -> Package<||>
    }
    'RedHat': {
      # Normalise the hardware and operating system identifiers
      case $hardwaremodel {
        "i386", "i686": { $arch = "x86" }
        "x86_64":       { $arch = "amd64" }
        default:        { fail("Hardware not supported") }
      }

      case $operatingsystem {
        "Centos":       { $dist = "centos" }
        "Redhat":       { $dist = "rhel"   }
        default:        { fail("Operating System not supported") }
      }

      yumrepo { 'MariaDB':
        baseurl  => "http://yum.mariadb.org/${version}/${dist}${operatingsystemmajrelease}-${arch}",
        descr    => "MariaDB",
        enabled  => 1,
        gpgcheck => 1,
        gpgkey   => "https://yum.mariadb.org/RPM-GPG-KEY-MariaDB",
        priority => 98,
      }
    }

    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only supports osfamily Debian and RedHat")
    }
  }
}
