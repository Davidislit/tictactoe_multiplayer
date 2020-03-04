import 'dart:convert';

import 'package:client_experimental/helper/socket_service.dart';
import 'package:client_experimental/main.dart';
import 'package:flutter/material.dart';
import 'game_communication.dart';
import 'game_page_screen.dart';

class StartPageScreen extends StatefulWidget {
  @override
  _StartPageStateScreen createState() => _StartPageStateScreen();
}

class _StartPageStateScreen extends State<StartPageScreen> {
  SocketService _socketService = new SocketService();
  static final TextEditingController _name = new TextEditingController();
  String playerName;
  List<dynamic> playersList = <dynamic>[];
  bool _isDialogOpen = false;
  bool _showPlayersList = false;

  @override
  void initState() {
    super.initState();
    _socketService.addListener(_onGameDataReceived);
    game.addListener(_onGameDataReceived);
    _handlePageSubscribes();
  }

  @override
  void dispose() {
    _socketService.removeListener(_onGameDataReceived);
    game.removeListener(_onGameDataReceived);
    super.dispose();
  }

  _handlePageSubscribes() {
    _socketService.addSubscribe('receive_message', (jsonData) {
      Map<String, dynamic> message = json.decode(jsonData);
      switch (message["action"]) {
        case "player_list":
          playersList = message["data"];
          setState(() {});
          print(playersList);
          break;

        default:
          break;
      }
    });
  }

  // SOON TO BE DELETED
  _onGameDataReceived(message) {
    switch (message["action"]) {
      case "players_list":
        playersList = message["data"];
        setState(() {});
        break;

      case 'new_game':
        Navigator.of(context).pop();
        Navigator.push(
            context,
            new MaterialPageRoute(
              builder: (BuildContext context) => new GamePageScreen(
                opponentName: message["data"], // Name of the opponent
                character: 'O',
              ),
            ));
        break;

      case 'request_game':
        _gameRequestDialog(message["data"], message["opponentId"].toString());
        break;

      case 'cancel_request_game':
        if (_isDialogOpen == true) {
          Navigator.of(context).pop();
        }
        _cancledGamerequest(message["data"]);
        break;
    }
  }

  _gameRequestDialog(String opponentName, String opponentId) {
    _isDialogOpen = true;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text('An Opponent Request to play!'),
            content: new Text('${opponentName} want\'s to play agasint you'),
            actions: <Widget>[
              new FlatButton(
                child: new Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _cancelGameRequest(opponentId);
                  _isDialogOpen = false;
                },
              ),
              new FlatButton(
                  child: new Text('Play'),
                  onPressed: () {
                    _isDialogOpen = false;
                    Navigator.of(context).pop();
                    _onPlayGame(opponentName, opponentId);
                  })
            ],
          );
        });
  }

  Widget _buildJoin() {
    if (_socketService.playerName != "") {
      return new Container();
    }
    return new Container(
      padding: const EdgeInsets.all(16.0),
      child: new Column(
        children: <Widget>[
          new TextField(
            controller: _name,
            keyboardType: TextInputType.text,
            decoration: new InputDecoration(
              hintText: 'Enter your name',
              contentPadding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
              border: new OutlineInputBorder(
                borderRadius: new BorderRadius.circular(32.0),
              ),
              icon: const Icon(Icons.person),
            ),
          ),
          new Padding(
            padding: const EdgeInsets.all(8.0),
            child: new RaisedButton(
              onPressed: _onGameJoin,
              child: new Text('Join...'),
            ),
          ),
        ],
      ),
    );
  }

  _onGameJoin() {
    _socketService.setPlayer(_name.text);
    _socketService.send('join', _name.text);
    // game.send('join', _name.text);
    // if (playersList.length > 1) {

    // }
    setState(() {
      _showPlayersList = true;
    });

    /// Force a rebuild
    setState(() {});
    print("playerName: $_socketService.playerName");
    print(_showPlayersList);
  }

  Widget _playersList() {
    if (_socketService.playerName == "" || playersList.length > 1) {
      return new Container();
    }

    List<Widget> children = playersList.map((playerInfo) {
      return new ListTile(
        title: new Text(playerInfo["name"]),
        trailing: new RaisedButton(
          onPressed: () {
            _requestPlayGame(playerInfo["name"], playerInfo["id"]);
          },
          child: new Text('Play'),
        ),
      );
    }).toList();

    return new Column(
      children: children,
    );
  }

  _requestPlayGame(String opponentName, String opponentId) {
    game.send('request_game', opponentId);
    _isDialogOpen = true;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text('Awaiting'),
            content: new Text(
                'Please wait untill ${opponentName} will response to your game.'),
            actions: <Widget>[
              new FlatButton(
                child: new Text('Cancel'),
                onPressed: () {
                  _isDialogOpen = false;
                  Navigator.of(context).pop();
                  _cancelGameRequest(opponentId);
                },
              ),
            ],
          );
        });
  }

  _cancelGameRequest(String opponentId) {
    game.send('cancel_request_game', opponentId);
  }

  _cancledGamerequest(String opponentName) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text('Game Request Cancelled'),
            content: new Text('${opponentName} canceled the game request.'),
            actions: <Widget>[
              new FlatButton(
                  child: new Text('Cancel'),
                  onPressed: () {
                    _isDialogOpen = false;
                    Navigator.of(context).pop();
                  }),
            ],
          );
        });
  }

  _onPlayGame(String opponentName, String opponentId) {
    game.send('new_game', opponentId);

    Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (BuildContext context) => new GamePageScreen(
            opponentName: opponentName,
            character: 'X',
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return new SafeArea(
      bottom: false,
      top: false,
      child: Scaffold(
        appBar: new AppBar(
          title: new Text('TicTacToe Multiplayer'),
        ),
        body: SingleChildScrollView(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              _buildJoin(),
              if (_socketService.playerName != "")
                Container(
                  alignment: AlignmentDirectional.topStart,
                  padding:
                      EdgeInsets.symmetric(vertical: 5.0, horizontal: 15.0),
                  child: new Text(
                    'Player Name: ${_socketService.playerName}',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              if (_showPlayersList == true)
                new Text(
                  'List of players:',
                  style: TextStyle(fontSize: 20),
                ),
              _playersList(),
            ],
          ),
        ),
      ),
    );
  }
}
