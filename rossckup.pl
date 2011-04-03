#!/usr/bin/perl -w

use Net::FTP;

# Configs
use constant {
  # Delete local archives after FTP upload:
  BACKUP_DELETE_AFTER => 1,
  # Email after successful backup:
  BACKUP_EMAIL_AFTER => 1,
  # Add date suffixes:
  BACKUP_SUFFIX => 1,
  # Local directory to backup:
  BACKUP_SRC => '/home/user/public_html',
  # Local backup directory:
  BACKUP_DST => '/home/user/rossckups',
  # Database hostname:
  DB_HOST => 'localhost',
  # Database username:
  DB_USER => 'root',
  # Database password:
  DB_PWD => '',
  # Database names to backup:
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
  FTP_DST => '/home/user2/rossckups',
  # System command to dump database:
  SYS_DUMP => '/usr/bin/mysqldump',
  # System command to compress backups:
  SYS_ZUP => '/usr/bin/gzip',
};

