#!/usr/bin/perl -w

use Net::FTP;

# Configs
# @see http://perldoc.perl.org/constant.html
use constant {
  # Archive name of the backedup files:
  BACKUP_ARCHIVE_NAME => 'rossckup',
  # Delete local archives after FTP upload:
  BACKUP_DELETE_AFTER => 1,
  # Email after successful backup:
  BACKUP_EMAIL_AFTER => 1,
  # Local directory to backup:
  BACKUP_SRC => '/home/user/public_html',
  # Local backup directory:
  BACKUP_DST => '/home/user/rossckup',
  # Dump and backup database:
  BACKUP_DB => 1,
  # Database hostname:
  DB_HOST => 'localhost',
  # Database username:
  DB_USER => 'root',
  # Database password:
  DB_PWD => '',
  # Space separated list of database names
  #  to backup, you can specify all to back 'em all:
  DB_NAMES => 'db1 db2 db3 db4',
  # FTP upload after local backup:
  FTP_UPLOAD => 1,
  # FTP hostname:
  FTP_HOST => 'ftp.example.com',
  # FTP username:
  FTP_USER => 'user\@ftp.example.com',
  # FTP passwprd:
  FTP_PWD => '',
  # Remote server backup directory:
  FTP_DST => '/home/user2/rossckup',
  # System path to dbdump executable:
  SYS_DUMP => '/usr/bin/mysqldump',
  # System path to gunzip executable:
  SYS_GZIP => '/usr/bin/gzip',
};

##### Warning: Donn touch me anymore! #####

