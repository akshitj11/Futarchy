module Proposals

using ..Markets: Market, create_market, predicted_metric_value, resolve!

export Proposal, create_proposal, is_active, is_expired, predicted_metric_values, winning_branch, resolve_proposal!, branch_market

mutable struct Proposal
    id::String
    description::String
    metric::Symbol
    deadline::Int
    market_yes::Market
    market_no::Market
    status::Symbol
end

function create_proposal(id::AbstractString, description::AbstractString, metric::Symbol, deadline::Integer; liquidity::Real=25.0)::Proposal
    deadline > 0 || throw(ArgumentError("deadline must be positive"))
    return Proposal(String(id), String(description), metric, Int(deadline), create_market(liquidity, 2), create_market(liquidity, 2), :active)
end

function is_active(proposal::Proposal)::Bool
    return proposal.status == :active
end

function is_expired(proposal::Proposal, step::Integer)::Bool
    return is_active(proposal) && Int(step) >= proposal.deadline
end

function predicted_metric_values(proposal::Proposal; base::Real=100.0, spread::Real=20.0)::Tuple{Float64, Float64}
    yes_value = predicted_metric_value(proposal.market_yes, base, spread)
    no_value = predicted_metric_value(proposal.market_no, base, spread)
    return (yes_value, no_value)
end

function winning_branch(proposal::Proposal; base::Real=100.0, spread::Real=20.0)::Symbol
    yes_value, no_value = predicted_metric_values(proposal; base=base, spread=spread)
    return yes_value >= no_value ? :yes : :no
end

function branch_market(proposal::Proposal, branch::Symbol)::Market
    branch == :yes && return proposal.market_yes
    branch == :no && return proposal.market_no
    throw(ArgumentError("branch must be :yes or :no"))
end

function resolve_proposal!(proposal::Proposal, branch::Symbol)::Proposal
    is_active(proposal) || return proposal
    branch == :yes || branch == :no || throw(ArgumentError("branch must be :yes or :no"))
    resolve!(proposal.market_yes, branch == :yes ? 1 : 2)
    resolve!(proposal.market_no, branch == :no ? 1 : 2)
    proposal.status = :enacted
    return proposal
end

end
