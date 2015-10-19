Request = require 'superagent'
_ = require "underscore"

REQUEST_INTERVAL = 1*1000
ENDPOINTS =
    NEW: "new-game"
    EVENT: "add-events"
    GET_SCORE: "get-scores"

serverUrl = null
requestTimer = null
game = null
events = []

getScores = (gameType, cb) ->
    Request
        .get "#{serverUrl}/#{ENDPOINTS.GET_SCORE}/#{gameType}"
        .end (err, response) ->
            if error = (isRequestError err, response)
                console.log "Couldn't get score: #{err.toString()}"
                return cb?(err)
            answer = _.sortBy(response.body[1], "score")
            cb answer

init = (url) ->
    serverUrl = url
    events = []
    console.log "Initializing highscore client", serverUrl

startGame = (gameType, user, cb) ->
    console.log "#{user} is starting game: ", gameType

    # error if connector is not initialized
    if not serverUrl? or serverUrl is ""
        console.log "Couldn't start game, connector is not initialized"
        return

    #initiate game
    game =
        "user-name": user
        "game-type": gameType
        "start-time": (new Date()).toISOString()
        "score": 0
        "id": null

    # empty events
    events = []

    #clearTimer if it runs
    if requestTimer?
        clearInterval requestTimer

    #sending game start to server
    Request
        .post "#{serverUrl}/#{ENDPOINTS.NEW}/#{gameType}"
        .send game
        .end (err, response) ->
            if error = (isRequestError err, response)
                console.log "Couldn't start game: #{err.toString()}"
                return cb? err, null
            game.id = response.body["game-id"]
            startEventSenderTimer()
            cb? null, response.body["game-id"]

eventHappened = (eventType, score) ->
    #save event
    events.push
        type: eventType,
        timestamp: elapsedTime()

    #update game score if given
    if score?
        game.score = score

isRequestError = (err, response) ->
    return err?
    #return true if everything was ok
    #return false otherwise

sendEvents = () ->
    # if event happened since the last sending
    if events.length isnt 0
        eventsToSend = _.clone events
        events = []
        message =
            "game-id": game.id
            "score": game.score
            "duration": elapsedTime()
            "events": eventsToSend

        Request
            .post "#{serverUrl}/#{ENDPOINTS.EVENT}/#{game.id}"
            .send message
            .end (err, response) ->
                if err?
                    console.log err

elapsedTime = (time) ->
    startTime = new Date(game["start-time"])
    if time?
        return time - startTime
    else
        return Date.now() - startTime

getGameId = ->
    game?.id

startEventSenderTimer = () ->
    requestTimer = setInterval sendEvents, REQUEST_INTERVAL

window.Highscore = module.exports =
    init: init
    startGame: startGame
    eventHappened: eventHappened
    getScores: getScores
    gameId: getGameId
