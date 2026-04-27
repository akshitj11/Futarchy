module Simulators

using Random
using ..Agents: Agent, create_agent, decide!, player_bet!
using ..DAOs: DAO, create_dao, add_proposal!, active_proposals, step_dao!
using ..Proposals: Proposal

export Simulator, create_simulator, seed_default_proposals!, step_simulator!, run_watch!, active_proposal, player_bet!, random_agent_name

mutable struct Simulator
    dao::DAO
    agents::Vector{Agent}
    true_yes::Float64
    true_no::Float64
    running::Bool
end

function random_agent_name(index::Integer)::String
    names = ["Ada", "Byron", "Curie", "Dijkstra", "Elinor", "Feynman", "Grace", "Hayek", "Iris", "Jevons", "Klein", "Lovelace", "Minsky", "Nash", "Ostrom", "Pareto", "Quinn", "Romer", "Schelling", "Turing"]
    return "$(names[mod1(Int(index), length(names))])-$(index)"
end

function _create_agents(count::Integer)::Vector{Agent}
    count > 0 || throw(ArgumentError("agent count must be positive"))
    agents = Agent[]
    for index in 1:Int(count)
        bias = clamp(1.0 + randn() * 0.18, 0.55, 1.45)
        noise = clamp(0.06 + rand() * 0.1, 0.03, 0.22)
        push!(agents, create_agent(random_agent_name(index), 100.0; bias=bias, noise_std=noise))
    end
    return agents
end

function create_simulator(agent_count::Integer=8; treasury::Real=10000.0, true_yes::Real=0.62, true_no::Real=0.48)::Simulator
    dao = create_dao(treasury)
    agents = _create_agents(agent_count)
    simulator = Simulator(dao, agents, Float64(true_yes), Float64(true_no), true)
    seed_default_proposals!(simulator)
    return simulator
end

function seed_default_proposals!(simulator::Simulator)::Vector{Proposal}
    if isempty(simulator.dao.proposals)
        add_proposal!(simulator.dao, "fund protocol growth campaign", :revenue, 12; liquidity=35.0)
        add_proposal!(simulator.dao, "launch builder grant program", :user_count, 18; liquidity=30.0)
    end
    return simulator.dao.proposals
end

function active_proposal(simulator::Simulator)::Union{Proposal, Nothing}
    proposals = active_proposals(simulator.dao)
    isempty(proposals) && return nothing
    return proposals[1]
end

function _agent_round!(simulator::Simulator)::Int
    trades = 0
    for proposal in active_proposals(simulator.dao)
        for agent in simulator.agents
            traded = decide!(agent, proposal, simulator.true_yes, simulator.true_no)
            trades += traded ? 1 : 0
        end
    end
    return trades
end

function step_simulator!(simulator::Simulator)::Int
    simulator.running || return 0
    trades = _agent_round!(simulator)
    step_dao!(simulator.dao, simulator.agents)
    if isempty(active_proposals(simulator.dao))
        add_proposal!(simulator.dao, "rebalance treasury strategy", :token_price, 10; liquidity=30.0)
    end
    return trades
end

function run_watch!(simulator::Simulator, steps::Integer, delay::Real, render::Function)::Simulator
    steps >= 0 || throw(ArgumentError("steps must be nonnegative"))
    wait = Float64(delay)
    wait >= 0.0 || throw(ArgumentError("delay must be nonnegative"))
    for _ in 1:Int(steps)
        step_simulator!(simulator)
        render(simulator)
        sleep(wait)
    end
    return simulator
end

end
