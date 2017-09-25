#!/usr/bin/perl

if(@ARGV == 1)
{
  $Date = $ARGV[0];
}
else
{
  $Date = `date -d "1 days ago" +%Y%m%d`;
  $Date =~ tr/\r\n//d;
}

my $FileName = sprintf("./ftp_all.list");
unless(open(MYFILE, $FileName))
{
  print "can not open file $FileName \n";
  exit;
}

while($line=<MYFILE>)
{
  #-r-xr-Sr-x 1 root root 377 2009-10-18 11:22 ParaEngineSDK/worlds/MyWorlds/AriesLoginBG/AriesLoginBG.worldconfig.txt
  if($line =~ /(\d+)\ +(\d\d\d\d)-(\d\d)-(\d\d)\ +(\d\d)\:(\d\d)\ +ParaEngineSDK\/(.*)$/)
  {
    if($1 != 0)
    {
      $filename = sprintf("%s._dat%d-%d-%d-%d-%d_l%d\n",$7,$2,$3,$4,$5,$6,$1);
      $filename = lc($filename);
      print $filename;
    }
  }
}
close(MYFILE);
