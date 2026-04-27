module Displays

using Term
using Term: Panel, tprint, @style
using Term.Tables: Table
using Term.Progress: ProgressBar
using ..Agents: Agent, last_bet_label
using ..DAOs: DAO, latest_log, active_proposals
using ..Markets: current_price, predicted_metric_value
using ..Proposals: Proposal
using ..Simulators: Simulator

export clear_screen, render!, render_dao_panel, render_market_panel, render_agent_table, render_governance_log, prompt_action, price_bar, make_progress

function clear_screen()::Nothing
    print("\033[2J\033[H")
    flush(stdout)
    return nothing
end

function make_progress()::ProgressBar
    return ProgressBar()
end

function price_bar(value::Real; width::Integer=28, color::Symbol=:cyan)::String
    clamped = clamp(Float64(value), 0.0, 1.0)
    total = max(1, Int(width))
    filled = clamp(round(Int, clamped * total), 0, total)
    empty = total - filled
    label = lpad(string(round(clamped * 100.0; digits=1)), 5) * "%"
    color_name = color == :green ? "green" : color == :red ? "red" : color == :yellow ? "yellow" : "cyan"
    return "{$color_name}" * repeat("█", filled) * "{/$(color_name)}" * repeat("░", empty) * " " * label
end

function render_dao_panel(dao::DAO)::Panel
    active_count = length(active_proposals(dao))
    title = @style "DAO State" cyan bold
    body = "{cyan}step{/cyan}: $(dao.step)\n{cyan}treasury{/cyan}: $(round(dao.treasury; digits=2))\n{cyan}active proposals{/cyan}: $(active_count)\n{cyan}total proposals{/cyan}: $(length(dao.proposals))"
    return Panel(body; title=title, style="cyan", width=86)
end

function _proposal_market_body(proposal::Proposal)::String
    yes_price = current_price(proposal.market_yes, 1)
    no_price = current_price(proposal.market_no, 1)
    yes_metric = predicted_metric_value(proposal.market_yes)
    no_metric = predicted_metric_value(proposal.market_no)
    yes_label = @style "YES" green bold
    no_label = @style "NO" red bold
    return "$(yes_label) $(price_bar(yes_price; color=:green)) metric $(round(yes_metric; digits=2))\n$(no_label)  $(price_bar(no_price; color=:red)) metric $(round(no_metric; digits=2))\n{cyan}deadline{/cyan}: $(proposal.deadline)  {cyan}status{/cyan}: $(proposal.status)\n{cyan}metric{/cyan}: $(proposal.metric)  {cyan}description{/cyan}: $(proposal.description)"
end

function render_market_panel(proposals::Vector{Proposal})::Panel
    title = @style "Markets" cyan bold
    if isempty(proposals)
        return Panel("{yellow}no active proposals{/yellow}"; title=title, style="yellow", width=86)
    end
    sections = String[]
    for proposal in proposals
        push!(sections, "{cyan}$(proposal.id){/cyan}\n" * _proposal_market_body(proposal))
    end
    return Panel(join(sections, "\n\n"); title=title, style="cyan", width=86)
end

function render_agent_table(agents::Vector{Agent})::Table
    rows = Matrix{String}(undef, length(agents), 4)
    for index in eachindex(agents)
        agent = agents[index]
        rows[index, 1] = agent.name
        rows[index, 2] = string(round(agent.balance; digits=2))
        rows[index, 3] = last_bet_label(agent)
        rows[index, 4] = string(round(agent.last_edge; digits=4))
    end
    return Table(rows; header=["agent", "balance", "last bet", "edge"], style="cyan", header_style="bold cyan")
end

function render_governance_log(dao::DAO)::Panel
    title = @style "Governance Log" cyan bold
    entries = latest_log(dao, 5)
    body = isempty(entries) ? "{yellow}no governance events yet{/yellow}" : join(entries, "\n")
    return Panel(body; title=title, style="cyan", width=86)
end

function render!(simulator::Simulator)::Nothing
    clear_screen()
    make_progress()
    tprint(render_dao_panel(simulator.dao))
    tprint(render_market_panel(active_proposals(simulator.dao)))
    tprint(render_agent_table(simulator.agents))
    tprint(render_governance_log(simulator.dao))
    return nothing
end

function prompt_action()::String
    tprint("{cyan}[b]et [s]kip [p]ropose [q]uit{/cyan} ")
    input = readline(stdin)
    return lowercase(strip(input))
end

end
