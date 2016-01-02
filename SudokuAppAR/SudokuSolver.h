//
//  SudokuSolver.h
//  SudokuAppAR
//
//  Created by Satej Mhatre on 1/2/16.
//  Copyright © 2016 Satej Mhatre. All rights reserved.
//

#ifndef SudokuSolver_h
#define SudokuSolver_h
#include <iostream>
#define i(a,b,c) sudoku[a-1][b-1].ChangeState(c)
#define cf(name) for(int i=1; i<=9; i++){name(i);};
#define cf2(name) for(int i=0; i<9; i+=3) for(int j=0; j<9; j+=3) name(i,j);
#define g(x) *(GetNumberArray+x)
void DrawGrid();

using namespace std;
void GetPuz(const char* puz);
void CheckRow(int r);
void CheckColumn(int c);
void CheckBox(int x, int y);
void CheckAll();
void CheckAllSingles();
bool* ReturnBoxPossibilities(int x, int i, int j);
bool* ReturnRowPossibilities(int x, int i);
bool* ReturnColPossibilities(int, int);
int theMain();
void  nakedpaircolumn(int x);
void  nakedpairbox(int x, int y);
void  nakedtriplerow(int x);
void  nakedtriplecolumn(int x);
void  nakedtriplebox(int x, int y);
void  nakedquadrow(int x);
void  nakedquadcolumn(int x);
void  nakedquadbox(int x, int y);
void  nakedpairrow(int x);
class cellSudoku;
char* getStringCompleted();
#endif /* SudokuSolver_h */
