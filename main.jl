include("lmsr.jl")
include("market.jl")
include("proposal.jl")
include("agent.jl")
include("dao.jl")
include("simulator.jl")
include("display.jl")

using ArgParse
using .Agents: player_bet!
using .DAOs: add_proposal!
using .Displays: render!, prompt_action
using .Simulators: create_simulator, step_simulator!, run_watch!, active_proposal

function parse_cli(args::Vector{String})::Dict{String, Any}
    settings = ArgParseSettings(description="Futarchy DAO Simulator")
    @add_arg_table! settings begin
        "mode"
            help = "watch or play"
            arg_type = String
            required = true
        "--steps"
            help = "number of watch steps"
            arg_type = Int
            default = 50
        "--agents"
            help = "number of agents"
            arg_type = Int
            default = 8
        "--delay"
            help = "watch mode delay in seconds"
            arg_type = Float64
            default = 0.5
    end
    parsed = parse_args(args, settings)
    mode = lowercase(parsed["mode"])
    mode == "watch" || mode == "play" || throw(ArgumentError("mode must be watch or play"))
    return parsed
end

function read_float(prompt::AbstractString)::Float64
    print(prompt)
    value = strip(readline(stdin))
    return parse(Float64, value)
end

function read_symbol(prompt::AbstractString)::Symbol
    print(prompt)
    value = lowercase(strip(readline(stdin)))
    return Symbol(value)
end

function handle_bet!(simulator)::Nothing
    proposal = active_proposal(simulator)
    proposal === nothing && return nothing
    branch = read_symbol("branch yes/no: ")
    outcome = Int(read_float("outcome 1/2: "))
    budget = read_float("budget: ")
    player_bet!(simulator.agents[1], proposal, branch, outcome, budget)
    return nothing
end

function handle_propose!(simulator)::Nothing
    print("description: ")
    description = strip(readline(stdin))
    metric = read_symbol("metric token_price/revenue/user_count: ")
    duration = Int(read_float("duration steps: "))
    add_proposal!(simulator.dao, description, metric, duration; liquidity=30.0)
    return nothing
end

function run_play!(simulator)::Nothing
    simulator.agents[1].name = "Player"
    while simulator.running
        step_simulator!(simulator)
        render!(simulator)
        action = prompt_action()
        if action == "q" || action == "quit"
            simulator.running = false
        elseif action == "b" || action == "bet"
            handle_bet!(simulator)
        elseif action == "p" || action == "propose"
            handle_propose!(simulator)
        end
    end
    return nothing
end

function main(args::Vector{String}=ARGS)::Nothing
    parsed = parse_cli(args)
    simulator = create_simulator(parsed["agents"])
    if lowercase(parsed["mode"]) == "watch"
        run_watch!(simulator, parsed["steps"], parsed["delay"], render!)
    else
        run_play!(simulator)
    end
    return nothing
end

main()
