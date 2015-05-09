require('es5-shim')
ROT = require('rot-js')
_ = require('lodash')
{Map, MapWithObjects} = require('map')
{Player, PlayerController, Monster, MonsterController} = require('creatures')

Events = require('events').EventEmitter

class Scene
    constructor: (game) ->
        @game = game
        @display = game.display
        @map = new MapWithObjects()
        @vizMap = new Map()
        @exploredMap = new Map()

        @game.events.on('move', @_handleMove.bind(@))
        @game.events.on('move', @map.handleMove.bind(@map))

    addObject: (obj) ->
        @map.addObject(obj)
        # TODO: Check vis first (may require calculating it)
        # obj.draw(@display)

    removeObject: (obj) ->
        @map.removeObject(obj)
        @_drawMapTileAt([obj.x, obj.y])

    lightPassesThroughTile: (tile) ->
        return tile? && tile == '.'

    passable: (tile) ->
        return tile? && tile == '.'

    impassible: (tile) ->
        return !@passable(tile)

    updateVisibilityFov: (source) ->
        @display.clear()
        @vizMap = new Map()

        @drawWholeMap()

        lightPassesThrough = (x, y) =>
            return @lightPassesThroughTile(@map.get(x, y))

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

    generateMap: () ->
        digger = new ROT.Map.Digger()
        digCallback = (x, y, value) ->
            if value
                return
            @map.set(x, y, '.')

        digger.create(digCallback.bind(@))

        @map.activeLocations((x, y, tile) =>
            for dir in ROT.DIRS[8]
                wx = x + dir[0]
                wy = y + dir[1]

                if !@map.get(wx, wy)?
                    @map.set(wx, wy, '#')
        )

    _drawMapTileAt: (pos) ->
        tile = @map.get(pos[0], pos[1])

        x = pos[0]
        y = pos[1]

        if @vizMap.get(x, y)
            @display.draw(x, y, tile)
        else if @exploredMap.get(x, y)
            @display.draw(x, y, tile, '#333333')

    drawWholeMap: () ->
        @map.activeLocations((x, y, tile) =>
            @_drawMapTileAt([x, y])
        )

    _handleMove: (obj, oldPos) ->
        if @vizMap.get(obj.x, obj.y)
            @_drawMapTileAt(oldPos)
            obj.draw(@display)

    randomSpawnLocation: () ->
        return @map.randomLocation(@passable.bind(@))

class Game
    constructor: () ->
        @events = new Events()

        @display = new ROT.Display()
        document.body.appendChild(@display.getContainer())

        @scene = new Scene(@)
        @scene.generateMap()
        @scene.drawWholeMap()

        @scheduler = new ROT.Scheduler.Simple()
        @scheduler.add(this.player, true)

        @engine = new ROT.Engine(@scheduler)
        @engine.start()

        @player = new Player(@, @scene.randomSpawnLocation())
        new PlayerController(@player)
        @addObject(@player)
        @scene.updateVisibilityFov(@player)

        @monster = new Monster(@, @scene.randomSpawnLocation())
        new MonsterController(@monster)
        @addObject(@monster)


        @engine.start()


    addObject: (obj) ->
        @scheduler.add(obj, true)
        @scene.addObject(obj)

    removeObject: (obj) ->
        @scheduler.remove(obj)
        @scene.removeObject(obj)



(new Game())
