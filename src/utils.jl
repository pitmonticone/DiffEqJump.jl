"""
Removes all entries from the history later than `start_time`. If
`start_time`remove all entries.
"""
function reset_history!(h; start_time = nothing)
    if start_time === nothing
        start_time = -Inf
    end
    @inbounds for i in 1:length(h)
        hi = h[i]
        ix = 0
        if eltype(hi) <: Tuple
            while ((ix + 1) <= length(hi)) && hi[ix + 1][1] <= start_time
                ix += 1
            end
        else
            while ((ix + 1) <= length(hi)) && hi[ix + 1] <= start_time
                ix += 1
            end
        end
        h[i] = ix == 0 ? eltype(h)[] : hi[1:ix]
    end
    nothing
end

"""
Computes conditional rate, given a vector of `rate_closures`, the history of
the process `h`, the solution `sol`. Optionally, it is possible to provide save
points with `saveat` and the indices of the targeted variables with `ixs`.

The vector `rate_closures` contains functions `closure(_h)` that returns a
function `rate(u, p, t)` which computes the conditional rate given any history
`_h`.
"""
function conditional_rate(rate_closures, h, sol; saveat = nothing, ixs = 1:length(h))
    if eltype(h[1]) <: Tuple
        h = [_h[1] for _h in h]
    end
    if typeof(saveat) <: Number
        _saveat = sol.t[1]:saveat:sol.t[end]
    else
        _saveat = sol.t
    end
    p = sol.prob.p
    _h = [eltype(h)(undef, 0) for _ in 1:length(h)]
    hixs = zeros(Int, length(h))
    condrates = Array{Array{eltype(_saveat), 1}, 1}()
    for t in _saveat
        @inbounds for i in 1:length(h)
            hi = h[i]
            ix = hixs[i]
            while ((ix + 1) <= length(hi)) && hi[ix + 1] <= t
                ix += 1
            end
            _h[i] = ix == 0 ? [] : hi[1:ix]
        end
        u = sol(t)
        condrate = Array{typeof(t), 1}()
        @inbounds for i in ixs
            rate = rate_closures[i](_h)
            _rate = rate(u, p, t)
            push!(condrate, _rate)
        end
        push!(condrates, condrate)
    end
    return DiffEqBase.build_solution(sol.prob, sol.alg, _saveat, condrates, dense = false,
                                     calculate_error = false,
                                     destats = DiffEqBase.DEStats(0),
                                     interp = DiffEqBase.ConstantInterpolation(_saveat,
                                                                               condrates))
end
