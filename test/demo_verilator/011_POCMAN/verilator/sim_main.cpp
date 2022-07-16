#include "Vslurm16.h"
#include "verilated.h"
  
#include <SDL2/SDL_image.h>

#define SCREEN_WIDTH    640
#define SCREEN_HEIGHT   480

SDL_Window*     window   = NULL;
SDL_Renderer*   renderer = NULL;

SDL_Surface * image;

int drawPoint(int x, int y, int r, int g, int b)
{

    //printf("Put pixel %d %d %x %x %x\n", x, y, r, g, b);
    //printf(".");

    SDL_SetRenderDrawColor(renderer, r, g, b, SDL_ALPHA_OPAQUE);
    SDL_RenderDrawPoint(renderer, x, y);

    return 0;
}

int flipBuffer(int dummy)
{
    SDL_RenderPresent(renderer);

   // SDL_SetRenderDrawColor(renderer, 0, 0, 0, SDL_ALPHA_OPAQUE);
   // SDL_RenderClear(renderer);
	return 0;
}



int main(int argc, char** argv, char** env) {

    if (SDL_Init(SDL_INIT_VIDEO) < 0)
    {
        printf("Could not init video\n");
        exit(EXIT_FAILURE);
    }

    if (SDL_CreateWindowAndRenderer(SCREEN_WIDTH, 
                                    SCREEN_HEIGHT,
                                    0, &window, &renderer) < 0)
    {
        printf("Could not create window and renderer\n");
        exit(EXIT_FAILURE);
    }

    SDL_SetRenderDrawColor(renderer, 255, 255, 255, SDL_ALPHA_OPAQUE);
    SDL_RenderClear(renderer);

	VerilatedContext* contextp = new VerilatedContext;
	contextp->commandArgs(argc, argv);
	Vslurm16* top = new Vslurm16{contextp};
	top->CLK = 0;

	int x = 0;
	int y = 0;
	int prev_hsync = 0;
	int prev_vsync = 0;
	while (!contextp->gotFinish()) { 
		
		contextp->timeInc(1);  // 1 timeprecision period passes...
        top->CLK = !top->CLK;

 		if (!top->CLK) {
              if (contextp->time() > 1 && contextp->time() < 10) {
                  top->RSTb = 0;  // Assert reset
              } else {
                  top->RSTb = 1;  // Deassert reset
              }
        }

		top->eval(); 	

		if (!top->CLK) {
			x += 1;
			if (top->vid_hsync == 0 && top->vid_hsync != prev_hsync) {
				x = 0;
				y += 1;
			}
			if (top->vid_vsync == 0 && top->vid_vsync != prev_vsync) {
				y = 0;
			}

			prev_hsync = top->vid_hsync;
			prev_vsync = top->vid_vsync;

			if (x > (96+48) && y > (33+2))
				drawPoint(x - (96+48), y - (33+2), top->vid_r*16, top->vid_g*16, top->vid_b*16);
			//drawPoint(x, y, 255, 0, 0);
			flipBuffer(0);
		}

		SDL_Event event;
		while (SDL_PollEvent(&event)) 
		{
		  switch (event.type) 
		  {
		  case SDL_KEYDOWN:
			break;
		  case SDL_KEYUP:
			// If escape is pressed, return (and thus, quit)
			if (event.key.keysym.sym == SDLK_ESCAPE)
			  return 0;
			break;
		  case SDL_QUIT:
			return(0);
		  }
		}

	}
	delete top;
	delete contextp;
	return 0;
}
