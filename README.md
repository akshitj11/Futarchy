# Futarchy DAO Simulator

A Julia CLI simulator for futarchy governance, where DAO proposals are decided by comparing conditional prediction markets. The project follows the futarchy principle of voting on values and betting on beliefs: the branch with the better predicted metric wins.

## Features

- LMSR market mechanism with numerically stable pure math.
- YES and NO conditional markets for each proposal.
- Rational noisy agents with Gaussian signal noise and bias.
- DAO proposal lifecycle, treasury state, governance log, and market resolution.
- Watch mode for automatic simulation.
- Interactive play mode for player bets and player proposals.
- Term.jl terminal display with panels, tables, progress styling, ANSI redraws, and colored market bars.

## Project structure

| File | Role |
| --- | --- |
| `main.jl` | CLI entry point. Parses `watch` and `play` modes with ArgParse.jl, creates the simulator, and routes user actions. |
| `lmsr.jl` | Pure LMSR math module. Implements stable `logsumexp`, cost, prices, trade costs, share movement, budget sizing, and inline unit tests. |
| `market.jl` | Conditional market state. Wraps LMSR quantities, current prices, buys, resolution, payouts, and metric predictions. |
| `proposal.jl` | Proposal model. Holds a proposal description, metric, deadline, YES market, NO market, status, and branch winner logic. |
| `agent.jl` | Agent behavior. Implements rational noisy agents, private beliefs, edge detection, budget-based betting, player bets, and payout settlement. |
| `dao.jl` | DAO governance state. Tracks treasury, proposals, step counter, governance log, proposal creation, expiry checks, enactment, and settlement. |
| `simulator.jl` | Time-step engine. Advances agents, DAO governance, proposal seeding, automatic proposal creation, and watch-mode loops. |
| `display.jl` | Terminal UI. Uses Term.jl `Panel`, `Table`, `ProgressBar`, `tprint`, and `@style` with full-screen ANSI redraws and colored market output. |
| `Project.toml` | Julia metadata and dependencies for ArgParse.jl, Term.jl, and Test. |

## Run

Install dependencies from the repository root:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Run watch mode:

```bash
julia --project=. main.jl watch --steps 50 --agents 8 --delay 0.5
```

Run interactive mode:

```bash
julia --project=. main.jl play --agents 5
```

Run a stress-style watch simulation:

```bash
julia --project=. main.jl watch --steps 100 --agents 20 --delay 0.1
```

Run LMSR inline tests:

```bash
julia --project=. lmsr.jl
```

## Interactive controls

During play mode, the prompt appears after each rendered step:

| Key | Action |
| --- | --- |
| `b` | Place a player bet on the active proposal. |
| `s` | Skip to the next simulation step. |
| `p` | Create a new proposal. |
| `q` | Quit interactive mode. |

## Implementation notes

The simulator uses two-outcome LMSR markets where outcome `1` represents the positive metric outcome and outcome `2` represents the negative metric outcome. Each proposal owns two conditional markets: one for the world where the proposal is enacted and one for the world where it is rejected. When the deadline expires, the DAO compares predicted metric values from the YES and NO markets and enacts the better branch.

Agents estimate private beliefs from a true signal plus Gaussian noise and bias. They compare belief against current market price, compute edge, and bet when the edge passes a threshold. Bet size is proportional to edge and capped by balance.

The display layer receives simulator or DAO data as arguments and does not rely on mutable global state. It redraws the terminal each step using ANSI clear codes and Term.jl renderables.

## Commit history summary

The implementation was committed one module at a time:

1. `Project.toml` for Julia package metadata.
2. `lmsr.jl` for stable LMSR math and inline tests.
3. `market.jl` for conditional market state.
4. `proposal.jl` for twin-market proposal logic.
5. `agent.jl` for noisy rational agents and player bets.
6. `dao.jl` for governance state and resolution.
7. `simulator.jl` for the time-step engine.
8. `display.jl` for Term.jl terminal UI.
9. `main.jl` for CLI watch and play modes.
10. `README.md` for usage and implementation roles.
