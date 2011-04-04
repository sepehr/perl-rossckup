#!/usr/bin/perl -w

use Net::FTP;
use MIME::Lite::TT::HTML;

# Configs
# @see http://perldoc.perl.org/constant.html
use constant {
  # Archive name of the backedup files:
  BACKUP_ARCHIVE_NAME => 'rossckup',
  # Delete local archives after FTP upload:
  BACKUP_DELETE_AFTER => 1,
  # Local directory to backup, no trailing slash:
  BACKUP_SRC => '/home/user/public_html',
  # Local backup directory, no trailing slash:
  BACKUP_DST => '/home/user/backups',
  # First remove all files in BACKUP_DST:
  BACKUP_RM => 0,
  # Dump and backup database:
  BACKUP_DB => 1,
  # Database hostname:
  DB_HOST => 'localhost',
  # Database username:
  DB_USER => 'user_dba',
  # Database password:
  DB_PWD => '',
  # Space separated list of database names
  # to backup, you can specify all to back 'em all:
  DB_NAMES => 'user_db1 user_db2 user_etc',
  # Email after successful backup:
  EMAIL_NOTIFY => 1,
  # Also attach backup tarball to that email:
  EMAIL_ATTACH => 1,
  # Email sender:
  EMAIL_FROM => 'rossckup@example.com',
  # Email recipient:
  EMAIL_TO => 'client@example.com',
  # Email subject:
  EMAIL_SUBJECT => 'Rossckup Notification',
  # Email text template name:
  EMAIL_TMPL_TXT => 'rossckup.txt.tt',
  # Email HTML template name:
  EMAIL_TMPL_HTML => 'rossckup.html.tt',
  # Email templates directory path, no trailing slash:
  EMAIL_TMPL_PATH => '/path/to/templates',
  # Email charset:
  EMAIL_CHARSET => 'utf8',
  # Email encoding:
  EMAIL_ENCODING => 'quoted-printable',
  # Email timezone:
  EMAIL_TIMEZONE => 'Asia/Tehran',
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
  # System path to gunzip executable:
  SYS_GZIP => '/bin/gzip',
  # System path to dbdump executable:
  SYS_DUMP => '/usr/bin/mysqldump',
};

# Email template params:
my %params;
$params{name} = 'Mr. Foo Bar';

##### Warning: Donn touch me anymore! #####

# Set date:
# @see http://perldoc.perl.org/functions/localtime.html
my ($s, $m, $h, $day, $month, $year, $wd, $yd, $o) = localtime();
$year += 1900;
# Set filenames:
$dbckup = BACKUP_DST . '/dbs.tmp.sql.gz';
$fileckup = BACKUP_DST . '/files.tmp.tar.gz';

# Make local backup directory, if not exists:
if (! -d BACKUP_DST) {
  # Status:
  print('STATUS: Making backup directory ' . BACKUP_DST . "\n");
  # Issue:
  mkdir(BACKUP_DST, 0755)
    or die "ERROR: There were a problem creating the local backup directory: $!";
}

# Remove old backups, if requested so:
if (BACKUP_RM) {
  $cmd = 'rm -rf ' . BACKUP_DST . '/*';
  # Status:
  print("STATUS: Executing $cmd\n");
  # Issue:
  system($cmd) == 0
    or warn 'WARNING: There were a problem cleaning the backup destination directory.';
}


# Make the files tarball:
$cmd = 'tar --exclude=' . BACKUP_DST . "/* -czPf $fileckup " . BACKUP_SRC;
# Status:
print("STATUS: Executing $cmd\n");
# Issue:
system($cmd) == 0
  or warn 'WARNING: There were problems making files tarball.';

# Make databases tarball:
if (BACKUP_DB) {
  # Determine the proper command to issue:
  $cmd = (DB_NAMES eq 'all') ?
    SYS_DUMP . ' --host=' . DB_HOST . ' --user=' . DB_USER . ' --password=' . DB_PWD . " --add-drop-table --all-databases -c -l --result-file=$dbckup" :
    SYS_DUMP . ' --host=' . DB_HOST . ' --user=' . DB_USER . ' --password=' . DB_PWD . ' --add-drop-table --databases ' . DB_NAMES . ' -c -l | ' . SYS_GZIP . " > $dbckup";
  # Status:
  print("STATUS: Executing $cmd \n");
  # And issue:
  system($cmd) == 0
    or warn 'WARNING: There were problems dumping the specified databases.';
}

# Rearchive tarballs:
$rossckup = BACKUP_DST . '/' . BACKUP_ARCHIVE_NAME . "-$year$month$day.tar.gz";
$cmd = "tar -czPf $rossckup $dbckup $fileckup";
# Status:
print("STATUS: Executing $cmd\n");
# Issue command:
system($cmd) == 0
  or die 'ERROR: Could not merge files and db tarballs.';

# Delete previous tarballs:
unlink $dbckup, $fileckup;

# Email notification:
# @see http://search.cpan.org/~chunzi/MIME-Lite-TT-HTML-0.03/lib/MIME/Lite/TT/HTML.pm
if (EMAIL_NOTIFY) {
  # Email template options:
  my %options;
  $options{INCLUDE_PATH} = EMAIL_TMPL_PATH;

  # Set initials:
  my $mail = MIME::Lite::TT::HTML->new(
    To   => EMAIL_TO,
    From => EMAIL_FROM,
    Charset  => EMAIL_CHARSET,
    Subject  => EMAIL_SUBJECT,
    Timezone => EMAIL_TIMEZONE,
    Encoding => EMAIL_ENCODING,
    Template => {
      text => EMAIL_TMPL_TXT,
      html => EMAIL_TMPL_HTML,
    },
    TmplParams => \%params,
    TmplOptions => \%options,
  );
  # Attach the backup tarball:
  if (EMAIL_ATTACH) {
    # Set content type:
    $mail->attr('content-type' => 'multipart/mixed');
    # Attach the tarball:
    $mail->attach(
      Path => $rossckup,
      Type => 'application/x-gzip',
      Filename => BACKUP_ARCHIVE_NAME . "-$year$month$day.tar.gz",
      Disposition => 'attachment',
    );
  }

  # Status:
  print('STATUS: Sending notification email to ' . EMAIL_TO . "\n");
  # Dispatch:
  $mail->send();
}

# FTP upload:
# @see http://perldoc.perl.org/Net/FTP.html
if (FTP_UPLOAD) {
  # Status:
  print('STATUS: Uploading backup tarball via FTP: ' . FTP_HOST . "\n");
  # Connect:
  my $ftp = Net::FTP->new(FTP_HOST, Debug => 0)
    or die 'ERROR: Could not connect to FTP host.';
  # Login:
  $ftp->login(FTP_USER, FTP_PWD)
    or die 'ERROR: Could not login to the FTP server.';
  # Change dir:
  $ftp->cwd(FTP_DST)
    or die 'ERROR: Could not change the FTP working directory.';
  # Set to binary mode:
  $ftp->binary();
  # Upload backups:
  $ftp->put($rossckup)
    or die('ERROR: Could not upload the backups to the FTP server: ' . $ftp->message);
  # Close FTP session:
  $ftp->quit();

  # Delete local tarball:
  if (BACKUP_DELETE_AFTER) {
    # Status:
    print("STATUS: Deleting local backup tarball.\n");
    # Delete:
    unlink $rossckup;
  }
}

