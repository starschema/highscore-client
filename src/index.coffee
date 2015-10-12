Request = require "browser-request"
_ = require "underscore"

REQUEST_INTERVAL = 1*1000
ENDPOINTS =
    NEW: "new-game"
    EVENT: "add-events"

serverUrl = null
requestTimer = null
game = null
events = []

init = (url) ->
    serverUrl = url
    events = []

startGame = (gameType, user, cb) ->
    # error if connector is not initialized
    if not serverUrl? or serverUrl is ""
        console.log "Couldn't start game, connector is not initialized"
        return

    #initiate game
    game =
        "user-name": user
        "game-type": gameType
        "start-time": Date.now()
        "score": 0
        "id": null

    # empty events
    events = []

    #clearTimer if it runs
    if requestTimer?
        clearInterval requestTimer

    #sending game start to server
    Request.post "#{serverUrl}/#{ENDPOINTS.NEW}/#{gameType}", game, (err, response, body) ->
        if error = (isRequestError err, response)
            console.log "Couldn't start game: #{error.toString()}"
            return cb err
        game.id = body["game-id"]
        startEventSenderTimer()
        cb null

eventHappened = (eventType, score) ->
    #save event
    events.push
        type: eventType,
        timestamp: elapsedTime()

    #update game score if given
    if score?
        game.score = score

isRequestError = (err, response) ->
    #return true if everything was ok
    #return false otherwise

sendEvents = () ->
    # if event happened since the last sending
    if events.length isnt 0
        eventsToSend = _.clone events
        message =
            "game-id": game.id
            "score": game.score
            "duration": elapsedTime()
            "events": eventsToSend

        Request.post "#{serverUrl}/#{ENDPOINTS.EVENT}", message, (err, response, body) ->
            #if everything was ok
            unless isRequestError err, response
                #clear the already sent event from the list
                _.difference(events, eventsToSend)

elapsedTime = (time) ->
    if time?
        return time - game["start-time"]
    else
        return Date.now() - game["start-time"]


startEventSenderTimer = () ->
    requestTimer = setInterval sendEvents, REQUEST_INTERVAL

window.Highscore = module.exports =
    init: init
    startGame: startGame
    eventHappened: eventHappened
