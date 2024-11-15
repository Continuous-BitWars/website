# Hackathon - BitWars

What you need:

* GitHub account. [Fork a player][clients] in your favorite language.
* Your team configuration (the `kubeconfig.yml` file) to get access to the Kubernetes cluster.
  Then set the token, team name, and namespace in your fork of a player in GitHub CI/CD.
  [See the quick introduction](./github-cicd.md).

If you haven't worked with Kubernetes yet, you can also take a look at [our brief introduction to `kubectl`](./kubernetes.md).
For example, you can use `kubectl` to follow the logs of your player on the cluster.

## Links

* [Register your team here](https://forms.gle/2yLmxuVg737zdxnX7)
* [GitHub BitWars Players][clients] (fork these)
* [Scoreboard](https://live.bitwars.online/)
* [Grafana](https://grafana.bitwars.online/) Credentials: `player:player`
* [Hackathon Event Page](https://events.fachschaft-it.de/Hackathon/)
* BitWars is inspired by [Continuous Poker](https://continuouspoker.org/)

## Overview - How To Play

BitWars is a round-based game.
Every round the game server sends an HTTP POST request containing the current game state to your player.
The response of your player is an array of actions, meaning the next moves you want to play.

## Game Dynamics

### Player

The player is the client you write and deploy to the Kubernetes cluster via GitHub.
You [choose and fork a player][clients] and implement your strategy there.

### Bits

Every round all bases you own produce a number of Bits according to the level of the base.
It's your task in the player to come up with a strategy on how to distribute these Bits, either attacking other bases to conquer them or sending them to your own bases to upgrade them.
Or you might want to keep them in the base to defend it against incoming attacks.

### Bases on the Map

In every game there is a fixed number of bases.
The goal of each game is to conquer all bases.
When all bases belong to you, you won!
The bases are spread over a map, so every base has an `x`, `y`, and `z` coordinate.
Therefore, there is a distance that your [Bits need to travel](#traveling-bits) between bases.
Depending on the map, your player starts out with one or more bases.
If you lose all bases to other players, you lost.

The bases are transferred in the game state and look like the following JSON snippet.

```json
  "bases": [
    {
      "uid": 1,
      "name": "Berlin",
      "player": 1001,
      "population": 2,
      "level": 0,
      "units_until_upgrade": 0,
      "position": {
        "x": 0,
        "y": 0,
        "z": 0
      }
    },
    {
      "uid": 2,
      "name": "Tokio",
      "player": 0,
      "population": 7,
      "level": 1,
      "units_until_upgrade": 0,
      "position": {
        "x": 3,
        "y": -3,
        "z": 0
      }
    },
    ...
  ]
}
```


### Base Levels and Upgrading

When you send Bits to your own base, these Bits will disappear in exchange for level points of the base.
This is how you upgrade your base. A higher level means

1. more Bits will spawn per round in your base
2. the base has a higher capacity of Bits

The game state contains all available base levels in the `base_levels` array.
Currently, there are 14 levels with the following details:

Level | Max. Population | Upgrade Cost  | Spawn Rate
----: | --------------: | ------------: | ---------:
1     | 20              | 10            | 1
2     | 40              | 20            | 2
3     | 80              | 30            | 3
4     | 100             | 40            | 4
5     | 200             | 50            | 5
6     | 300             | 100           | 6
7     | 400             | 200           | 7
8     | 500             | 400           | 8
9     | 600             | 600           | 9
10    | 700             | 800           | 10
11    | 800             | 1000          | 15
12    | 900             | 1500          | 20
13    | 1000            | 2000          | 25
14    | 2000            | 3000          | 50

In the first level, the maximum population of Bits is 20 and every round a single Bit is spawned.
If you want to upgrade to level 2, you need to send 10 Bits to that base.

**Example:**

If your base `A` is in level 1 and you send 80 Bits to it from base `A` (`src == dest` means you want to upgrade your base),
then base `A` will upgrade to level 4 (10 + 20 + 30 = 60 Bits) and the remaining 20 Bits are added to the population of that base.

A quick `JSON` snippet:

```json
    "base_levels": [
      {
        "max_population": 20,
        "upgrade_cost": 10,
        "spawn_rate": 1
      },
      {
        "max_population": 40,
        "upgrade_cost": 20,
        "spawn_rate": 2
      },
      {
        "max_population": 80,
        "upgrade_cost": 30,
        "spawn_rate": 3
      },
      {
        "max_population": 100,
        "upgrade_cost": 40,
        "spawn_rate": 4
      },
      ...
    ]
```

Note: If the number of Bits in your base reaches the maximum capacity (`max_population`), then the `spawn_rate` will turn into a death rate.
For example, assuming the spawn rate is 5, then instead of 5 new Bits being spawned every round, 5 Bits will be killed every round as long as you are above the maximum population.

### Traveling Bits

#### Travel Time

The travel time is calculated by using the [Euclidean distance][eucl] in a three dimensional space.
The result is rounded down as it is easier to work with natural numbers.
If `src` and `dest` is the same base, the travel time is zero (Bits arrive in the same round).

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

When deciding where you want to send your Bits, you might want to calculate the distance yourself.
However, you don't have to do that for actions by other players.
The server does this for you, so you can check the `dest` field to know whether one of your bases is going to be attacked
and read the `progress` values to find out when the Bits arrive.

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

When `progress.traveled` equals 1, then this action was just submitted and the Bits traveled 1 step (Bits travel 1 step per round).
You also know that the fight will take place in 2 rounds and you have two opportunities to submit actions (the current round and when `progress.traveled=2`).
You will not receive a game state in that `progress.distance` equals `progress.traveled`, because this is the round in which the fight takes place, so you can just check your updated base information.

#### Travel Costs

Your Bits can only travel for a defined distance before they lose their electric charge!
The following `JSON` snippet in the game state shows that Bits can travel for 10 rounds _without taking damage_.
If you send your Bits to a base that is further away than 10 steps, one Bit will die every additional round.

```json
{
...
    "paths": {
      "grace_period": 10,
      "death_rate": 1
    }
}
```



## Player Actions

Every round the server requests an array of actions from your player.
An action defines how many Bits (`amount`) you want to send from the base identified by `src` to the base identified by `dest`.
The following action means that we send 5 Bits from base 1 to base 2.

```json
{
  "src": 1,
  "dest": 2,
  "amount": 5,
}
```

This action is interpreted in one of the following ways by the server:

1. **Base upgrade:** Both bases (`src` and `dest`) belong to you and are the same.
  Then the Bits you send are used to [upgrade your base].
2. **Movement of Bits:** If `src` and `dest` belong to you but are different, then you transfer Bits between your bases.
3. **Attacking another base:** The `dest` base is an enemy base and you can try to conquer it.
  When your Bits reach the destination base (they might need a couple of rounds [depending on the distance](#traveling-bits), a fight will take place (a simple subtraction).

    ```
    (Bits in the destination base) - (your arrived Bits)
    ```

    If you manage to defeat all enemy Bits (meaning at least one of your Bits survive), you successfully conquered the base.
    If you defeat all Bits in the base but no Bits of your own survived (meaning the result of the above equation is zero), the base still belongs to the previous player.

If you decide to submit no actions, you can simply reply with an empty array.
The server also assumes an empty array if your player takes too long to respond (timeout is about one second).
All actions you send are executed in the same round while the execution order is not defined.


<!--
## Example Actions

### Attacking Another Player

### Upgrade Your Own Base

### Move Bits Between Your Bases
-->



<!-- parking lot of links -->
[eucl]: https://en.wikipedia.org/wiki/Euclidean_distance#Higher_dimensions
[clients]: https://github.com/Continuous-BitWars/
[upgrade your base]: #base-levels-and-upgrading

