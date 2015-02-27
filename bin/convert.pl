#!/usr/bin/perl

use strict;
use warnings;

sub create_tmp_dir{
  `mkdir -p tmp/`;
}

sub get_date{
  my $date = `date +%Y%m%d`;
  chomp $date;
  return $date;
}

sub convert_file_to_linux{
  my ($filename) = @_;

  my $converted_file = "tmp/$filename.utf8";
  my $cmd = "cat $filename | iconv -f sjis -t utf8 | tr \$'\x0d' \$'\n' > $converted_file";
  `$cmd`;
  return $converted_file;
}

#sub get_schema_info{
#  my ($schema_file) = @_;
#  open my $fh,"<".$schema_file;
#  my $line = <$fh>;
#  chomp $line;
#  return (split(/\t/,$line,-1));
#}

sub create_bms_sql{
  my ($converted_file,$type,$team_id) = @_;
  my $date = get_date();
  # とりあえず定形として読む
  # 打撃(dageki)
  # 試合ID  選手ID  選手  内野フライ  内野ゴロ  外野フライ  三振  四球  死球  送りバント  犠打  ヒット  二塁打  三塁打  HR  打点  盗塁
  # 投手(toushu)
  # 試合ID  選手ID  選手  完投  完封  勝  負  セーブ  投球回  投球回1/3 奪三振  失点
  open my $fh,"<".$converted_file;
  while(my $line = <$fh>){
    chomp $line;
    next unless ($line =~ /^[A-Za-z0-9]/);
    my @array = split(/,/,$line,-1);
    for (my $i=0;$i<scalar(@array);++$i){
      $array[$i] = 0 if($array[$i] eq '');
    }
    # TODO
    # player_idとgame_idはPlayers/Gamesテーブルから取得するようにする
    # order(order_id?)を取得
    # input_statusってなんだっけ

    my $sql = "";

    if ($type eq 'dageki'){
      my ($game_id,$player_id,$player,$fly_infield,$fly_outfield,$so,$four,$dead,$bunt,$sac,$single_hit,$double_hit,$triple_hit,$home_run,$hit_score,$steel) = @array;
      # 打席数
      my $TPA = $fly_infield + $fly_outfield + $so + $four + $dead + $bunt + $sac + $single_hit + $double_hit + $triple_hit + $home_run;
      # 打数(except 四球、死球、送りバント、犠打
      my $AB =  $fly_infield + $fly_outfield + $so + $single_hit + $double_hit + $triple_hit + $home_run;
      # 得点、がないので便宜上打点を入れる
      $sql = "INSERT INTO stat_hittings VALUES(NULL,$player_id,$game_id,$TPA,$AB,$single_hit,$double_hit,$triple_hit,$home_run,$so,$four,$dead,$bunt,$sac,$hit_score,$hit_score,$steel,$date,$date,$team_id,1);";
    }elsif($type eq 'toushu'){
      # TODO
      # 被安打、与四球、与死球をバッターのファイルから取得するようにする（無理か？）
      # 試合ID  選手ID  選手  完投  完封  勝  負  セーブ  投球回  投球回1/3 奪三振  失点
      # holdは取ってないので0
      # 自責点=失点
      # 投球回の値がINTなのでとりあえず投球回×3+投球回1/3の値を入れておく
      my ($game_id,$player_id,$player,$kantou,$kanpuu,$win,$lose,$save,$inning,$inning_three,$getk,$lostscore) = @array;
      my $inning_triple = $inning * 3 + $inning_three;
      my $inning_frac   = sprintf("%.2f",$inning_triple/3);
      $sql = "INSERT INTO stat_pitchings VALUES(NULL,$player_id,$game_id,$win,$lose,0,$save,$inning_triple,0,$getk,0,0,$lostscore,$lostscore,$date,$date,$inning_triple,$team_id,0,1);";
    }
    print $sql . "\n";
  }
}

sub main{
  if(@ARGV != 3){
    die('./bin/convert.pl <filename> <type: toushu/dageki> <team_id>');
  }

  # チームIDはDBから引く
  # TODO
  my ($csv_file,$type,$team_id) = ($ARGV[0],$ARGV[1],$ARGV[2]);

  create_tmp_dir();
  my $converted_file = convert_file_to_linux($csv_file);

  create_bms_sql($converted_file,$type,$team_id);

  return 1;
}

&main;
