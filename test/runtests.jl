using Test, Random, QPDAS
using LinearAlgebra, SparseArrays

include("testCholeskySpecial.jl")

import OSQP

Random.seed!(12345)

model = OSQP.Model()

# Test qp problem
me, mi, n = 20, 20, 1000
# Equality
A = randn(me, n)
b = randn(me)
# Inequality
C = randn(mi, n)
d = randn(mi)
# Project from
z = randn(n)

M = [A;C]
# Ax=b
# Cx≥d
u = [b;fill(Inf, length(d))]
l = [b;d]

OSQP.setup!(model; P=SparseMatrixCSC{Float64}(I, n, n), l=l, A=sparse(M), u=u, verbose=false,
    eps_abs=eps(), eps_rel=eps(),
    eps_prim_inf=eps(), eps_dual_inf=eps())

OSQP.update!(model; q=-z)
results = OSQP.solve!(model)
x1 = results.x

QP = QuadraticProgram(A,b,C,d,z)
x2 = solve!(QP)
#x2 = solveQP(A,b,C,d,z)

@test A*x2 ≈ b atol=1e-12 # works up to 1e-14
@test minimum(C*x2 - d) > -1e-12 # works up to 1e-14

@test norm(x1-z) ≈ norm(x2-z) rtol=1e-11 # works up to 1e-12
@test x1 ≈ x2 rtol=1e-10  # works up to 1e-11

# # New test
# b = randn(me)
# d = randn(mi)
z = randn(n)

OSQP.update!(model; q=-z)
results = OSQP.solve!(model)
x1 = results.x

update!(QP, z=z)
x2 = solve!(QP)

@test A*x2 ≈ b atol=1e-12 # works up to 1e-14
@test minimum(C*x2 - d) > -1e-12 # works up to 1e-14

@test norm(x1-z) ≈ norm(x2-z) rtol=1e-11 # works up to 1e-12
@test x1 ≈ x2 rtol=1e-10  # works up to 1e-11

# Update multiple
b = randn(me)
d = randn(mi)
z = randn(n)

# Rebuild for OSQP
u = [b;fill(Inf, length(d))]
l = [b;d]

OSQP.setup!(model; P=SparseMatrixCSC{Float64}(I, n, n), l=l, A=sparse(M), u=u, verbose=false,
    eps_abs=eps(), eps_rel=eps(),
    eps_prim_inf=eps(), eps_dual_inf=eps())

OSQP.update!(model; q=-z)
results = OSQP.solve!(model)
x1 = results.x

update!(QP, z=z, b=b, d=d)
x2 = solve!(QP)

@test A*x2 ≈ b atol=1e-12 # works up to 1e-14
@test minimum(C*x2 - d) > -1e-12 # works up to 1e-14

@test norm(x1-z) ≈ norm(x2-z) rtol=1e-11 # works up to 1e-12
@test x1 ≈ x2 rtol=1e-10  # works up to 1e-11
#
# ## Compare gurobi
#
# env = Gurobi.Env()
# model = gurobi_model(env, f = -z, H = sparse(1.0*I, length(z), length(z)),
#     Aeq = A, beq = b, A = -C, b = -d)
#
# optimize(model)

### TEST P SPARSE

me, mi, n = 20, 20, 1000
# Equality
A = randn(me, n)
b = randn(me)
# Inequality
C = randn(mi, n)
d = randn(mi)
# Project from
z = randn(n)

M = [A;C]
# Ax=b
# Cx≥d
u = [b;fill(Inf, length(d))]
l = [b;d]

dig = fill(1.0,n)
dig[1:2:end] .= 2.0
dig2 = copy(dig)
dig2[1:3:end] .= 3
P = spdiagm(-1 => dig2[1:end-1], 0 => dig, 1 => dig2[1:end-1])

OSQP.setup!(model; P=P, l=l, A=sparse(M), u=u, verbose=false,
    eps_abs=eps(), eps_rel=eps(),
    eps_prim_inf=eps(), eps_dual_inf=eps())

OSQP.update!(model; q=-z)
results = OSQP.solve!(model)
x1 = results.x


QP = QuadraticProgram(A,b,C,d,z,P)
x2 = solve!(QP)
#x2 = solveQP(A,b,C,d,z)

@test A*x2 ≈ b atol=1e-12 # works up to 1e-14
@test minimum(C*x2 - d) > -1e-12 # works up to 1e-14

@test norm(x1-z) ≈ norm(x2-z) rtol=1e-11 # works up to 1e-12
@test x1 ≈ x2 rtol=1e-10  # works up to 1e-11


## TEST UPDATE WITH P
b = randn(me)
d = randn(mi)
z = randn(n)

u = [b;fill(Inf, length(d))]
l = [b;d]
OSQP.setup!(model; P=P, l=l, A=sparse(M), u=u, verbose=false,
    eps_abs=eps(), eps_rel=eps(),
    eps_prim_inf=eps(), eps_dual_inf=eps())
OSQP.update!(model; q=-z)
results = OSQP.solve!(model)
x1 = results.x

update!(QP, z=z, b=b, d=d)
x2 = solve!(QP)

@test A*x2 ≈ b atol=1e-12 # works up to 1e-14
@test minimum(C*x2 - d) > -1e-12 # works up to 1e-14

@test norm(x1-z) ≈ norm(x2-z) rtol=1e-11 # works up to 1e-12
@test x1 ≈ x2 rtol=1e-10  # works up to 1e-11

### TEST P DENSE

PA = randn(n,n)
P = PA*PA' + I

# Needs to be sparse for OSQP
OSQP.setup!(model; P=SparseMatrixCSC(P), l=l, A=sparse(M), u=u, verbose=false,
    eps_abs=eps(), eps_rel=eps(),
    eps_prim_inf=eps(), eps_dual_inf=eps())

OSQP.update!(model; q=-z)
results = OSQP.solve!(model)
x1 = results.x


QP = QuadraticProgram(A,b,C,d,z,P)
x2 = solve!(QP)
#x2 = solveQP(A,b,C,d,z)

@test A*x2 ≈ b atol=1e-12 # works up to 1e-14
@test minimum(C*x2 - d) > -1e-12 # works up to 1e-14

@test norm(x1-z) ≈ norm(x2-z) rtol=1e-11 # works up to 1e-12
@test x1 ≈ x2 rtol=1e-10  # works up to 1e-11



#
#
# me, mi, n = 20, 5, 100
# # Equality
# A = randn(me, n)
# C = randn(mi, n)
# D = randn(mi, n)
# E = randn(mi, n)
# M = [A;C;D;C;E]*[A;C;D;C;E]'
# F = bunchkaufman(M, check=false)
# F.info < 0 && error("info: $(F.info)")
# F2 = F.U*pinv(Matrix(F.D))*F.U'
# @test maximum(abs, F.U*F.D*F.U' - M) < 1e-10
# Pinv = inv(F.U)*pinv(Matrix(F.D))*inv(F.U')
# @test maximum(abs, Pinv*M*Pinv - Pinv) < 1e-14
# @test maximum(abs, M*Pinv*M - M) < 1e-14
