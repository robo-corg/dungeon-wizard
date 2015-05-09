Q = require('q')
Events = require('events').EventEmitter
# Events = require('minivents')
ROT = require('rot-js')
_ = require('lodash')

{attack, Sword} = require('combat')

randomItem = (arr) ->
    return arr[Math.floor(ROT.RNG.getUniform() * arr.length)]

randomDir = () ->
    return randomItem(ROT.DIRS[8])

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

    passable: (tile) ->
        return tile? && tile == '.'

    canMove: (dir) ->
        return dir != null && @passable(@game.scene.map.get(@x + dir[0], @y + dir[1]))

    isEnemy: (other) ->
        return other != @

    firstEnemyInDir: (dir) ->
        x = @x + dir[0]
        y = @y + dir[1]

        return _.find(
            @game.scene.map.objects.get(x, y),
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
        try
            @events.emit('before-act')

            return @action.promise.then(
                (action) => action()
            ).then(() =>
                @action = Q.defer()
            ).catch((err) =>
                console.log("Error in action: " + err + "\n" + err.stack)
                @action = Q.defer()
            )
        catch error
            console.log("Error: in act: " + error)

class Player extends Creature
    weapon: new Sword()

    draw: (display) ->
        display.draw(@x,  @y, "@", "#ff0")

    postMove: (oldPos) ->
        @game.scene.updateVisibilityFov(@)


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

module.exports = {
    Creature,
    Player,
    Monster,
    MonsterController,
    PlayerController
}
