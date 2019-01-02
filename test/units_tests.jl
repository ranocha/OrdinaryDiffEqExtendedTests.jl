using OrdinaryDiffEq, RecursiveArrayTools, Unitful
using LinearAlgebra

@testset "Algorithms" begin
    algs = [Euler(),Midpoint(),Heun(),Ralston(),RK4(),SSPRK104(),SSPRK22(),SSPRK33(),
            SSPRK432(),BS3(),BS5(),DP5(),DP5Threaded(),DP8(),Feagin10(),Feagin12(),
            Feagin14(),TanYam7(),Tsit5(),TsitPap8(),Vern6(),Vern7(),Vern8(),Vern9()]

    @testset "Scalar units" begin
        f(y,p,t) = 0.5*y / 3.0u"s"
        u0 = 1.0u"N"
        prob = ODEProblem(f,u0,(0.0u"s",1.0u"s"))

        for alg in algs
            if !(alg isa DP5Threaded)
                @show alg
                sol = solve(prob,alg,dt=1u"s"/10)
            end
        end

        sol = solve(prob,ExplicitRK())
    end

    @testset "2D units" begin
        f(dy,y,p,t) = (dy .= 0.5.*y ./ 3.0u"s")
        u0 = [1.0u"N" 2.0u"N"
              3.0u"N" 1.0u"N"]
        prob = ODEProblem(f,u0,(0.0u"s",1.0u"s"))

        for alg in algs
            @show alg
            sol = solve(prob,alg,dt=1u"s"/10)
        end

        sol = solve(prob,ExplicitRK())
    end
end

@testset "Mixed units" begin
    @testset "With ArrayPartition" begin
        r0 = [1131.340, -2282.343, 6672.423]u"km"
        v0 = [-5.64305, 4.30333, 2.42879]u"km/s"
        Δt = 86400.0*365u"s"
        μ = 398600.4418u"km^3/s^2"
        rv0 = ArrayPartition(r0,v0)

        function f(dy, y, μ, t)
            r = norm(y.x[1])
            dy.x[1] .= y.x[2]
            dy.x[2] .= -μ .* y.x[1] / r^3
        end

        prob = ODEProblem(f,rv0,(0.0u"s",1.0u"s"),μ)
        sol = solve(prob,Tsit5())
    end

    @testset "Without ArrayPartition" begin
        # coordinate: u = [position, momentum]
        # parameters: p = [mass, force constanst]
        function f_harmonic!(du,u,p,t)
            du[1] = u[2]/p[1]
            du[2] = -p[2]*u[1]
        end

        mass = 1.0u"kg"
        k = 1.0u"N/m"
        p = [mass, k]

        u0 = [1.0u"m", 0.0u"kg*m/s"] # initial values (position, momentum)
        tspan = (0.0u"s", 10.0u"s")
        prob = ODEProblem(f_harmonic!, u0, tspan, p)
        sol = solve(prob, Tsit5())
    end
end
