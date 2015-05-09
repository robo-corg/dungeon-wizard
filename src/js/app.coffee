require('es5-shim')
ROT = require('rot-js')
_ = require('lodash')
{Map, MapWithObjects} = require('map')
{Player, PlayerController, Monster, MonsterController} = require('creatures')

Events = require('events').EventEmitter


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

        @player = new Player(@, @map.randomLocation(@passable.bind(@)))
        new PlayerController(@player)
        @addObject(@player)
        @updateVisibilityFov(@player)

        @monster = new Monster(@, @map.randomLocation(@passable.bind(@)))
        new MonsterController(@monster)
        @addObject(@monster)

        @events.on('move', @_handleMove.bind(@))
        @events.on('move', @map.handleMove.bind(@map))

        @engine.start()

    lightPassesThroughTile: (tile) ->
        return tile? && tile == '.'

    passable: (tile) ->
        return tile? && tile == '.'

    impassible: (tile) ->
        return !@passable(tile)

    updateVisibilityFov: (source) ->
        @display.clear()
        @vizMap = new Map()

        @_drawWholeMap()

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

    _drawWholeMap: () ->
        @map.activeLocations((x, y, tile) =>
            @_drawMapTileAt([x, y])
        )

(new Game())
