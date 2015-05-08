attack = (weapon, target, agressor) ->
    result = weapon.attack(target, agressor)

    if result?
        target.takeDamage(result)


class Sword
    attack: (target, agressor) ->
        return amount: 3

module.exports = {
    attack,
    Sword
}
