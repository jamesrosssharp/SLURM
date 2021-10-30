
#include <SDL2/SDL.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include <SDL2/SDL_image.h>

#define SCREEN_WIDTH    640
#define SCREEN_HEIGHT   480

SDL_Window*     window   = NULL;
SDL_Renderer*   renderer = NULL;

SDL_Surface * image;


int sx1 = 10;
int sx2 = 500;
int sy1 = 50;
int sy2 = 400;

int u1 = 319;
int u2 = 0;
int v1 = 199;
int v2 = 0;


int init(int dummy)
{

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

	IMG_Init(IMG_INIT_PNG);

	image  = IMG_Load("plane.png");

    SDL_SetRenderDrawColor(renderer, 0, 0, 0, SDL_ALPHA_OPAQUE);
    SDL_RenderClear(renderer);

    printf("inited!\n");

    return 0;
}

uint32_t getpixel(SDL_Surface *surface, int x, int y)
{
    int bpp = surface->format->BytesPerPixel;
    /* Here p is the address to the pixel we want to retrieve */
    Uint8 *p = (Uint8 *)surface->pixels + y * surface->pitch + x * bpp;

	switch (bpp)
	{
    case 1:
        return *p;
        break;

    case 2:
        return *(Uint16 *)p;
        break;

    case 3:
        if (SDL_BYTEORDER == SDL_BIG_ENDIAN)
            return p[0] << 16 | p[1] << 8 | p[2];
        else
            return p[0] | p[1] << 8 | p[2] << 16;
            break;

        case 4:
            return *(Uint32 *)p;
            break;

        default:
            return 0;       /* shouldn't happen, but avoids warnings */
      }
}

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

    SDL_SetRenderDrawColor(renderer, 0, 0, 0, SDL_ALPHA_OPAQUE);
    SDL_RenderClear(renderer);
}

int shutDown(int dummy)
{
	IMG_Quit();

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    
    printf("Shutdown\n");

    return 0;
}

void render()
{
	// Perform bitmap scaling

	int u = u1;
	int v = v1;

	int u_start = u1;

	int u_diff = u2 - u1;
	int v_diff = v2 - v1;

	int x_diff = sx2 - sx1;
	int y_diff = sy2 - sy1;

	int u_accu = 0;
	int v_accu = 0;

	int u_step = 1;
	int v_step = 1;

	if (u_diff < 0)
	{
		u_diff = -u_diff;
		u_step = -u_step;
		//u = u2;
		//u_start = u2;
	}

	if (v_diff < 0)
	{
		v_diff = -v_diff;
		v_step = -v_step;
		//v = v2;
	}

	for (int y = sy1; y < sy2; y++) 
	{
		u = u_start;

		for (int x = sx1; x < sx2; x++)
			{
				SDL_Color rgb;
				uint32_t data = getpixel(image, u, v);
				SDL_GetRGB(data, image->format, &rgb.r, &rgb.g, &rgb.b);

				drawPoint(x, y, rgb.r, rgb.g, rgb.b);
		
				u_accu += u_diff;
		
				while (u_accu > x_diff)
				{
					u_accu -= x_diff;	
					u += u_step;
				}

			}

			v_accu += v_diff;
		
			while (v_accu > y_diff)
			{
				v_accu -= y_diff;	
				v += v_step;
			}
	}

	flipBuffer(true);
}

int main(int argc, char** argv)
{
	init(true);

	float scale = 1.0;
	int frames;	

	while (1)
	{
		scale = 200 + 100*sin(2*3.14*frames / 100);

		sx1 = 320 - scale;
		sx2 = 320 + scale;
		sy1 = 240 - scale;
		sy2 = 240 + scale; 


		// Render stuff
		render();

		// Poll for events, and handle the ones we care about.
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
		frames ++;
		SDL_Delay(10);
	}

	shutDown(true);
}
