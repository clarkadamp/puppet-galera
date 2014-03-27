class galera::repo (
 # Default version of MariaDB is 5.5
 $version = "5.5",
) {
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
