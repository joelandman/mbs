# mbs
Mandelbrot Set with various languages

Exploring idiomatic ways to write a Mandelbrot set calculation.  Initially in Julia, will
expand to other languages as well.

The [Mandelbrot set](https://en.wikipedia.org/wiki/Mandelbrot_set) is defined well on Wikipedia, as iterating this equation, 

![z = z^2 + c](https://render.githubusercontent.com/render/math?math=z%20%3D%20z%5E2%20%2B%20c)

and measuring the magnitude of z. 

When 

![|z| < 2](https://render.githubusercontent.com/render/math?math=%7Cz%7C%20%3C%202)

you continue iteration for that z.  When 

![|z| > 2](https://render.githubusercontent.com/render/math?math=%7Cz%7C%20%3E%202)

you fix that value of z at 2.0 + 0.0i

where 

![i=sqrt(-1)](https://render.githubusercontent.com/render/math?math=i%3Dsqrt(-1))

Then you plot the aforementioned magnitudes, adjusting color or other attributes by magnitude.  This
gives you complex figures, and this code will generate a png file for you named mbs.png, which you can display.

![Mandelbrot Set](https://github.com/joelandman/mbs/blob/master/mbs.png "Mandelbrot Set example")

The goal here is to provide idiomatic, that is, language centric mechanisms of performing this computation.  In most of these calculations, the calculation is performed by 3 loops, one each for iterations, for the real part of z, and the imaginary part of z.  This is idiomatically C-like.  I wanted to see if I could write this in a way that made better use of the underlying power of the language.

Initial efforts are with Julia.
