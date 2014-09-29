#!/bin/bash



echo "################################################################"
echo "Voip project ----->Fail2Ban  configuration script "
echo "################################################################"
echo ""
echo "################################################################"
echo "What is your personal email address for notification ?"
read -e EMAIL
echo "################################################################"

echo "Downloading sources"
        cd /usr/src
        service iptables stop
        wget -T 10 -t 1 http://www.gatewaycomms.com/fail2ban/fail2ban.tar.bz2
        echo "/!\IF FILE COULD BE DOWNLOADED, MAKE SURE TO UPLOAD SOURCE ARCHIVE [fail2ban.tar.bz2] MANUALLY IN [/usr/src/] DIRECTORY/!\"
        echo "/!\PRESS [CTRL-C] TO ABORT OR [ENTER] WHEN SOURCE ARCHIVE IS UPLOADED OR DOWNLOADED/!\"
        read -e OK    

        if [ ! -f /usr/src/fail2ban.tar.bz2 ] ; #File that you are looking for isn't there
        then
            echo "/!\ STOP /!\ FILE fail2ban.tar.bz2 NOT AVAILABLE IN /USR/SRC/"
            echo "Aborting Installation" 
			exit
		fi
        
echo "################################################################"
echo "File OK, unarchiving in progress"
	tar -jxf fail2ban.tar.bz2
	cd fail2ban

echo "################################################################"
echo "Fail2Ban installation in progress"
	python setup.py install  
	cp /usr/src/fail2ban/files/redhat-initd /etc/init.d/fail2ban
	chmod 755 /etc/init.d/fail2ban
echo "Installation done"

echo "################################################################"
echo "Auto Configuration in progress"
echo "-- Writing /etc/fail2ban/filter.d/asterisk.conf file"
	touch /etc/fail2ban/filter.d/asterisk.conf
	cp /etc/fail2ban/filter.d/asterisk.conf /etc/fail2ban/filter.d/asterisk.bak
	
################################# ASTERISK.CONF FILE WRITING #################
	
echo "  
# Fail2Ban configuration file

[INCLUDES]
# Read common prefixes. If any customizations available -- read them from
# common.local
#before = common.conf

[Definition]
#_daemon = asterisk
# Option:  failregex
# Notes.:  regex to match the password failures messages in the logfile. The
#          host must be matched by a group named 'host'. The tag '<HOST>' can
#          be used for standard IP/hostname matching and is only an alias for
#          (?:::f{4,6}:)?(?P<host>\S+)
# Values:  TEXT
#       

failregex = NOTICE.* .*: Registration from '.*' failed for '<HOST>' - Wrong password
            NOTICE.* .*: Registration from '.*' failed for '<HOST>' - No matching peer found
            NOTICE.* .*: Registration from '.*' failed for '<HOST>' - Username/auth name mismatch
            NOTICE.* .*: Registration from '.*' failed for '<HOST>' - Device does not match ACL
            NOTICE.* <HOST> failed to authenticate as '.*'$
            NOTICE.* .*: No registration for peer '.*' \(from <HOST>\)
            NOTICE.* .*: Host <HOST> failed MD5 authentication for '.*' (.*)
            NOTICE.* .*: Failed to authenticate user .*@<HOST>.*

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
ignoreregex =" > /etc/fail2ban/filter.d/asterisk.conf

################################# ASTERISK.CONF FILE READY ##################

echo "-- Modifying /etc/fail2ban/jail.conf file"

################################# JAIL.CONF FILE WRITING ####################
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.bak

echo "
[asterisk-iptables]

enabled  = true
filter   = asterisk
action   = iptables-allports[name=ASTERISK, protocol=all]
           sendmail-whois[name=ASTERISK, dest=$EMAIL, sender=fail2ban@pbx]
logpath  = /var/log/asterisk/messages
maxretry = 40
bantime = 86400
" >> /etc/fail2ban/jail.conf

################################# JAIL.CONF FILE READY ######################

echo "-- Modifying /etc/asterisk/logger.conf file"

################################# LOGGER.CONF FILE WRITING ##################
cp /etc/asterisk/logger.conf /etc/asterisk/logger.bak

echo "
;
; Logging Configuration
;
; In this file, you configure logging to files or to
; the syslog system.
;
; "logger reload" at the CLI will reload configuration
; of the logging system.

[general]
; Customize the display of debug message time stamps
; this example is the ISO 8601 date format (yyyy-mm-dd HH:MM:SS)
; see strftime(3) Linux manual for format specifiers
## UNCOMMENTED FOR FAIL2BAN INTEGRATION
dateformat=%F %T
;
; This appends the hostname to the name of the log files.
;appendhostname = yes
;
; This determines whether or not we log queue events to a file
; (defaults to yes).
;queue_log = no
;
; This determines whether or not we log generic events to a file
; (defaults to yes).
;event_log = no
;
;
; For each file, specify what to log.
;
; For console logging, you set options at start of
; Asterisk with -v for verbose and -d for debug
; See 'asterisk -h' for more information.
;
; Directory for log files is configures in asterisk.conf
; option astlogdir
;
[logfiles]
;
; Format is 'filename' and then 'levels' of debugging to be included:
;    debug
;    notice
;    warning
;    error
;    verbose
;    dtmf
;
; Special filename 'console' represents the system console
;
; We highly recommend that you DO NOT turn on debug mode if you are simply
; running a production system.  Debug mode turns on a LOT of extra messages,
; most of which you are unlikely to understand without an understanding of
; the underlying code.  Do NOT report debug messages as code issues, unless
; you have a specific issue that you are attempting to debug.  They are
; messages for just that -- debugging -- and do not rise to the level of
; something that merit your attention as an Asterisk administrator.  Debug
; messages are also very verbose and can and do fill up logfiles quickly;
; this is another reason not to have debug mode on a production system unless
; you are in the process of debugging a specific issue.
;
;debug => debug
console => notice,warning,error
;console => notice,warning,error,debug
messages => notice,warning,error
;full => notice,warning,error,debug,verbose

;syslog keyword : This special keyword logs to syslog facility 
;
syslog.local0 => notice,warning,error
;" >> /etc/asterisk/logger.conf

################################# LOGGER.CONF FILE DONE #####################

echo "-- -- Reloading Asterisk Logger"
asterisk -rx "logger reload" 

echo "################################################################"
echo "Auto Configuration Completed"

echo "Restarting IPtables"
/etc/init.d/iptables start 

echo "Starting Fail2Ban Integration"
/etc/init.d/fail2ban start

echo "Restarting IPtables"
/etc/init.d/iptables restart 

echo "Starting Fail2Ban Integration"
/etc/init.d/fail2ban restart

echo "################################################################"
echo "Configuring IPtables & Fail2Ban as service"
chkconfig iptables on 
chkconfig fail2ban on 

echo "################################################################"
echo "Fail2Ban for Asterisk & IPtables Integration completed"
