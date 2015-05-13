require('es5-shim')
ROT = require('rot-js')
_ = require('lodash')
{Map, MapWithObjects} = require('map')
{Scene} = require('scene')
{Player, PlayerController, Monster, MonsterController} = require('creatures')
scenarios = require('scenarios')

Events = require('events').EventEmitter


class Game
    constructor: () ->
        @events = new Events()

        @display = new ROT.Display()
        document.body.appendChild(@display.getContainer())


        @scheduler = new ROT.Scheduler.Simple()
        @engine = new ROT.Engine(@scheduler)

        @scene = null
        
        @setScene(scenarios.newGame(@))

        @engine.start()

    setScene: (scene) ->
        if @scene?
            _.forEach(@scene.objects, @removeObject.bind(@))

        @scene = scene

        if @scene?
            _.forEach(@scene.objects, @addObject.bind(@))

    addObject: (obj) ->
        console.log('Adding ' + obj)
        @scheduler.add(obj, true)

        @scene.addObject(obj)

    removeObject: (obj) ->
        @scheduler.remove(obj)

        @scene.removeObject(obj)



(new Game())
