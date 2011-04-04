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
  # Email after successful backup:
  EMAIL_NOTIFY => 1,
  # Also attach backup tarball to that email:
  EMAIL_ATTACH => 1,
  # Email sender:
  EMAIL_FROM => 'rossckup@example.com',
  # Email recipient:
  EMAIL_TO => 'client@example.com',
  # Email text template name:
  EMAIL_TMPL_TXT => 'template.txt.tt',
  # Email HTML template name:
  EMAIL_TMPL_HTML => 'template.html.tt',
  # Email templates directory path:
  EMAIL_TMPL_PATH => '/path/to/templates',
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

# Email template params:
my %params;
%params{name} = 'Mr. Foo Bar';

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
  or warn 'There were problems making files tarball.';

# Make databases tarball:
if (BACKUP_DB) {
  # Find the proper command to issue:
  my $cmd = (DB_NAMES eq 'all') ?
    SYS_DUMP . ' --host=' . DB_HOST . ' --user=' . DB_USER . ' --password=' . DB_PWD . " --add-drop-table --all-databases -c -l --result-file=$dbckup" :
    SYS_DUMP . ' --host=' . DB_HOST . ' --user=' . DB_USER . ' --password=' . DB_PWD . ' --add-drop-table --databases ' . DB_NAMES . ' -c -l | ' . SYS_GZIP . " > $dbckup";
  # And issue:
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
# @see http://search.cpan.org/~chunzi/MIME-Lite-TT-HTML-0.03/lib/MIME/Lite/TT/HTML.pm
if (EMAIL_NOTIFY) {
  # Email template options:
  my %options;
  %options{INCLUDE_PATH} = EMAIL_TMPL_PATH;

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
      Type => '',
      Path => $rossckup,
      Filename => BACKUP_ARCHIVE_NAME . "-$year$month$day.tar.gz",
      Disposition => 'attachment',
    );
  }
  # Dispatch:
  $mail->send();
}

# FTP upload:
# @see http://perldoc.perl.org/Net/FTP.html
if (FTP_UPLOAD) {
  # Connect:
  my $ftp = Net::FTP->new(FTP_HOST, Debug => 0)
    or die 'Err! Could not connect to FTP host.';
  # Login:
  $ftp->login()
    or die 'Err! Could not login to the FTP server.';
  # Change dir:
  $ftp->cwd(FTP_DST)
    or die 'Err! Could not change the FTP working directory.';
  # Set to binary mode:
  $ftp->binary();
  # Upload backups:
  $ftp->put($rossckup)
    or die('Err! Could not upload the backups to the FTP server.');
  # Close FTP session:
  $ftp->quit();

  # Delete local tarball:
  if (BACKUP_DELETE_AFTER) {
    unlink $rossckup;
  }
}

