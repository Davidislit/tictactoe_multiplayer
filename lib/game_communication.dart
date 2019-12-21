import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'websocket_helper.dart';

GameCommunication game = new GameCommunication();

class GameCommunication {
  static final GameCommunication _game = new GameCommunication._internal();

  String _playerName = "";
  String _playerID = "";

  factory GameCommunication() {
    return _game;
  }

  GameCommunication._internal() {
    sockets.initCommunication();
    sockets.addListener(_onMessageReceived);
  }

  String get playerName => _playerName;

  _onMessageReceived(serverMessage) {
    Map message = json.decode(serverMessage);

    switch (message["action"]) {
      case 'connect':
        _playerID = message["data"];
        break;

      default:
        _listeners.forEach((Function callback) {
          callback(message);
        });
        break;
    }
  }

  send(String action, String data) {
    if (action == 'join') {
      _playerName = data;
    }

    sockets.send(json.encode({"action": action, "data": data}));
  }

  sendGamePlay(String action, String data, String playerTurn) {
    if (action == 'join') {
      _playerName = data;
    }

    sockets.send(json
        .encode({"action": action, "data": data, "playerTurn": playerTurn}));
  }

  ObserverList<Function> _listeners = new ObserverList<Function>();
  addListener(Function callback) {
    _listeners.add(callback);
  }

  removeListener(Function callback) {
    _listeners.remove(callback);
  }
}
