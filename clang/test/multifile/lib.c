static int helper(int x) { return x + 1000; }  /* same name as in a.c */
int r1(int x) { return x * x; }
int other(int x) {
  switch (x) { case 1: return helper(1); case 3: return 30; case 5: return 50;
               case 7: return 70; case 9: return helper(9); default: return 0; }
}
