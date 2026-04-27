module Agents

using Random
using ..Markets: Market, buy_for_budget!, current_price, payout_value
using ..Proposals: Proposal, is_active, branch_market

export Agent, Position, create_agent, decide!, player_bet!, receive_payout!, portfolio_value, private_belief, last_bet_label

mutable struct Position
    proposal_id::String
    branch::Symbol
    outcome::Int
    shares::Float64
end

mutable struct Agent
    name::String
    balance::Float64
    bias::Float64
    noise_std::Float64
    portfolio::Dict{String, Vector{Position}}
    last_bet::String
    last_edge::Float64
end

function create_agent(name::AbstractString, balance::Real=100.0; bias::Real=1.0, noise_std::Real=0.08)::Agent
    starting_balance = Float64(balance)
    starting_balance >= 0.0 || throw(ArgumentError("balance must be nonnegative"))
    return Agent(String(name), starting_balance, Float64(bias), Float64(noise_std), Dict{String, Vector{Position}}(), "none", 0.0)
end

function private_belief(true_value::Real, noise_std::Real, bias::Real)::Float64
    raw = Float64(true_value) + randn() * Float64(noise_std) * Float64(bias)
    return clamp(raw, 0.01, 0.99)
end

function _store_position!(agent::Agent, position::Position)::Nothing
    if !haskey(agent.portfolio, position.proposal_id)
        agent.portfolio[position.proposal_id] = Position[]
    end
    push!(agent.portfolio[position.proposal_id], position)
    return nothing
end

function _trade!(agent::Agent, proposal::Proposal, branch::Symbol, outcome::Integer, edge::Real, budget::Real)::Bool
    spend = min(agent.balance, Float64(budget))
    spend <= 0.0 && return false
    market = branch_market(proposal, branch)
    cost, shares = buy_for_budget!(market, outcome, spend)
    cost <= 0.0 && return false
    agent.balance -= cost
    _store_position!(agent, Position(proposal.id, branch, Int(outcome), shares))
    agent.last_edge = Float64(edge)
    agent.last_bet = "$(uppercase(String(branch))) outcome $(outcome) $(round(shares; digits=2))"
    return true
end

function decide!(agent::Agent, proposal::Proposal, true_yes::Real, true_no::Real; threshold::Real=0.04, max_fraction::Real=0.2)::Bool
    is_active(proposal) || return false
    agent.balance <= 0.0 && return false
    yes_belief = private_belief(true_yes, agent.noise_std, agent.bias)
    no_belief = private_belief(true_no, agent.noise_std, agent.bias)
    yes_market = branch_market(proposal, :yes)
    no_market = branch_market(proposal, :no)
    yes_edge = yes_belief - current_price(yes_market, 1)
    no_edge = no_belief - current_price(no_market, 1)
    branch = abs(yes_edge) >= abs(no_edge) ? :yes : :no
    edge = branch == :yes ? yes_edge : no_edge
    abs(edge) <= Float64(threshold) && return false
    outcome = edge > 0.0 ? 1 : 2
    budget = agent.balance * min(Float64(max_fraction), abs(edge))
    return _trade!(agent, proposal, branch, outcome, edge, budget)
end

function player_bet!(agent::Agent, proposal::Proposal, branch::Symbol, outcome::Integer, budget::Real)::Bool
    is_active(proposal) || throw(ArgumentError("proposal is not active"))
    branch == :yes || branch == :no || throw(ArgumentError("branch must be :yes or :no"))
    outcome == 1 || outcome == 2 || throw(ArgumentError("outcome must be 1 or 2"))
    spend = Float64(budget)
    spend > 0.0 || throw(ArgumentError("budget must be positive"))
    spend <= agent.balance || throw(ArgumentError("budget exceeds balance"))
    market = branch_market(proposal, branch)
    before = current_price(market, outcome)
    cost, shares = buy_for_budget!(market, outcome, spend)
    agent.balance -= cost
    _store_position!(agent, Position(proposal.id, branch, Int(outcome), shares))
    agent.last_edge = outcome == 1 ? 1.0 - before : before
    agent.last_bet = "PLAYER $(uppercase(String(branch))) outcome $(outcome) $(round(shares; digits=2))"
    return true
end

function receive_payout!(agent::Agent, proposal::Proposal)::Float64
    positions = get(agent.portfolio, proposal.id, Position[])
    total = 0.0
    for position in positions
        market = branch_market(proposal, position.branch)
        total += payout_value(market, position.outcome, position.shares)
    end
    agent.balance += total
    delete!(agent.portfolio, proposal.id)
    return total
end

function portfolio_value(agent::Agent)::Float64
    total = 0.0
    for positions in values(agent.portfolio)
        for position in positions
            total += position.shares
        end
    end
    return total
end

function last_bet_label(agent::Agent)::String
    return agent.last_bet
end

end
