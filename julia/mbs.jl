#!/usr/bin/env julia

using TimerOutputs
using PyPlot
using Printf

N=4096
NP = Float64(N)
const xmin	= -1.5
const xmax 	=  1.0
const ymin 	= -1.0
const ymax	=  1.0

dx = (xmax-xmin)/NP
dy = (ymax-ymin)/NP

to = TimerOutput()


z = zeros(ComplexF64,N,N)

function fill_z!(z::Array{Complex{Float64}},N::Int64,M::Int64,xmin::Float64,dx::Float64,ymin::Float64,dy::Float64)
        [@inbounds z[j,i]=ComplexF64(xmin+(i-1)*dx,ymin+(j-1)*dy) for j in 1:N, i in 1:N]
        return nothing
end

function mbi!(zzz::Array{Complex{Float64}},ccc::Array{Complex{Float64}},Niter::Int64)
	# main Mandelbrot Iteration function.
	#
	# update zzz in place.
	#
	# main loop
	#		loop
	#			z_next = z*z + c
	#			if |z_next| > 2 then z_next = 2.0 + 0.0 im
	#		end loop
	#

	# create local temp space to avoid unneeded per iteration temp allocation
    zzzp = zeros(ComplexF64,size(zzz))

	for i in 1:Niter
		zzzp .= zzz .* zzz .+ ccc

		# note: abs2(z) provides |z|^2, which avoids a square root
		# that is superfluous to the calculation
		zzz .= zzzp .* ( abs2.(zzzp) .< 4.0 ) .+ (2.0 + 0.0im) * ( abs.(zzzp) .>= 4.0 )
	end
	return nothing
end

# create arrays

@timeit to "fill array" fill_z!(z,N,N,xmin,dx,ymin,dy)
@timeit to "copy constant" c = copy(z)

# force 1 iteration to compile function, then time 80 iterations of the compiled function
mbi!(z,c,1)

@timeit to "run iterations" mbi!(z,c,80)

@timeit to "get magnitude"  field = abs.(z)
#PyPlot.gray()
@timeit to "create plot" imshow(field,interpolation="none")
colorbar()
@timeit to "save plot" savefig("mbs.png",dpi=1200)
show(to)
@printf("\n");
