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

attack = (weapon, target, agressor) ->
    result = weapon.attack(target, agressor)

    if result?
        target.takeDamage(result)

class Creature
    maxHp: 1
    weapon: null

    constructor: (game, pos) ->
        @game = game
        @x = pos[0]
        @y = pos[1]
        @action = Q.defer()
        @events = new Events()

        @hp = @maxHp

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
        @action.resolve(() =>
            if !@canMove(dir)
                return

            oldPos = [@x, @y]

            @x += dir[0]
            @y += dir[1]

            @game.events.emit('move', @, oldPos)
            @postMove(oldPos)
        )

    attack: (other) ->
        @action.resolve(() =>
            attack(@weapon, other, @)
        )

    getSightRadius: () ->
        return 5

    postMove: (oldPos) ->

    takeDamage: (damage) ->
        @hp -= damage.amount

        @game.events.emit('take-damage', damage)

        if @hp <= 0
            @die()

    die: () ->
        @game.removeObject(@)
        @game.events.emit('die', @)

    act: () ->
        @events.emit('before-act')

        return @action.promise.then(
            (action) => action()
        ).then(() =>
            @action = Q.defer()
        ).catch((err) =>
            console.log("Error in action: " + err + "\n" + err.stack)
            @action = Q.defer()
        )

class Sword
    attack: (target, agressor) ->
        return amount: 3

class Player extends Creature
    weapon: new Sword()

    draw: (display) ->
        display.draw(@x,  @y, "@", "#ff0")

    postMove: (oldPos) ->
        @game.updateVisibilityFov(@)


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
        @vizMap = new Map()
        @exploredMap = new Map()

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
        @updateVisibilityFov(@player)

        @monster = new Monster(@, @map.randomLocation())
        new MonsterController(@monster)
        @addObject(@monster)

        @events.on('move', @_handleMove.bind(@))
        @events.on('move', @map.handleMove.bind(@map))

        @engine.start()

    updateVisibilityFov: (source) ->
        @display.clear()
        @vizMap = new Map()

        @_drawWholeMap()

        lightPassesThrough = (x, y) =>
            return @map.get(x, y)?

        fov = new ROT.FOV.PreciseShadowcasting(lightPassesThrough)
        radius = source.getSightRadius()

        fov.compute(source.x, source.y, radius, (x ,y) =>
            @vizMap.set(x, y, true)
            @exploredMap.set(x, y, true)

            @_drawMapTileAt([x, y])

            objects = @map.objects.get(x, y) || []

            for object in objects
                do (object) =>
                    object.draw(@display)
        )

    addObject: (obj) ->
        @scheduler.add(obj, true)
        @map.addObject(obj)
        # TODO: Check vis first (may require calculating it)
        # obj.draw(@display)

    removeObject: (obj) ->
        @scheduler.remove(obj)
        @map.removeObject(obj)
        @_drawMapTileAt([obj.x, obj.y])

    _handleMove: (obj, oldPos) ->
        if @vizMap.get(obj.x, obj.y)
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

        x = pos[0]
        y = pos[1]

        if @vizMap.get(x, y)
            @display.draw(x, y, tile)
        else if @exploredMap.get(x, y)
            @display.draw(x, y, tile, '#333333')

    _drawWholeMap: () ->
        @map.activeLocations((x, y, tile) =>
            @_drawMapTileAt([x, y])
        )

(new Game())
