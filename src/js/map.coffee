ROT = require('rot-js')
_ = require('lodash')

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


class MapWithObjects extends Map
    constructor: () ->
        super()
        @objects = new Map()

    _add: (x, y, obj) ->
        existing = @objects.get(x, y)

        if !existing
            existing = []
            @objects.set(x, y, existing)

        existing.push(obj)

    _remove: (x, y, obj) ->
        existing = @objects.get(x, y) || []

        _.remove(
            existing,
            (item) => item == obj
        )

    addObject: (obj) ->
        @_add(obj.x, obj.y, obj)

    removeObject: (obj) ->
        @_remove(obj.x, obj.y, obj)

    handleMove: (obj, oldPos) ->
        @_remove(oldPos[0], oldPos[1], obj)
        @addObject(obj)

module.exports = {
    Map,
    MapWithObjects
}
