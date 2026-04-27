# Futarchy DAO Simulator

A Julia CLI simulator for futarchy governance, where a DAO chooses policies by comparing conditional prediction markets. Participants vote on the metric they care about and bet on which proposal branch predicts the best outcome.

## Current status

The project is being built one module at a time. The first implemented module is `lmsr.jl`, which contains pure, numerically stable LMSR math and inline unit tests.

## Planned structure

| File | Role |
| --- | --- |
| `main.jl` | CLI entry point for watch mode and interactive play mode. |
| `lmsr.jl` | Pure LMSR math functions for cost, prices, trade costs, buy costs, share quantities, and inline tests. |
| `market.jl` | Conditional market state around LMSR quantities, liquidity, resolution, and payouts. |
| `proposal.jl` | Proposal model with paired YES and NO markets for conditional outcome comparisons. |
| `agent.jl` | Rational and noisy agent behavior using private beliefs, edge thresholds, and balance-aware sizing. |
| `dao.jl` | DAO state, treasury, proposal lifecycle, governance log, and enactment logic. |
| `simulator.jl` | Time-step engine that advances agents, proposals, markets, and DAO governance. |
| `display.jl` | First-class terminal UI layer using Term.jl panels, tables, progress bars, colors, and prompts. |
| `Project.toml` | Julia package metadata and dependencies for ArgParse.jl, Term.jl, and tests. |

## Implemented `lmsr.jl` behavior

`lmsr.jl` exports a `LMSR` module with pure functions and no mutable global state.

| Function | Role |
| --- | --- |
| `logsumexp(values)` | Stable log-sum-exp helper used to avoid overflow and underflow in LMSR cost math. |
| `cost(q, b)` | LMSR cost function `b * log(sum(exp.(q ./ b)))` implemented through the stable helper. |
| `prices(q, b)` | Returns the full probability vector for all outcomes as a stable softmax over quantities. |
| `price(q, b, outcome)` | Returns the current probability for a single one-indexed outcome. |
| `trade_cost(q, q_new, b)` | Computes the cost difference between two quantity vectors. |
| `quantity_after_buy(q, outcome, shares)` | Returns a new quantity vector after buying shares of one outcome. |
| `buy_cost(q, b, outcome, shares)` | Computes how much a buy operation costs without mutating market state. |
| `shares_for_budget(q, b, outcome, budget)` | Uses bounded binary search to estimate the purchasable shares for a fixed spend. |
| `run_lmsr_tests()` | Runs inline tests for stability, pricing invariants, trade costs, and validation errors. |

## Running the inline LMSR tests

From the repository root:

```bash
julia lmsr.jl
```

Or from a Julia session:

```julia
include("lmsr.jl")
LMSR.run_lmsr_tests()
```

## Target CLI usage

```bash
julia main.jl watch --steps 50 --agents 8 --delay 0.5
julia main.jl play --agents 5
julia main.jl watch --steps 100 --agents 20 --delay 0.1
```

## Commit plan

The full simulator will be built through small, focused commits:

1. Add Julia project metadata.
2. Add stable LMSR math.
3. Document LMSR behavior and project roles.
4. Add market state and trade application.
5. Add proposal model with twin conditional markets.
6. Add agent belief and betting behavior.
7. Add DAO governance state and resolution logic.
8. Add simulator time-step engine.
9. Add Term.jl display panels and tables.
10. Add CLI argument parsing and watch mode.
11. Add interactive play mode.
12. Add final README usage examples and smoke-test notes.
