# FractalExplorer (v1.0.0)
Welcome to FractalExplorer, a simple software where you can explore fractal in real time. The fractal render is done by the GPU.

## Informations
Click [here](https://github.com/PixelDeEcran/FractalExplorer/releases/latest) if you want to download the latest version of FractalExplorer.

 - Left Click to move
 - Right Click to rotate
 - Scroll to zoom
 - Space to show/hide the configuration interface
 - Two fractals : Mandelbrot and Julia
 - Two precision modes (defines how far you can zoom) : 32-bit and 64-bit
## Some pictures
![Mandelbrot Set](https://github.com/PixelDeEcran/FractalExplorer/blob/main/screenshots/screenshot1.PNG?raw=true) 
![Mandelbrot Set](https://github.com/PixelDeEcran/FractalExplorer/blob/main/screenshots/screenshot2.PNG?raw=true)![Mandelbrot Set](https://github.com/PixelDeEcran/FractalExplorer/blob/main/screenshots/screenshot3.PNG?raw=true)![Julia Set](https://github.com/PixelDeEcran/FractalExplorer/blob/main/screenshots/screenshot4.PNG?raw=true)
 ## Some thoughts
 At first, this project was just made for me. I wanted to learn Modern OpenGL and C++ (finally, I haven't learned much about Modern OpenGL). And I though that this could be a good idea to share my little program. Thanks to this little project, I've learned so much, but I just don't have a fairly good level to go farther. I tried to emulate a 128-bit floating-point but I didn't succeed. I also tried to implement the Pertubation theory, but I also don't succeed. More generally, there is a lot of jerk in the code.
For those who wonder what tutorial I used to learn Modern OpenGL, click [here](https://www.youtube.com/watch?v=W3gAzLwfIP0&list=PLlrATfBNZ98foTJPJ_Ev03o2oq3-GGOS2).

Maybe in the future, I will try to implement an emulation of 128-bit floating point, and some others stuffs that let's you do some animations (even if I think that's a bad idea, because it's a real render time, and if you do 6 FPS, the animation will just be horrible). 
But for now, I think I've already largely fulfilled my objectives.
