require('es5-shim')
ROT = require('rot-js')
Q = require('q')

Events = require('minivents')


class Creature
    constructor: (game, pos) ->
        @game = game
        @x = pos[0]
        @y = pos[1]
        @action = Q.defer()

    canMove: (dir) ->
        return @game.map.get(@x + dir[0], @y + dir[1])

    move: (dir) ->
        @action.resolve(() =>
            oldPos = [@x, @y]

            @x += dir[0]
            @y += dir[1]

            @game.events.emit('move', @, oldPos)
        )

    act: () ->
        return @action.promise.then(
            (action) => action()
        ).then(() =>
            @action = Q.defer()
        )



class Player extends Creature
    draw: (display) ->
        display.draw(@x,  @y, "@", "#ff0")


class Monster extends Creature
    draw: (display) ->
        display.draw(@x,  @y, "g", "#00ff")


keyEventToDir = (e) ->
    code = e.keyCode

    keyMap = []
    keyMap[38] = 0
    keyMap[33] = 1
    keyMap[39] = 2
    keyMap[34] = 3
    keyMap[40] = 4
    keyMap[35] = 5
    keyMap[37] = 6
    keyMap[36] = 7

    dirNum = keyMap[code]

    if dirNum == undefined
        return null

    # is there a free space?
    return ROT.DIRS[8][dirNum]


class PlayerController
    constructor: (target) ->
        @target = target

    handleKeyEvent: (e) ->
        dir = keyEventToDir(e)

        if dir != null && !@target.canMove(dir)
            return

        @target.move(dir)


class MonsterController
    constructor: (target) ->
        @target = target


class Map
    constructor: () ->
        @data = {}

    get: (x, y) ->
        return @data[x+','+y]

    set: (x, y, val) ->
        @data[x+','+y] = val

    randomLocation: () ->
        freeCells = Object.keys(@data)

        index = Math.floor(ROT.RNG.getUniform() * freeCells.length)
        key = freeCells.splice(index, 1)[0]
        parts = key.split(",")
        x = parseInt(parts[0])
        y = parseInt(parts[1])

        return [x, y]

    activeLocations: (cb) ->
        for key, tile of @data
            parts = key.split(",")
            x = parseInt(parts[0])
            y = parseInt(parts[1])

            cb(x, y, tile)


class Game
    constructor: () ->
        @events = new Events()
        @map = new Map()
        @display = new ROT.Display()
        document.body.appendChild(@display.getContainer())

        @_generateMap()
        @_drawWholeMap()

        @scheduler = new ROT.Scheduler.Simple()
        @scheduler.add(this.player, true)

        @engine = new ROT.Engine(@scheduler)
        @engine.start()

        @player = new Player(@, @map.randomLocation())
        @playerController = new PlayerController(@player)
        @addObject(@player)

        window.addEventListener('keydown', 
            (e) => @playerController.handleKeyEvent(e)
        )

        @events.on('move', @_handleMove.bind(@))

        @engine.start()

    addObject: (obj) ->
        @scheduler.add(obj, true)
        obj.draw(@display)

    _handleMove: (obj, oldPos) ->
        @_drawMapTileAt(oldPos)
        obj.draw(@display)

    _generateMap: () ->
        digger = new ROT.Map.Digger()
        digCallback = (x, y, value) ->
            if value
                return
            @map.set(x, y, '.')

        digger.create(digCallback.bind(@))

    _drawMapTileAt: (pos) ->
        tile = @map.get(pos[0], pos[1])
        @display.draw(pos[0], pos[1], tile)

    _drawWholeMap: () ->
        @map.activeLocations(@display.draw.bind(@display))

(new Game())
