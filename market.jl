module Markets

using ..LMSR: prices, price, trade_cost, buy_cost, quantity_after_buy, shares_for_budget

export Market, create_market, current_prices, current_price, buy!, buy_for_budget!, resolve!, payout_value, predicted_metric_value, is_resolved, market_trade_cost

mutable struct Market
    q::Vector{Float64}
    b::Float64
    resolved::Bool
    outcome::Union{Int, Nothing}
end

function create_market(b::Real=25.0, outcomes::Integer=2)::Market
    outcomes >= 2 || throw(ArgumentError("outcomes must be at least two"))
    liquidity = Float64(b)
    isfinite(liquidity) || throw(ArgumentError("liquidity must be finite"))
    liquidity > 0.0 || throw(ArgumentError("liquidity must be positive"))
    return Market(zeros(Float64, outcomes), liquidity, false, nothing)
end

function is_resolved(market::Market)::Bool
    return market.resolved
end

function current_prices(market::Market)::Vector{Float64}
    return prices(market.q, market.b)
end

function current_price(market::Market, outcome::Integer)::Float64
    return price(market.q, market.b, outcome)
end

function buy!(market::Market, outcome::Integer, shares::Real)::Tuple{Float64, Float64}
    market.resolved && throw(ArgumentError("cannot trade a resolved market"))
    quantity = Float64(shares)
    quantity >= 0.0 || throw(ArgumentError("shares must be nonnegative"))
    cost = buy_cost(market.q, market.b, outcome, quantity)
    market.q = quantity_after_buy(market.q, outcome, quantity)
    return (cost, quantity)
end

function buy_for_budget!(market::Market, outcome::Integer, budget::Real)::Tuple{Float64, Float64}
    market.resolved && throw(ArgumentError("cannot trade a resolved market"))
    spend = Float64(budget)
    spend >= 0.0 || throw(ArgumentError("budget must be nonnegative"))
    shares = shares_for_budget(market.q, market.b, outcome, spend)
    cost, quantity = buy!(market, outcome, shares)
    return (cost, quantity)
end

function resolve!(market::Market, outcome::Integer)::Market
    market.resolved && return market
    1 <= outcome <= length(market.q) || throw(ArgumentError("outcome index is out of bounds"))
    market.resolved = true
    market.outcome = Int(outcome)
    return market
end

function payout_value(market::Market, outcome::Integer, shares::Real)::Float64
    market.resolved || return 0.0
    quantity = Float64(shares)
    quantity >= 0.0 || throw(ArgumentError("shares must be nonnegative"))
    market.outcome === nothing && return 0.0
    return market.outcome == outcome ? quantity : 0.0
end

function predicted_metric_value(market::Market, base::Real=100.0, spread::Real=20.0)::Float64
    probability = current_price(market, 1)
    return Float64(base) + Float64(spread) * (probability - 0.5)
end

function market_trade_cost(market::Market, q_new::AbstractVector{<:Real})::Float64
    return trade_cost(market.q, q_new, market.b)
end

end
