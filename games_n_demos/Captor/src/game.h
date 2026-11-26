/*
 * game.h: Captor game logic.
 */

#ifndef GAME_H
#define GAME_H

void game_init(void);
void game_frame(void);	/* call once per frame, after video_vblank() */

#endif
