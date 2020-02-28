#!/usr/bin/env julia

using TimerOutputs
using PyPlot
using Printf

const N=4096
const NP = Float64(N)
const xmin	= -1.5
const xmax 	=  1.0
const ymin 	= -1.0
const ymax	=  1.0

const dx = (xmax-xmin)/NP
const dy = (ymax-ymin)/NP

to = TimerOutput()

function fill_z!(z::Array{Complex{Float64}},N::Int64,M::Int64,xmin::Float64,dx::Float64,ymin::Float64,dy::Float64)
	xjm1tdy::Float64 = 0.0
	@inbounds for i in 1:N
		xim1tdxpxmin = xmin+Float64(i-1)*dx
		@inbounds for j in 1:M
			xjm1tdypymin = ymin+Float64(j-1)*dy
			z[i,j] =  ComplexF64(xim1tdxpxmin,xjm1tdypymin)
		end
	end
    return nothing
end


function mbi(zzz::Array{Complex{Float64}},ccc::Array{Complex{Float64}},t::BitArray,zzzp::Array{Complex{Float64}},Niter::Int64)
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

	four::Float64  = 4.0
	z_two::Complex{Float64} = 2.0+0.0im
    @simd for i in 1:Niter
        zzzp .= zzz .* zzz .+ ccc
        t    .= ( abs2.(zzzp) .< four )
		zzz .= zzzp .*  t  .+ z_two .* ( .! t )
    end
    return nothing
end

@timeit to "create array" 		z = Array{ComplexF64}(undef,N,N)
@timeit to "fill array" 		fill_z!(z,N,N,xmin,dx,ymin,dy)
@timeit to "create BitArray"	t    = BitArray(undef,size(z))
@timeit to "create temp array" 	zzzp = Array{ComplexF64}(undef,size(z))
@timeit to "copy constant" 		c 	 = copy(z)

# force 1 iteration to compile function, then time 80 iterations of the compiled function
mbi(z,c,t,zzzp,1)

@timeit to "run iterations" mbi(z,c,t,zzzp,80)

@timeit to "get magnitude"  field = abs.(z)
#PyPlot.gray()
@timeit to "create plot" imshow(field,interpolation="none")
colorbar()
@timeit to "save plot" savefig("mbs.png",dpi=1200)
show(to)
@printf("\n");
