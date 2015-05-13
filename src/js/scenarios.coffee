{Scene} = require('scene')
_ = require('lodash')
{Player, PlayerController, Monster, MonsterController} = require('creatures')

newPlayer = (game) ->
    player = new Player(game, [0, 0])
    game.player = player
    new PlayerController(game.player)

    return player

newGame = (game) ->
    player = newPlayer(game)
    scene = newDungeonFloor(game)
    movePlayerToScene(scene, player)

    return scene

movePlayerToScene = (scene, player) ->
    startPos = scene.randomSpawnLocation()
    player.x = startPos[0]
    player.y = startPos[1]
    scene.addObject(player)

    scene.updateVisibilityFov(player)

newDungeonFloor = (game) ->
    scene = new Scene(game)
    scene.generateMap()
    scene.drawWholeMap()

    monster = new Monster(game, scene.randomSpawnLocation())
    new MonsterController(monster)
    scene.addObject(monster)

    return scene

module.exports = {
    newGame
}
