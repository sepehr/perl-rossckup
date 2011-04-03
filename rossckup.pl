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

# Set date:
# @see http://perldoc.perl.org/functions/localtime.html
($s, $m, $h, $day, $month, $year, $wd, $yd, $o) = localtime();
$year += 1900;
# Set filenames:
$dbckup = BACKUP_DST . '/db.tmp.sql.gz';
$fileckup = BACKUP_DST . '/site.tmp.tar.gz';

# Make the files tarball:
# @see http://perldoc.perl.org/functions/system.html
system('tar --exclude ' . BACKUP_DST . "/*  -czf $fileckup " . BACKUP_SRC)
  or warn 'There were problems making te files tarball.';

# Make databases tarball:
if (BACKUP_DB) {
  # Find the proper command to issue:
  my $cmd = (DB_NAMES eq 'all') ?
    SYS_DUMP . ' --host=' . DB_HOST . ' --user=' . DB_USER . ' --password=' . DB_PWD . " --add-drop-table --all-databases -c -l --result-file=$dbckup" :
    SYS_DUMP . ' --host=' . DB_HOST . ' --user=' . DB_USER . ' --password=' . DB_PWD . ' --add-drop-table --databases ' . DB_NAMES . ' -c -l | ' . SYS_GZIP . " > $dbckup";
  # Issue:
  system($cmd)
    or warn 'There were problems dumping the specified databases.';
}

# Merge both tarballs together:
$rossckup = BACKUP_DST . '/' . BACKUP_ARCHIVE_NAME . "-$year$month$day.tar.gz";
system("tar -czf $rossckup $dbckup $fileckup")
  or die 'Err! Could not merge files and db tarballs.';

# Delete previous tarballs:
unlink $dbckup, $fileckup;


# Email notification:
# @see
if (BACKUP_EMAIL_AFTER) {
  # TODO: Do!
}

