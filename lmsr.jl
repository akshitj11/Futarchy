module LMSR

using Test

export logsumexp, cost, prices, price, trade_cost, quantity_after_buy, buy_cost, shares_for_budget, run_lmsr_tests

function _require_nonempty(values::AbstractVector{<:Real})::Nothing
    isempty(values) && throw(ArgumentError("values must not be empty"))
    all(isfinite, values) || throw(ArgumentError("values must be finite"))
    return nothing
end

function _require_positive_liquidity(b::Real)::Nothing
    liquidity = Float64(b)
    isfinite(liquidity) || throw(ArgumentError("liquidity must be finite"))
    liquidity > 0.0 || throw(ArgumentError("liquidity must be positive"))
    return nothing
end

function _require_same_length(q::AbstractVector{<:Real}, q_new::AbstractVector{<:Real})::Nothing
    length(q) == length(q_new) || throw(ArgumentError("quantity vectors must have the same length"))
    return nothing
end

function _require_outcome(q::AbstractVector{<:Real}, outcome::Integer)::Nothing
    1 <= outcome <= length(q) || throw(ArgumentError("outcome index is out of bounds"))
    return nothing
end

function _require_nonnegative(value::Real, name::String)::Nothing
    amount = Float64(value)
    isfinite(amount) || throw(ArgumentError("$name must be finite"))
    amount >= 0.0 || throw(ArgumentError("$name must be nonnegative"))
    return nothing
end

function _as_float_vector(values::AbstractVector{<:Real})::Vector{Float64}
    _require_nonempty(values)
    return Float64.(values)
end

function logsumexp(values::AbstractVector{<:Real})::Float64
    converted = _as_float_vector(values)
    offset = maximum(converted)
    total = sum(exp(value - offset) for value in converted)
    return offset + log(total)
end

function cost(q::AbstractVector{<:Real}, b::Real)::Float64
    _require_positive_liquidity(b)
    quantities = _as_float_vector(q)
    liquidity = Float64(b)
    scaled = quantities ./ liquidity
    return liquidity * logsumexp(scaled)
end

function prices(q::AbstractVector{<:Real}, b::Real)::Vector{Float64}
    _require_positive_liquidity(b)
    quantities = _as_float_vector(q)
    liquidity = Float64(b)
    scaled = quantities ./ liquidity
    offset = maximum(scaled)
    weights = exp.(scaled .- offset)
    denominator = sum(weights)
    return weights ./ denominator
end

function price(q::AbstractVector{<:Real}, b::Real, outcome::Integer)::Float64
    _require_outcome(q, outcome)
    return prices(q, b)[outcome]
end

function trade_cost(q::AbstractVector{<:Real}, q_new::AbstractVector{<:Real}, b::Real)::Float64
    _require_same_length(q, q_new)
    return cost(q_new, b) - cost(q, b)
end

function quantity_after_buy(q::AbstractVector{<:Real}, outcome::Integer, shares::Real)::Vector{Float64}
    _require_outcome(q, outcome)
    _require_nonnegative(shares, "shares")
    q_new = _as_float_vector(q)
    q_new[outcome] += Float64(shares)
    return q_new
end

function buy_cost(q::AbstractVector{<:Real}, b::Real, outcome::Integer, shares::Real)::Float64
    q_new = quantity_after_buy(q, outcome, shares)
    return trade_cost(q, q_new, b)
end

function shares_for_budget(q::AbstractVector{<:Real}, b::Real, outcome::Integer, budget::Real; tolerance::Real=1.0e-9, max_iterations::Integer=100)::Float64
    _require_outcome(q, outcome)
    _require_positive_liquidity(b)
    _require_nonnegative(budget, "budget")
    _require_nonnegative(tolerance, "tolerance")
    max_iterations > 0 || throw(ArgumentError("max_iterations must be positive"))
    target = Float64(budget)
    target == 0.0 && return 0.0
    lower = 0.0
    upper = max(1.0, target)
    expansions = 0
    while buy_cost(q, b, outcome, upper) < target && expansions < max_iterations
        upper *= 2.0
        expansions += 1
    end
    buy_cost(q, b, outcome, upper) >= target || throw(ArgumentError("budget search failed to bracket a solution"))
    allowed_error = Float64(tolerance)
    for _ in 1:max_iterations
        midpoint = (lower + upper) / 2.0
        midpoint_cost = buy_cost(q, b, outcome, midpoint)
        abs(midpoint_cost - target) <= allowed_error && return midpoint
        if midpoint_cost < target
            lower = midpoint
        else
            upper = midpoint
        end
    end
    return (lower + upper) / 2.0
end

function run_lmsr_tests()::Bool
    @testset "lmsr" begin
        @test isapprox(logsumexp([0.0, 0.0]), log(2.0); atol=1.0e-12)
        @test isapprox(cost([0.0, 0.0], 1.0), log(2.0); atol=1.0e-12)
        @test isapprox(sum(prices([1.0, -1.0], 2.0)), 1.0; atol=1.0e-12)
        @test price([0.0, 0.0], 10.0, 1) == 0.5
        @test price([0.0, 0.0], 10.0, 2) == 0.5
        @test buy_cost([0.0, 0.0], 5.0, 1, 2.0) > 0.0
        @test isapprox(trade_cost([0.0, 0.0], [2.0, 0.0], 5.0), buy_cost([0.0, 0.0], 5.0, 1, 2.0); atol=1.0e-12)
        @test all(isfinite, prices([1000.0, 1001.0], 10.0))
        @test all(isfinite, prices([-1000.0, -1001.0], 10.0))
        shares = shares_for_budget([0.0, 0.0], 10.0, 1, 3.0)
        @test shares > 0.0
        @test buy_cost([0.0, 0.0], 10.0, 1, shares) <= 3.0 + 1.0e-7
        @test_throws ArgumentError cost([], 1.0)
        @test_throws ArgumentError cost([0.0, 0.0], 0.0)
        @test_throws ArgumentError price([0.0, 0.0], 1.0, 3)
        @test_throws ArgumentError buy_cost([0.0, 0.0], 1.0, 1, -1.0)
    end
    return true
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_lmsr_tests()
end

end
