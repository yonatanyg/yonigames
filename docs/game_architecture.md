# Game Architecture

YoniGames treats each game as a catalog entry plus optional reusable runtime behavior.

## Add a New Game

1. Add an id to `GameIds`.
2. Add a `GameDefinition` to `GameCatalog.all`.
3. Pick an existing `GameRoleStrategy` when possible.
4. Declare lobby role choices with `GamePlayerRole` when the game needs teams, jobs, or sides.
5. Declare the game's settings with `GameSettingDefinition`.
6. Add a tile image under `assets/game_tiles/`.
7. Only add service or screen code if the game needs a new role strategy, setting type, word source, or round UI pattern.

## Core Pieces

- `GameDefinition`: static game metadata, labels, image, player count, scoring, deck, timer, player roles, and role strategy.
- `GamePlayerRole`: declarative lobby role/team choices, including minimum players and optional capacity. The room stores only `players.{playerId}.roleId`.
- `GameSettingDefinition`: declarative lobby settings, such as deck, category, or timer.
- `GameRoom`: normalized room state read from Firestore.
- `GameSession`: normalized in-round state.
- `GameSessionFactory`: starts rounds and chooses focus players from reusable game rules.
- `RoomService`: Firebase persistence and room actions.
- `LobbyScreen`: room settings and compact game selector.
- `GameDashboardScreen`: visual game picker before room creation.

## Current Setting Types

- `deck`: chooses a reusable word deck and supports manual words.
- `category`: chooses a category-backed word list.
- `timer`: chooses a round duration.

## Current Player Roles

- Build a Question: at least one `Hinter` and exactly one `Guesser`. Round focus prefers players who chose `Guesser`.
- Out of the Loop: at least three `Player` seats because the hidden out-of-loop player is chosen by the round strategy.
- Password: at least one player on `Team 1` and one player on `Team 2`.

When a player joins, `RoomService` places them into the first role that helps satisfy the selected game's start requirements. The host can also randomize role assignments in the lobby.

## Out of the Loop Flow

Out of the Loop uses the shared `GameSession` plus phase fields:

- `wordReveal`: everyone except the out-of-loop player sees the secret word.
- `question`: each player receives one category-backed question in random order. The host advances after each real-life answer.
- `discussion`: players discuss who sounded suspicious.
- `vote`: each player votes for another player.
- `revealOutOfLoop`: the app reveals who was out of the loop and shows vote totals.
- `guess`: the out-of-loop player picks from category words.
- `finalReveal`: the app shows whether the guess matched the real word.
