#!/usr/bin/perl -w
#
# Rossckup.pl - http://github.com/sepehr/rossckup
# Local and cross server backup for wash machines!
#
# Copyright (C) 2010, by Sepehr Lajevardi <me@sepehr.ws>
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Net::FTP;
use Net::SMTP::SSL;

my $VERSION = 0.2;

# Configs
use constant {
  # System path to gunzip executable:
  SYS_GZIP => '/bin/gzip',
  # System path to dbdump executable:
  SYS_DUMP => '/usr/bin/mysqldump',
  # Archive name of the backedup files:
  BACKUP_ARCHIVE_NAME => 'rossckup',
  # Local backup directory, no trailing slash:
  BACKUP_DST => '/home/user/private_pool',
  # First remove all files in BACKUP_DST:
  BACKUP_RM => 1,
  # Local directory to backup, no trailing slash:
  BACKUP_SRC => '/home/user/public_html',
  # Whether to backup files:
  BACKUP_FILES => 1,
  # Dump and backup database:
  BACKUP_DB => 1,
  # Database hostname:
  DB_HOST => 'localhost',
  # Database username:
  DB_USER => 'user_dba',
  # Database password:
  DB_PWD => '',
  # Space separated list of database names
  # to backup, you can specify "all" to back 'em all:
  DB_NAMES => 'user_db1 user_db2 user_etc',
  # FTP upload after local backup:
  FTP_UPLOAD => 1,
  # FTP hostname:
  FTP_HOST => 'ftp.example.com',
  # FTP username:
  FTP_USER => 'ftp_user',
  # FTP passwprd:
  FTP_PWD => '',
  # Remote server backup directory, no trailing slash:
  FTP_DST => '/',
  # Delete local archives after FTP upload:
  FTP_DELETE_AFTER => 0,
  # Email after successful backup:
  EMAIL_NOTIFY => 1,
  # SMTP server:
  EMAIL_SMTP_HOST => 'smtp.example.com',
  # SMTP username:
  EMAIL_SMTP_USER => 'user+example.com',
  # SMTP password:
  EMAIL_SMTP_PWD => '',
  # Email sender:
  EMAIL_FROM => 'rossckup@example.com',
  # Email recipient:
  EMAIL_TO => 'fatass.boss@example.com',
  # Email recipient name:
  EMAIL_TO_NAME => 'Mr. Jonney Cowboy',
  # Email subject:
  EMAIL_SUBJECT => 'Rossckup Backup Notification',
  # Email text body, available tokens:
  # _to_name_
  # _ftp_dst_
  # _db_names_
  # _ftp_host_
  # _backup_src_
  # _backup_dst_
  EMAIL_BODY => "Dear _to_name_,\nBackup operation has been successfully done on your machine.",
  # Email sgnature:
  EMAIL_SIGNATURE => "\n\nAutomated Backup for Wash Machines!\nhttp://github.com/sepehr/rossckup",
};

##### Warning: Donn touch me again! #####

# Check configs:
if (!BACKUP_FILES && !BACKUP_DB) {
  # Exit:
  die "Nothing, Good!\n";
}

# Backup date:
my ($s, $m, $h, $day, $month, $year, $wd, $yd, $o) = localtime();
$year += 1900;

# Check local backup directory:
if (! -d BACKUP_DST) {
  # Status:
  print('STATUS: Making backup directory ' . BACKUP_DST . "\n");
  # Issue:
  mkdir(BACKUP_DST, 0755)
    or die "ERROR: There were a problem creating the local backup directory.\n";
}

# Remove old backups, if requested so:
if (BACKUP_RM) {
  my $cmd = 'rm -rf ' . BACKUP_DST . '/*';
  # Status:
  print("STATUS: Executing $cmd\n");
  # Issue:
  system($cmd) == 0
    or warn "WARNING: There were a problem cleaning the backup destination directory.\n";
}

# Make the files tarball:
my $fileckup = BACKUP_DST . '/' . BACKUP_ARCHIVE_NAME . ".files-$year$month$day.tar.gz";
if (BACKUP_FILES) {
  my $cmd = 'tar --exclude=' . BACKUP_DST . "/* -czPf $fileckup " . BACKUP_SRC;
  # Status:
  print("STATUS: Executing $cmd\n");
  # Issue:
  system($cmd) == 0
    or warn 'WARNING: There were problems making files tarball.';
}

