#!/usr/bin/env julia

using TimerOutputs
using PyPlot
using Printf
using Distributed

N=4096
NP = Float64(N)
const xmin	= -1.5
const xmax 	=  1.0
const ymin 	= -1.0
const ymax	=  1.0
const Nthr = Threads.nthreads()
const Nperpanel = Int64(ceil(N/Nthr))

zpanel = zeros(ComplexF64,Nthr,Nperpanel,N)
zfinal = zeros(ComplexF64,N,N)
#@printf("size of zpanel = %s\n",size(zpanel))

dx = (xmax-xmin)/NP
dy = (ymax-ymin)/NP

to = TimerOutput()


function mbi(zzz::Array{Complex{Float64}},ccc::Array{Complex{Float64}},Niter::Int64,panel::Int64)
        t    = BitArray(undef,size(zzz))
        zzzp = zeros(ComplexF64,size(zzz))
 		four = 4.0
		#@printf("size of zzz, zzp, zzq, ccp = %s, %s, %s, %s\n",size(zzz),size(zzp),size(zzq),size(ccp))
        for i in 1:Niter
            zzzp  .= zzz  .* zzz  .+ ccc
            t    .= ( abs2.(zzzp) .< four )
			zzz  .= zzzp  .*  t   .+ four .* ( .! t  )
        end
        return nothing
end

function fill_z!(z::Array{Complex{Float64}},N::Int64,M::Int64,xmin::Float64,dx::Float64,ymin::Float64,dy::Float64)
        [@inbounds z[j,i]=ComplexF64(xmin+(i-1)*dx,ymin+(j-1)*dy) for j in 1:N, i in 1:N]
        return nothing
end

@timeit to "create array" z = zeros(ComplexF64,N,N)

#@timeit to "fill base array" [z[j,i]=ComplexF64(xmin+(i-1)*dx,ymin+(j-1)*dy) for j in 1:N, i in 1:N]
@timeit to "fill base array" fill_z!(z,N,N,xmin,dx,ymin,dy)

@timeit to "fill paneled array" @inbounds for panel=1:Nthr
						 		 @inbounds for j in 1:Nperpanel
								  @inbounds for i in 1:N
									zpanel[panel,j,i]=z[j+Nperpanel*(panel-1),i]
								  end
							     end
end

#[z[i,j]=ComplexF64(xmin+(i-1)*dx,ymin+(j-1)*dy) for j in 1:N, i in 1:N]
@timeit to "copy constant" c = copy(zpanel)

# force 1 iteration to compile function, then time 80 iterations of the compiled function
Threads.@threads for panel=1:Nthr
	mbi(zpanel[panel,:,:],c[panel,:,:],1,panel)
end

@timeit to "run iterations" Threads.@threads for panel=1:Nthr
								mbi(zpanel[panel,:,:],c[panel,:,:],80,panel)
							end

@timeit to "copy from panels" for panel=1:Nthr
								  zfinal[Nperpanel*(panel-1)+1:Nperpanel*panel,:] = zpanel[panel,:,:]
							  end

@timeit to "get magnitude"  field = abs.(zfinal)
#PyPlot.gray()
@timeit to "create plot" imshow(field,interpolation="none")
colorbar()
@timeit to "save plot" savefig("mbs.png",dpi=1200)
show(to)
@printf("\n");
