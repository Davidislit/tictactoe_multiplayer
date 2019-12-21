import 'package:flutter/material.dart';
import 'game_communication.dart';

class GamePageScreen extends StatefulWidget {
  GamePageScreen({
    Key key,
    this.opponentName,
    this.character,
  }) : super(key: key);

  final String opponentName;

  final String character;

  @override
  _GamePageScreenState createState() => _GamePageScreenState();
}

class _GamePageScreenState extends State<GamePageScreen> {
  AssetImage cross = AssetImage('assets/cross.png');
  AssetImage circle = AssetImage('assets/circle.png');
  AssetImage edit = AssetImage('assets/edit.png');
  int crossScore = 0;
  int circleScore = 0;
  bool isCross;
  bool isGameOn = true;
  List<String> gameState;
  String playerTurn;
  String gameResult;

  @override
  void initState() {
    super.initState();
    _resetGame();
    game.addListener(_onAction);
  }

  @override
  void dispose() {
    game.removeListener(_onAction);
    super.dispose();
  }

  _onAction(message) {
    switch (message["action"]) {
      case 'resigned':
        _alertResigned();
        break;

      case 'play':
        playerTurn = message["playerTurn"];
        gameState = message["data"].split(';');
        // Force rebuild
        setState(() {});
        break;

      case 'show_winner':
        gameResult = message["data"];
        _showGameResult(gameResult);
        break;

      case 'play_again':
        _resetGame();
        Navigator.of(context).pop();
        break;
    }
  }

  _resetGame() {
    setState(() {
      this.gameState = [
        "empty",
        "empty",
        "empty",
        "empty",
        "empty",
        "empty",
        "empty",
        "empty",
        "empty",
      ];
      playerTurn = 'X';
    });
  }

  _alertResigned() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text('Opponent has resigned'),
            content: new Text('YOU WON! The opponent has resigned :D'),
            actions: <Widget>[
              new FlatButton(
                child: new Text('Bye'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  _doResign() {
    game.send('resign', '');
    Navigator.of(context).pop();
  }

  playGame(int index) {
    if (widget.character == playerTurn) {
      if (this.gameState[index] == 'empty') {
        setState(() {
          if (widget.character == 'X') {
            this.gameState[index] = 'cross';
            playerTurn = 'O';
          } else {
            this.gameState[index] = 'circle';
            playerTurn = 'X';
          }
          this.playGameTurn();
        });
      }
    }
  }

  playGameTurn() {
    game.sendGamePlay('play', this.gameState.join(';'), playerTurn);
  }

  AssetImage getImage(String value) {
    switch (value) {
      case ('empty'):
        return edit;
        break;
      case ('cross'):
        return cross;
        break;
      case ('circle'):
        return circle;
        break;
    }
  }

  _getGameResultAndIncrementResult(String gameResult) {
    switch (gameResult) {
      case 'cross':
        setState(() {
          crossScore = crossScore + 1;
        });
        return 'X';
      case 'circle':
        setState(() {
          circleScore = circleScore + 1;
        });
        return 'O';
      case 'draw':
        return 'draw';
    }
  }

  _showGameResult(String gameResult) {
    String gameWinner = _getGameResultAndIncrementResult(gameResult);
    String title;
    bool winner;
    if (gameWinner == 'draw') {
      title = 'Draw :O';
    } else {
      winner = widget.character == gameWinner ? true : false;
      title = winner ? 'You Won :)' : 'You Lost :(';
    }
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text(title),
            content:
                new Text('No Worries you have 5 seconds to play again :D!!!'),
          );
        });
  }

  String _showPlayerTurn(String playerTurn) {
    if (widget.character == playerTurn) {
      return "Your Turn!";
    } else {
      return "Opponent Turn!";
    }
  }

  _askIfResign() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text('Resign?'),
            content: new Text('Are you sure you want to resign?'),
            actions: <Widget>[
              new FlatButton(
                child: new Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text('Yes'),
                onPressed: () {
                  _doResign();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return new SafeArea(
      top: false,
      bottom: false,
      child: new Scaffold(
        appBar: new AppBar(
            title: new Text(
              'Game against: ${widget.opponentName}',
              style: new TextStyle(fontSize: 16.0),
            ),
            leading: new IconButton(
                icon: new Icon(Icons.arrow_back),
                onPressed: () {
                  _askIfResign();
                }),
            actions: <Widget>[
              new RaisedButton(
                onPressed: _doResign,
                child: new Text('Resign'),
              ),
            ]),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text('Cross Score: $crossScore',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 45),
                  ),
                  Text('Circle Score: $circleScore',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Text("${_showPlayerTurn(playerTurn)}",
                  style: TextStyle(fontSize: 18)),
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: this.gameState.length,
                itemBuilder: (ctx, i) => SizedBox(
                  width: 100,
                  height: 100,
                  child: MaterialButton(
                    onPressed: () {
                      this.playGame(i);
                    },
                    child: Image(
                      image: this.getImage(this.gameState[i]),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
