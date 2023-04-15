/// 試合
class Match {
  /// 年度
  final String year;

  /// 大会
  final String tournaments;

  /// 節
  final String sec;

  /// 試合日
  final String date;

  /// K/O時刻
  final String kickoff;

  /// ホーム
  final String home;

  /// スコア
  final String score;

  /// アウェイ
  final String away;

  /// スタジアム
  final String venue;

  /// 入場者数
  final String att;

  /// インターネット中継・TV放送
  final String broadcast;

  const Match(
      {required this.year,
      required this.tournaments,
      required this.sec,
      required this.date,
      required this.kickoff,
      required this.home,
      required this.score,
      required this.away,
      required this.venue,
      required this.att,
      required this.broadcast});

  @override
  String toString() {
    return 'Match('
        'year: "$year", '
        'tournaments: "$tournaments", '
        'sec: "$sec", '
        'date: "$date", '
        'kickoff: "$kickoff", '
        'home: "$home", '
        'score: "$score", '
        'away: "$away", '
        'venue: "$venue", '
        'att: "$att", '
        'broadcast: "$broadcast"'
        ')';
  }
}
