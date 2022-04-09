#!/usr/bin/env julia

using TimerOutputs, GLMakie, FileIO

N=4096
NPx = N
NPy = convert(Int64,round(3*NPx/4))		# 3/4 aspect ratio
const xmin	= -2.0
const xmax 	=  1.0
const ymin 	= -1.25
const ymax	=  1.25

dx = (xmax-xmin)/NPx
dy = (ymax-ymin)/NPy

xs = [ xmin + (i-1)*dx for i in 1:NPx]
ys = [ ymin + (i-1)*dy for i in 1:NPy]


to = TimerOutput()
out_array = zeros(Float64,NPx,NPy)

function mb_iterate(i,j,dx,dy,xmin,ymin,Niter)
	z = c =  xmin + (i-1) * dx + im*(ymin + (j-1) * dy)
	j = 0.0
	for i in 1:Niter
		j += 1.0
		z_prime = z*z + c
		if abs2(z_prime) <= 4.0
			z = z_prime
		else
			z = j + 0*im
			break
		end
	end
	return abs(z)
end

# compile mb_iterate with 1 call, then time it on the array.
x = mb_iterate(1,1,dx,dy,xmin,ymin,60)
print("x = $x\n") # to defeat being optimized away

@timeit to "run iterations for loops" @inbounds Threads.@threads for i in 1:NPx
	@simd for j in 1:NPy
		out_array[i,j] = mb_iterate(i,j,dx,dy,xmin,ymin,60)
	end
end

jrange = 1:NPy
irange = 1:NPx
@timeit to "run iterations for loop + broadcast" Threads.@threads for j in 1:NPy
		out_array[irange,j] = mb_iterate.(irange,j,dx,dy,xmin,ymin,30)
end

@timeit to "create figure and save" FileIO.save("mbs.png",
					heatmap(xs,ys,out_array,colormap = Reverse(:deep));
					resolution = size(out_array))


show(to)
print("\n")
