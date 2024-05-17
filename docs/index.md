# Hackathon - BitWars

What you need:

* GitHub account. [Fork a client][clients] in your favorite language.
* Your team configuration to get access to the Kubernetes cluster.
    * Set team name
    * Set secrets for CI/CD

## Links

* [GitHub BitWars Clients][clients] (fork these)
* [Scoreboard](https://live.bitwars.online/)
* [Grafana](https://grafana.bitwars.online/) Credentials: `player:player`
* [Hackathon Event Page](https://events.fachschaft-it.de/Hackathon/)
* BitWars is inspired by [Continuous Poker](https://continuouspoker.org/)

## Overview - How To Play

BitWars is a round-based game. Every round the game server sends a request with the current game state to your client to pull your array of actions, meaning the next moves you want to play.

## Elements in the Game

### Player

The player is the client you write and deploy via GitHub.

### Bits

All bases you own produce every round a number of Bits according to the level of the base. It's your task in the client to come up with a strategy on how to distribute these Bits, either attacking other bases to conquer them or sending them to your own bases to upgrade them. Or you might want to keep them in the base to defend it against incoming attacks.

### Bases

In every game there is a fixed number of bases. The goal of each game is to conquer all bases. When all bases belong to you, you won! The bases are spread over a map, so every base has an `x`, `y`, and `z` coordinate. Therefore, there is a distance that your Bits need to travel between bases. Your player starts out with at least one base. If you lose all bases to other players, you lost.

```json
{
  "bases": [
    {
      "uid": 1003, // unique ID of the base
      "player": 1001, // player ID to which the base belongs to
      "population": 10, // current Bits in the base
      "level": 0,
      "unitsUntilUpgrade": 0, // number of Bits required to reach the next level
      "position": {
        "x": 0,
        "y": 0,
        "z": 0
      }
    },
    {
      "uid": 1001,
      "player": 1001,
      "population": 21,
      "level": 0,
      "unitsUntilUpgrade": 0,
      "position": {
        "x": 0,
        "y": 0,
        "z": 0
      }
    },
    ...
  ]
}
```

Note: If one of your bases requires 10 Bits to reach the next level and you send 13 Bits to the base, then your base will reach the next level, but the additional 3 Bits will be lost. Always upgrade with the exact amount!


## Upgrade Your Base

When you send Bits to your own base, these Bits will disappear in exchange for level points of the base. This is how you upgrade your base. A higher level means

* more Bits will spawn per round in your base 
* the base has a higher capacity of Bits

The game state contains the available levels of bases. For example, the following JSON snippet shows the first three base levels in the game. The index of the described level corresponds to the level number, so we start out at level 0 with a maximum population (capacity of the base) of 20, an upgrade cost of 1000 (you have to send 1000 Bits to the base to upgrade to the next level) and a spawn rate of 1 (one Bit spawns in the base per round).

```json
{
"baseLevels": [
  {
    "maxPopulation": 20,
    "upgradeCost": 1000,
    "spawnRate": 1
  },
  {
    "maxPopulation": 40,
    "upgradeCost": 1000,
    "spawnRate": 2
  },
  {
    "maxPopulation": 80,
    "upgradeCost": 1000,
    "spawnRate": 3
  },
  ...
]
}
```

Note: If the number of Bits in your base reach the maximum capacity (`maxPopulation`), then the `spawnRate` will turn into a death rate. For example, assuming the spawn rate is 5, this means that instead of 5 new Bits every round, 5 Bits will be killed every round as long as you are above the maxiumum capacity.

## Actions

Every round the server requests an array of actions from your player. An action defines how many Bits (`amount`) you want to send from the base identified by `src` to the base identified by `dest`. The following action means that we send 5 Bits from base 1 to base 2.

```json
{
  "src": 1,
  "dest": 2,
  "amount": 5,
}
```

This action is interpreted in one of two ways by the server.

1. Both bases (`src` and `dest`) belong to you and are the same. Only then the Bits you sent are used to [upgrade your base].
2. If `src` and `dest` belong to you, you transfer Bits between your bases.
3. The `dest` base is an enemy base and you try to conquer it. When your Bits reach the base (they might need a couple of rounds depending on the distance), a fight will take place (a simple substraction).

    ```
    (Bits in the base) - (your arrived Bits)
    ```

    If you manage to defeat all enemy Bits (meaning at least one of your Bits survive), you successfully conquered the base. If you defeat all Bits in the base but with no survivors of your own (meaning the result of the above equation is zero), the base still belongs to the previous player.

If you decide to submit no actions, you can simply reply with an emtpy array. The servers also assumes an empty array if your client takes too long to respond (timeout is about one second). All actions you send are executed in the same tick while the execution order is not defined.


## Traveling Bits

### Travel Time

The travel time is calculated by the using the [Euclidean distance][eucl] in a three dimensional space. The result is rounded down as it is easier to work with natural numbers. If `src` and `dest` is the same base, the travel time is zero (Bits arrive in the same round).

More formally, with a base $A(x_1,y_1,z_1)$ and a base $B(x_2,y_2,z_2)$ the distance $d$ is defined as

$$ d= \lfloor \sqrt{(x_1-x_2)^2 + (y_1-y_2)^2 + (z_1-z_2)^2} \rfloor$$

Note the floor symbol that rounds down to the nearest integer (basically strip the part after the comma).

Assume we send 5 Bits from base 1 to base 2:

```json
{
  "src": 1,
  "dest": 2,
  "amount": 5,
}
```

When deciding where you want to send your Bits, you might want to calculate the distance yourself. However, you don't have to do that for actions by other players. The server does this for you, so you can check the `dest` field to know whether one of your bases is going to be attacked and read the `progress` values to find out when the Bits
arrive.

```json
{
  "uuid": "e79007bb-d938-49b0-8b28-4cf271f791ae", // unique ID of this action
  "player": 1001, // player ID that this action belongs to
  "src": 1, // from this base
  "dest": 2, // to this base
  "amount": 5, // with 5 Bits
  "progress": {
    "distance": 3, // total distance from src to dest
    "traveled": 1 // distance already traveled.
  }
}
```

When `progress.traveled` equals 1, then this action was just submitted and the Bits traveled 1 step (Bits travel 1 step per round). You also know that the fight will take place in 2 rounds and you have two opportunities to submit actions (the current round and when `progress.traveled=2`). You will not receive a game state in that `progress.distance` equals `progress.traveled`, because this is the round in which the fight takes place, so you can just check your updated base information.


### Travel Costs

Your Bits can only travel for a defined distance before they lose their electric charge! The following JSON snippet in the game state shows that Bits can travel for 10 rounds without _taking damage_. If you send your Bits to a base that is further away than 10 steps, one Bit will die every additional round.

```json
{
  "paths": {
    "gracePeriod": 10,
    "deathRate": 1
  }
}
```


<!-- parking lot of links -->
[eucl]: https://en.wikipedia.org/wiki/Euclidean_distance#Higher_dimensions
[clients]: https://github.com/Continuous-BitWars/
[upgrade your base]: #upgrade-your-base

