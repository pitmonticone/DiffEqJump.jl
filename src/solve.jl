function solve{P,algType,recompile_flag}(
  jump_prob::AbstractJumpProblem{P},
  alg::algType,timeseries=[],ts=[],ks=[],recompile::Type{Val{recompile_flag}}=Val{true};
  kwargs...)

  integrator = init(jump_prob,alg,timeseries,ts,ks,recompile;kwargs...)
  solve!(integrator)
  integrator.sol
end

function init{P,algType,recompile_flag}(
  jump_prob::AbstractJumpProblem{P},
  alg::algType,timeseries=[],ts=[],ks=[],recompile::Type{Val{recompile_flag}}=Val{true};
  callback=CallbackSet(),tstops = Float64[],
  save_positions = P <: AbstractDiscreteProblem ? (false,true) : (true,true),
  kwargs...)

  prob,initial_stop,jump_callback = build_jump_problem(jump_prob,save_positions)
  push!(tstops,initial_stop)
  integrator = init(prob,alg,timeseries,ts,ks,recompile;
                    callback=CallbackSet(callback,jump_callback),
                    tstops=tstops,
                    kwargs...)
end

function build_jump_problem{P<:AbstractODEProblem}(jump_prob::AbstractJumpProblem{P},save_positions)
  jump_callback = DiscreteCallback(jump_prob.discrete_jump_aggregation)
  initial_stop = jump_callback.condition.next_jump
  if typeof(jump_prob.variable_jumps) <: Tuple{}
    new_prob = jump_prob.prob
  end
  new_prob,initial_stop,jump_callback
end