# Make databases tarball:
my $dbckup = BACKUP_DST . '/' . BACKUP_ARCHIVE_NAME . ".dbs-$year$month$day.sql.gz";
if (BACKUP_DB) {
  # Determine the proper command to issue:
  my $cmd = (DB_NAMES eq 'all') ?
    SYS_DUMP . ' --host=' . DB_HOST . ' --user=' . DB_USER . ' --password=' . DB_PWD . " --add-drop-table --all-databases -c -l --result-file=$dbckup" :
    SYS_DUMP . ' --host=' . DB_HOST . ' --user=' . DB_USER . ' --password=' . DB_PWD . ' --add-drop-table --databases ' . DB_NAMES . ' -c -l | ' . SYS_GZIP . " > $dbckup";
  # Status:
  print("STATUS: Executing $cmd \n");
  # And issue:
  system($cmd) == 0
    or warn 'WARNING: There were problems dumping the specified databases.';
}

# Rearchive tarballs:
my $rossckup = BACKUP_DST . '/' . BACKUP_ARCHIVE_NAME . "-$year$month$day.tar.gz";
# Determine the proper command to issue:
if (BACKUP_FILES && BACKUP_DB) {
  my $cmd = "tar -czPf $rossckup $dbckup $fileckup";
  # Status:
  print("STATUS: Executing $cmd\n");
  # Issue command:
  system($cmd) == 0
    or die "ERROR: Could not merge files and db tarballs.\n";
  # Remove oldies:
  unlink $fileckup, $dbckup;
}
# Files backup only:
elsif (BACKUP_FILES) {
  $rossckup = $fileckup;
}
# Databases backup only:
else {
  $rossckup = $dbckup;
}

# Email notification:
if (EMAIL_NOTIFY) {
  # Status:
  print('STATUS: Sending notification email to: ' . EMAIL_TO . "\n");

  # Set initials:
  my $smtp = Net::SMTP::SSL->new(
    EMAIL_SMTP_HOST,
    Port => 465,
    Debug => 0
  ) or warn "WARNING: Could not connect to the specified SMTP server.\n";
  # Authenticate:
  $smtp->auth(EMAIL_SMTP_USER, EMAIL_SMTP_PWD)
    or warn "WARNING: SMTP authention failed.";
  # Set email addresses:
  $smtp->mail(EMAIL_FROM);
  $smtp->to(EMAIL_TO);
  # Build the message:
  $smtp->data;
  # Dispatch, headers:
  $smtp->datasend('From: ' . EMAIL_FROM . "\n");
  $smtp->datasend('To: ' . EMAIL_TO . "\n");
  $smtp->datasend('Subject: ' . EMAIL_SUBJECT . "\n");
  $smtp->datasend("\n");
  # Prepare body tokens:
  # Replace tokens, PHP's strtr() equivalent somehow:
  my %dic = (
    '_to_name_' => EMAIL_TO_NAME,
    '_ftp_dst_' => FTP_DST,
    '_db_names_' => DB_NAMES,
    '_ftp_host_' => FTP_HOST,
    '_backup_src_' => BACKUP_SRC,
    '_backup_dst_' => BACKUP_DST,
  );
  my $tokens = join '|', keys %dic;
  my $body = EMAIL_BODY;
  $body =~ s/($tokens)/$dic{$1}/g;
  # And send:
  $smtp->datasend($body . EMAIL_SIGNATURE. "\n");

  # Closing SMTP session:
  $smtp->dataend;
  $smtp->quit;
}

# FTP upload:
if (FTP_UPLOAD) {
  # Status:
  print('STATUS: Uploading backup tarball via FTP: ' . FTP_HOST . "\n");
  # Connect:
  my $ftp = Net::FTP->new(FTP_HOST, Debug => 0)
    or die "ERROR: Could not connect to FTP host.\n";
  # Login:
  $ftp->login(FTP_USER, FTP_PWD)
    or die "ERROR: Could not login to the FTP server.\n";
  # Change dir:
  $ftp->cwd(FTP_DST)
    or die "ERROR: Could not change the FTP working directory.\n";
  # Set to binary mode:
  $ftp->binary();
  # Upload backups:
  $ftp->put($rossckup)
    or die('ERROR: Could not upload the backups to the FTP server: ' . $ftp->message . "\n");
  # Close FTP session:
  $ftp->quit();

  # Delete local tarball:
  if (FTP_DELETE_AFTER) {
    # Status:
    print("STATUS: Deleting local backup tarball.\n");
    # Delete:
    unlink $rossckup;
  }
}

# Good gal, say bye:
print("Bye!\n");

=head1 NAME

Rossckup.pl

=head1 DESCRIPTION

Local and cross server backup for wash machines!

=head1 PREREQUISITES

Rossckup requires the C<strict> module. It also requires
C<Net::FTP> and C<Net::SMTP:SSL>.

=pod OSNAMES

any

=pod SCRIPT CATEGORIES

Web

=cut

