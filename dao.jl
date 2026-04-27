module DAOs

using ..Proposals: Proposal, create_proposal, is_active, is_expired, winning_branch, resolve_proposal!, predicted_metric_values
using ..Agents: Agent, receive_payout!

export DAO, create_dao, add_proposal!, active_proposals, step_dao!, resolve_expired!, next_proposal_id, latest_log

mutable struct DAO
    treasury::Float64
    proposals::Vector{Proposal}
    governance_log::Vector{String}
    step::Int
end

function create_dao(treasury::Real=10000.0)::DAO
    starting_treasury = Float64(treasury)
    starting_treasury >= 0.0 || throw(ArgumentError("treasury must be nonnegative"))
    return DAO(starting_treasury, Proposal[], String[], 0)
end

function next_proposal_id(dao::DAO)::String
    return "P$(length(dao.proposals) + 1)"
end

function add_proposal!(dao::DAO, description::AbstractString, metric::Symbol, duration::Integer; liquidity::Real=25.0)::Proposal
    duration > 0 || throw(ArgumentError("duration must be positive"))
    proposal = create_proposal(next_proposal_id(dao), description, metric, dao.step + Int(duration); liquidity=liquidity)
    push!(dao.proposals, proposal)
    push!(dao.governance_log, "step $(dao.step): proposed $(proposal.id) $(proposal.description)")
    return proposal
end

function active_proposals(dao::DAO)::Vector{Proposal}
    return [proposal for proposal in dao.proposals if is_active(proposal)]
end

function _settle_agents!(agents::Vector{Agent}, proposal::Proposal)::Float64
    total = 0.0
    for agent in agents
        total += receive_payout!(agent, proposal)
    end
    return total
end

function resolve_expired!(dao::DAO, agents::Vector{Agent}; base::Real=100.0, spread::Real=20.0)::Vector{Proposal}
    resolved = Proposal[]
    for proposal in dao.proposals
        if is_expired(proposal, dao.step)
            branch = winning_branch(proposal; base=base, spread=spread)
            yes_value, no_value = predicted_metric_values(proposal; base=base, spread=spread)
            resolve_proposal!(proposal, branch)
            payouts = _settle_agents!(agents, proposal)
            push!(dao.governance_log, "step $(dao.step): enacted $(proposal.id) $(uppercase(String(branch))) yes=$(round(yes_value; digits=2)) no=$(round(no_value; digits=2)) payouts=$(round(payouts; digits=2))")
            push!(resolved, proposal)
        end
    end
    return resolved
end

function step_dao!(dao::DAO, agents::Vector{Agent}; base::Real=100.0, spread::Real=20.0)::Vector{Proposal}
    dao.step += 1
    return resolve_expired!(dao, agents; base=base, spread=spread)
end

function latest_log(dao::DAO, count::Integer=5)::Vector{String}
    limit = max(0, Int(count))
    limit == 0 && return String[]
    start_index = max(1, length(dao.governance_log) - limit + 1)
    return dao.governance_log[start_index:end]
end

end
