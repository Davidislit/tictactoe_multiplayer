const {
    checkWin
} = require('./logic');
/**
 * Parameters
 */
var webSocketsServerPort = 1337; // Adapt to the listening port number you want to use
/**
 * Global variables
 */
// websocket and http servers
var webSocketServer = require('websocket').server;
var http = require('http');
/**
 * HTTP server to implement WebSockets
 */
var server = http.createServer(function (request, response) {
    // Not important for us. We're writing WebSocket server,
    // not HTTP server
});
server.listen(webSocketsServerPort, function () {
    console.log((new Date()) + " Server is listening on port " +
        webSocketsServerPort);
});

/**
 * WebSocket server
 */
var wsServer = new webSocketServer({
    // WebSocket server is tied to a HTTP server. WebSocket
    // request is just an enhanced HTTP request. For more info 
    // http://tools.ietf.org/html/rfc6455#page-6
    httpServer: server
});

// This callback function is called every time someone
// tries to connect to the WebSocket server
wsServer.on('request', function (request) {

    var connection = request.accept(null, request.origin);

    //
    // New Player has connected.  So let's record its socket
    //
    var player = new Player(request.key, connection);

    //
    // Add the player to the list of all players
    //
    Players.push(player);

    //
    // We need to return the unique id of that player to the player itself
    //
    connection.sendUTF(JSON.stringify({
        action: 'connect',
        data: player.id
    }));

    //
    // Listen to any message sent by that player
    //
    connection.on('message', function (data) {

        //
        // Process the requested action
        //
        var message = JSON.parse(data.utf8Data);
        switch (message.action) {
            //
            // When the user sends the "join" action, he provides a name.
            // Let's record it and as the player has a name, let's 
            // broadcast the list of all the players to everyone
            //
            case 'join':
                player.name = message.data;
                BroadcastPlayersList();
                break;

                //
                // When a player resigns, we need to break the relationship
                // between the 2 players and notify the other player 
                // that the first one resigned
                //
            case 'resign':
                Players[player.opponentIndex]
                    .connection
                    .sendUTF(JSON.stringify({
                        'action': 'resigned'
                    }));
                setTimeout(function () {
                    Players[player.opponentIndex].opponentIndex = player.opponentIndex = null;
                }, 0);
                break;

                //
                // A player initiates a new game.
                // Let's create a relationship between the 2 players and
                // notify the other player that a new game starts
                // 
            case 'new_game':
                player.setOpponent(message.data);
                Players[player.opponentIndex].setOpponent(player.id);
                Players[player.opponentIndex]
                    .connection
                    .sendUTF(JSON.stringify({
                        'action': 'new_game',
                        'data': player.name
                    }));
                break;

            case 'request_game':
                player.setOpponent(message.data);
                Players[player.opponentIndex]
                    .connection
                    .sendUTF(JSON.stringify({
                        'action': 'request_game',
                        'data': player.name,
                        'opponentId': player.opponentIndex
                    }));
                //
                // A player sends a move.  Let's forward the move to the other player
                //
            case 'play':
                const gameState = message.data.split(';');
                var winner = checkWin(gameState);
                if (winner == null) {
                    Players[player.opponentIndex]
                        .connection
                        .sendUTF(JSON.stringify({
                            'action': 'play',
                            'data': message.data,
                            'playerTurn': message.playerTurn,
                        }));
                } else {
                    Players[player.opponentIndex]
                        .connection
                        .sendUTF(JSON.stringify({
                            'action': 'show_winner',
                            'data': winner,
                        }));
                    player.connection.sendUTF(JSON.stringify({
                        'action': 'show_winner',
                        'data': winner,
                    }));
                    setTimeout(() => {
                        Players[player.opponentIndex]
                            .connection
                            .sendUTF(JSON.stringify({
                                'action': 'play_again',
                            }));
                        player.connection.sendUTF(JSON.stringify({
                            'action': 'play_again',
                        }));
                    }, 5000);
                }

                break;

            case 'cancel_request_game':
                Players[player.opponentIndex]
                    .connection
                    .sendUTF(JSON.stringify({
                        'action': 'cancel_request_game',
                        'data': player.name,
                    }));

                setTimeout(function () {
                    Players[player.opponentIndex].opponentIndex = player.opponentIndex = null;
                }, 0);
                break;

            case "choose_starter":
                Players[player.opponentIndex]
                    .connection
                    .sendUTF(JSON.stringify({
                        'action': 'choose_starter',
                        'data': message.data,
                    }))
        }
    });

    // user disconnected
    connection.on('close', function (connection) {
        // We need to remove the corresponding player
        // TODO
    });
});

// -----------------------------------------------------------
// List of all players
// -----------------------------------------------------------
var Players = [];

function Player(id, connection) {
    this.id = id;
    this.connection = connection;
    this.name = "";
    this.opponentIndex = null;
    this.index = Players.length;
}

Player.prototype = {
    getId: function () {
        return {
            name: this.name,
            id: this.id
        };
    },
    setOpponent: function (id) {
        var self = this;
        Players.forEach(function (player, index) {
            if (player.id == id) {
                self.opponentIndex = index;
                Players[index].opponentIndex = self.index;
                return false;
            }
        });
    },
};

function BroadcastPlayersList() {
    var playersList = [];

    Players.forEach(function (player) {
        if (player.name !== '' && player.connection.connected && player.opponentIndex == null) {
            playersList.push(player.getId());
        }
    });

    if (playersList.length == 0) {
        return;
    }

    playersList.forEach((currentPlayer) => {

        const sendingPlayerList = playersList.filter(player => player.name !== currentPlayer.name);

        var message = JSON.stringify({
            'action': 'players_list',
            'data': sendingPlayerList
        });

        const currentPlayerIndex = Players.findIndex(player => player.name == currentPlayer.name);

        Players[currentPlayerIndex].connection.sendUTF(message);

    });
}

setInterval(() => BroadcastPlayersList(), 1000);