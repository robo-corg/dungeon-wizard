require('es5-shim')
ROT = require('rot-js')
Q = require('q')
_ = require('lodash')
maps = require('map')

Map = maps.Map
MapWithObjects = maps.MapWithObjects

Events = require('minivents')

randomItem = (arr) ->
    return arr[Math.floor(ROT.RNG.getUniform() * arr.length)]

randomDir = () ->
    return randomItem(ROT.DIRS[8])

class Creature
    constructor: (game, pos) ->
        @game = game
        @x = pos[0]
        @y = pos[1]
        @action = Q.defer()
        @events = new Events()

    canMove: (dir) ->
        return dir != null && @game.map.get(@x + dir[0], @y + dir[1])

    isEnemy: (other) ->
        return other != @

    firstEnemyInDir: (dir) ->
        x = @x + dir[0]
        y = @y + dir[1]

        return _.find(
            @game.map.objects.get(x, y),
            (obj) => @isEnemy(obj)
        ) || null

    move: (dir) ->
        console.log('move: ' + @constructor.name)
        @action.resolve(() =>
            if !@canMove(dir)
                return

            oldPos = [@x, @y]

            @x += dir[0]
            @y += dir[1]

            @game.events.emit('move', @, oldPos)
        )

    attack: (other) ->
        other.die()

    die: () ->
        console.log(@constructor.name + ': I died')

    act: () ->
        console.log('act: ' + @constructor.name)

        @events.emit('before-act')

        return @action.promise.then(
            (action) => action()
        ).then(() =>
            @action = Q.defer()
        ).catch((err) =>
            console.log("Error in action: " + err + "\n" + err.stack)
        )



class Player extends Creature
    draw: (display) ->
        display.draw(@x,  @y, "@", "#ff0")


class Monster extends Creature
    draw: (display) ->
        display.draw(@x,  @y, "g", "#00ff00")


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

        window.addEventListener('keydown',
            (e) => @handleKeyEvent(e)
        )

    handleKeyEvent: (e) ->
        dir = keyEventToDir(e)

        if dir == null
            return

        enemy = @target.firstEnemyInDir(dir)

        if enemy?
            console.log("Found enemy: " + enemy)
            @target.attack(enemy)
        else if @target.canMove(dir)
            @target.move(dir)


class MonsterController
    constructor: (target) ->
        @target = target

        @target.events.on('before-act', @think.bind(@))

    think: () ->
        @target.move(randomDir())




class Game
    constructor: () ->
        @events = new Events()
        @map = new MapWithObjects()
        @display = new ROT.Display()
        document.body.appendChild(@display.getContainer())

        @_generateMap()
        @_drawWholeMap()

        @scheduler = new ROT.Scheduler.Simple()
        @scheduler.add(this.player, true)

        @engine = new ROT.Engine(@scheduler)
        @engine.start()

        @player = new Player(@, @map.randomLocation())
        new PlayerController(@player)
        @addObject(@player)

        @monster = new Monster(@, @map.randomLocation())
        new MonsterController(@monster)
        @addObject(@monster)

        @events.on('move', @_handleMove.bind(@))
        @events.on('move', @map.handleMove.bind(@map))

        @engine.start()

    addObject: (obj) ->
        @scheduler.add(obj, true)
        obj.draw(@display)

    removeObject: (obj) ->
        @scheduler.remove(obj)
        @_drawMapTileAt([obj.x, obj.y])

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
