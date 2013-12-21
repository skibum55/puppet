# == Define: orautils::nodemanagerautostart
#
#  autostart of the nodemanager for linux
#
define orautils::nodemanagerautostart(
                        $version         = "1111",
                        $wlHome          = undef, 
                        $user            = 'oracle',
                        $domain          = undef,
                        $logDir          = undef,
                       ) {


   if $version == "1111" {
     $nodeMgrPath    = "${wlHome}/common/nodemanager"
     $nodeMgrBinPath = "${wlHome}/server/bin"

     $scriptName = "nodemanager_${$version}" 

	   if $logDir == undef {
	      $nodeMgrLckFile = "${nodeMgrPath}/nodemanager.log.lck"
	   } else {
	      $nodeMgrLckFile = "${logDir}/nodemanager.log.lck"
	   }
   } elsif $version == "1212" {
     $nodeMgrPath    = "${wlHome}/../user_projects/domains/${domain}/nodemanager"
     $nodeMgrBinPath = "${wlHome}/../user_projects/domains/${domain}/bin"     
     $scriptName = "nodemanager_${domain}" 

     if $logDir == undef {
        $nodeMgrLckFile = "${nodeMgrPath}/nodemanager_${domain}.log.lck"
     } else {
        $nodeMgrLckFile = "${logDir}/nodemanager_${domain}.log.lck"
     }
   } else {
     $nodeMgrPath    = "${wlHome}/common/nodemanager"
     $nodeMgrBinPath = "${wlHome}/server/bin"

     if $logDir == undef {
        $nodeMgrLckFile = "${nodeMgrPath}/nodemanager.log.lck"
     } else {
        $nodeMgrLckFile = "${logDir}/nodemanager.log.lck"
     }
   }

   # determine whether to use chkconfig or sysv-rc-conf package
   $rc_config = $operatingsystem ? {
     /(Debian|Ubuntu)/ => "sysv-rc-conf",
     default => "chkconfig",
   }
 
   package { "$rc_config":
       ensure => "present",
       alias  => "rc-config",
   }
   
   
   case $operatingsystem {
     CentOS, RedHat, OracleLinux, Debian, SLES: { 

        $execPath        = '/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:'
        
        Exec { path      => $execPath,
               logoutput => true,
             }
             
        exec { "${rc_config} ${scriptName}":
	       command => "${rc_config} --add ${scriptName}",
	       require => File["/etc/init.d/${scriptName}"],
	       user    => 'root',
	       unless  => "${rc_config} | /bin/grep '${scriptName}'",
	      }     

     }
     Ubuntu:{
     	
     	exec { "${rc_config} ${scriptName}":
	       command => "${rc_config} on ${scriptName}",
	       require => File["/etc/init.d/${scriptName}"],
	       user    => 'root',
	     }
	     
   	service { "${scriptName}":
        	  ensure  => running,
        	  enable  => true,
        	  require => exec["${rc_config} ${scriptName}"],
   		}
     
     }
     
     default: { 
        fail("Unrecognized operating system") 
     }
   }

   file { "/etc/init.d/${scriptName}" :
      ensure  => present,
      mode    => "0755",
      content => template("orautils/nodemanager.erb"),
   }

}  
