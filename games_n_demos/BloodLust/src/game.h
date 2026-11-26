/*
 * game.h: BloodLust game logic.
 */

#ifndef GAME_H
#define GAME_H

void game_init(void);

/* Run one frame (called once per vertical blank). */
void game_frame(void);

#endif
