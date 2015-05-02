assert = require('chai').assert
maps = require('../src/js/map')

Map = maps.Map
MapWithObjects = maps.MapWithObjects


describe('Map', () ->
    describe('get', () ->
        it('should return undefined for unset item', () ->
            map = new Map()

            assert.isUndefined(map.get(0, 0))
        )

        it('should return set for set item', () ->
            map = new Map()
            map.set(1, 1, 42)

            assert.equal(map.get(1, 1), 42)
        )
    )
)

describe('MapWithObjects', () ->
    describe('addObject', () ->
        it('should add an object to .objects', () ->
            map = new MapWithObjects()
            obj = {x: 0, y: 0, id: 5}

            map.addObject(obj)
            assert.deepEqual(map.objects.get(0, 0), [obj])
        )
    )
    describe('handleMove', () ->
        it('should leave only one mapped instance of object', () ->
            map = new MapWithObjects()
            obj = {x: 0, y: 0, id: 5}

            map.addObject(obj)

            obj.x = 1
            obj.y = 1

            map.handleMove(obj, [0, 0])

            assert.deepEqual(map.objects.get(0, 0), [])
            assert.deepEqual(map.objects.get(1, 1), [obj])
        )
    )
)
