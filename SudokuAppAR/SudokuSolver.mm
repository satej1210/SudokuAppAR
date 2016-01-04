//
//  main.cpp
//  Sudoku
//
//  Created by Mudit Gupta on 6/20/15.
//  Copyright (c) 2015 Mudit Gupta. All rights reserved.
//

#include <iostream>

#include <vector>
#include "SudokuSolver.h"


using namespace std;
/*
 void DrawGrid();
 
 
 void GetPuz(const char*);
 void CheckRow(int r);
 void CheckColumn(int c);
 void CheckBox(int x, int y);
 void CheckAll();
 void CheckAllSingles();
 bool* ReturnBoxPossibilities(int x, int i, int j);
*/


char completedString[81];
class cellSudoku
{
    int state = 0;
    int box_number;
    
public:
    bool is_filled = false;
    bool possibilities[9] = {true, true, true, true, true, true, true, true, true};
    bool printed = false;
    
    void ChangeState(int x) //changes the state of the cell and deletes all possibilities
    {
        state = x;
        is_filled = true;
        for(int i=0; i<9; i++)
        {
            possibilities[i] = false;
        }
    }
    
    int GetState() //gets the private variable state
    {
        return state;
    }
    
};
vector<vector<cellSudoku>> sudoku;

class lockedcandidate
{
public:
#define g(x) *(GetNumberArray+x)
    void static f11(int i, int j)   //row in box
    {
        bool *GetNumberArray;
        for(int x=1; x<=9; x++)
        {
            GetNumberArray = ReturnBoxPossibilities(x, i, j);
            if(g(0)||g(1)||g(2))
                if((g(3)||g(4)||g(5)||g(6)||g(7)||g(8))==false)
                {
                    for(int b=0; b<9; b++)
                    {
                        if(b<j||b>=j+3)
                            sudoku[i][b].possibilities[x-1]=false;
                    }
                }
            
            if(g(3)||g(4)||g(5))
                if((g(0)||g(1)||g(2)||g(6)||g(7)||g(8))==false)
                {
                    for(int b=0; b<9; b++)
                    {
                        if(b<j||b>=j+3)
                            sudoku[i+1][b].possibilities[x-1]=false;
                    }
                    
                }
            if(g(6)||g(7)||g(8))
                if((g(3)||g(4)||g(5)||g(0)||g(1)||g(2))==false)
                {
                    for(int b=0; b<9; b++)
                    {
                        if(b<j||b>=j+3)
                            sudoku[i+2][b].possibilities[x-1]=false;
                    }
                    
                }
            
            
            
        }
    }
    
    void static f12(int i, int j) //column in box
    {
        bool *GetNumberArray;
        for(int x=1; x<=9; x++)
        {
            GetNumberArray = ReturnBoxPossibilities(x, i, j);
            
            if(g(0)||g(3)||g(6))
                if((g(1)||g(2)||g(4)||g(5)||g(7)||g(8))==false)
                {
                    for(int b=0; b<9; b++)
                    {
                        if(b<i||b>=i+3)
                            sudoku[b][j].possibilities[x-1]=false;
                    }
                    
                }
            
            if(g(1)||g(4)||g(7))
                if((g(0)||g(2)||g(3)||g(5)||g(6)||g(8))==false)
                {
                    for(int b=0; b<9; b++)
                    {
                        if(b<i||b>=i+3)
                            sudoku[b][j+1].possibilities[x-1]=false;
                    }
                }
            if(g(2)||g(5)||g(8))
                if((g(0)||g(1)||g(3)||g(4)||g(6)||g(7))==false)
                {
                    for(int b=0; b<9; b++)
                    {
                        if(b<i||b>=i+3)
                            sudoku[b][j+2].possibilities[x-1]=false;
                    }
                }
            
            
            
        }
        
    }
    
    void static both()
    {
        
        
        for(int i=0; i<9; i+=3)
        {
            for(int j=0; j<9; j+=3)
            {
                f11(i,j);
                f12(i,j);
            }
        }
    }
    
    void static f21(int i) //row
    {
        bool *GetNumberArray;
        for(int x=1; x<=9; x++)
        {
            GetNumberArray = ReturnRowPossibilities(x, i);
            
            if(g(0)||g(1)||g(2))
                if((g(3)||g(4)||g(5)||g(6)||g(7)||g(8))==false)
                {
                    int left_row_num=(i)/3*3;
                    int left_col_num=0;
                    
                    for(int a=left_row_num; a<left_row_num+3; a++)
                    {
                        for(int b=left_col_num; b<left_col_num+3; b++)
                        {
                            if(a!=i)
                                sudoku[a][b].possibilities[x-1]=false;
                        }
                        
                    }
                }
            
            if(g(3)||g(4)||g(5))
                if((g(0)||g(1)||g(2)||g(6)||g(7)||g(8))==false)
                {
                    int left_row_num=(i)/3*3;
                    int left_col_num=3;
                    
                    for(int a=left_row_num; a<left_row_num+3; a++)
                    {
                        for(int b=left_col_num; b<left_col_num+3; b++)
                        {
                            if(a!=i)
                                sudoku[a][b].possibilities[x-1]=false;
                        }
                        
                    }
                }
            
            if(g(6)||g(7)||g(8))
                if((g(3)||g(4)||g(5)||g(0)||g(1)||g(2))==false)
                {
                    int left_row_num=(i)/3*3;
                    int left_col_num=6;
                    
                    for(int a=left_row_num; a<left_row_num+3; a++)
                    {
                        for(int b=left_col_num; b<left_col_num+3; b++)
                        {
                            if(a!=i)
                                sudoku[a][b].possibilities[x-1]=false;
                        }
                        
                    }
                }
            
            
        }
        
    }
    
    void static f22(int i) //column
    {
        bool *GetNumberArray;
        for(int x=1; x<=9; x++)
        {
            GetNumberArray = ReturnColPossibilities(x, i);
            
            if(g(0)||g(1)||g(2))
                if((g(3)||g(4)||g(5)||g(6)||g(7)||g(8))==false)
                {
                    int left_col_num=(i)/3*3;
                    int left_row_num=0;
                    
                    for(int a=left_row_num; a<left_row_num+3; a++)
                    {
                        for(int b=left_col_num; b<left_col_num+3; b++)
                        {
                            if(b!=i)
                                sudoku[a][b].possibilities[x-1]=false;
                        }
                        
                    }
                }
            
            if(g(3)||g(4)||g(5))
                if((g(0)||g(1)||g(2)||g(6)||g(7)||g(8))==false)
                {
                    int left_col_num=(i)/3*3;
                    int left_row_num=3;
                    
                    for(int a=left_row_num; a<left_row_num+3; a++)
                    {
                        for(int b=left_col_num; b<left_col_num+3; b++)
                        {
                            if(b!=i)
                                sudoku[a][b].possibilities[x-1]=false;
                        }
                        
                    }
                }
            
            if(g(6)||g(7)||g(8))
                if((g(3)||g(4)||g(5)||g(0)||g(1)||g(2))==false)
                {
                    int left_col_num=(i)/3*3;
                    int left_row_num=6;
                    
                    for(int a=left_row_num; a<left_row_num+3; a++)
                    {
                        for(int b=left_col_num; b<left_col_num+3; b++)
                        {
                            if(b!=i)
                                sudoku[a][b].possibilities[x-1]=false;
                        }
                        
                    }
                }
            
            
        }
        
    }
    
    void static both2()
    {
        for(int i=0; i<9; i++)
        {
            f21(i);
            f22(i);
        }
        
    }
    
};

class naked
{
private:
    
    void static nakedpaircolumn(int x);
    void static nakedpairbox(int x, int y);
    void static nakedtriplerow(int x);
    void static nakedtriplecolumn(int x);
    void static nakedtriplebox(int x, int y);
    void static nakedquadrow(int x);
    void static nakedquadcolumn(int x);
    void static nakedquadbox(int x, int y);
public:
    
    void static nakedpairrow(int x);
    
    void static all()
    {
        for(int i=1; i<=9; i++){nakedpairrow(i);};
        for(int i=1; i<=9; i++){nakedpaircolumn(i);};
      
        cf2(nakedpairbox);
        for(int i=1; i<=9; i++){nakedtriplerow(i);};
        for(int i=1; i<=9; i++){nakedtriplecolumn(i);};
        for(int i=1; i<=9; i++){nakedquadrow(i);};
        for(int i=1; i<=9; i++){nakedquadcolumn(i);};
    
        
        //        cf2(nakedtriplebox);
        //        cf2(nakedquadbox);
    }
    
};

void naked::nakedquadrow(int RowNumber)
{
    for(int Number1=1; Number1<=9; Number1++)
    {
        for(int Number2=Number1+1; Number2<=9; Number2++)
        {
            for(int Number3=Number2+1; Number3<=9; Number3++)
            {
                for(int Number4=Number3+1; Number4<=9; Number4++)
                {
                    int outerflag = 0;
                    int store[4] = {-1,-1, -1,-1};
                    int index = 0;
                    
                    for(int i=0; i<9; i++)
                    {
                        int FalseNum = 0;
                        int TrueNum= 0;
                        
                        if(sudoku[RowNumber-1][i].possibilities[Number1-1] || sudoku[RowNumber-1][i].possibilities[Number2-1] || sudoku[RowNumber-1][i].possibilities[Number3-1]||sudoku[RowNumber-1][i].possibilities[Number4-1])
                        {
                            if(sudoku[RowNumber-1][i].possibilities[Number1-1])
                                TrueNum++;
                            if(sudoku[RowNumber-1][i].possibilities[Number2-1])
                                TrueNum++;
                            if(sudoku[RowNumber-1][i].possibilities[Number3-1])
                                TrueNum++;
                            if(sudoku[RowNumber-1][i].possibilities[Number4-1])
                                TrueNum++;
                            
                            
                            for(int x=1; x<=9; x++)
                            {
                                if(!(sudoku[RowNumber-1][i].possibilities[x-1]))
                                    FalseNum++;
                            }
                            if(FalseNum==(9-TrueNum))
                            {
                                outerflag++;
                                store[index] = i;
                                index++;
                            }
                        }
                    }
                    if(outerflag==4)
                    {
                        cout<<"\nnaked quad row found at"<<RowNumber;
                        for(int i=0; i<9; i++)
                        {
                            if(i!=store[0] && i!=store[1] && i!=store[2] && i!=store[3])
                            {
                                sudoku[RowNumber-1][i].possibilities[Number1-1]=false;
                                sudoku[RowNumber-1][i].possibilities[Number2-1]=false;
                                sudoku[RowNumber-1][i].possibilities[Number3-1]=false;
                                sudoku[RowNumber-1][i].possibilities[Number4-1]=false;
                            }
                        }
                    }
                }
            }
        }
    }
}


void naked::nakedquadcolumn(int ColumnNumber)
{
    for(int Number1=1; Number1<=9; Number1++)
    {
        for(int Number2=Number1+1; Number2<=9; Number2++)
        {
            for(int Number3=Number2+1; Number3<=9; Number3++)
            {
                for(int Number4=Number3+1; Number4<=9; Number4++)
                {
                    int outerflag = 0;
                    int store[4] = {-1,-1, -1,-1};
                    int index = 0;
                    
                    for(int i=0; i<9; i++)
                    {
                        int FalseNum = 0;
                        int TrueNum= 0;
                        
                        if(sudoku[i][ColumnNumber-1].possibilities[Number1-1] || sudoku[i][ColumnNumber-1].possibilities[Number2-1] || sudoku[i][ColumnNumber-1].possibilities[Number3-1]||sudoku[i][ColumnNumber-1].possibilities[Number4-1])
                        {
                            if(sudoku[i][ColumnNumber-1].possibilities[Number1-1])
                                TrueNum++;
                            if(sudoku[i][ColumnNumber-1].possibilities[Number2-1])
                                TrueNum++;
                            if(sudoku[i][ColumnNumber-1].possibilities[Number3-1])
                                TrueNum++;
                            if(sudoku[i][ColumnNumber-1].possibilities[Number4-1])
                                TrueNum++;
                            
                            
                            for(int x=1; x<=9; x++)
                            {
                                if(!(sudoku[i][ColumnNumber-1].possibilities[x-1]))
                                    FalseNum++;
                            }
                            if(FalseNum==(9-TrueNum))
                            {
                                outerflag++;
                                store[index] = i;
                                index++;
                            }
                        }
                    }
                    if(outerflag==4)
                    {
                        cout<<"\nnaked quad column found at"<<ColumnNumber;
                        for(int i=0; i<9; i++)
                        {
                            if(i!=store[0] && i!=store[1] && i!=store[2] && i!=store[3])
                            {
                                sudoku[i][ColumnNumber-1].possibilities[Number1-1]=false;
                                sudoku[i][ColumnNumber-1].possibilities[Number2-1]=false;
                                sudoku[i][ColumnNumber-1].possibilities[Number3-1]=false;
                                sudoku[i][ColumnNumber-1].possibilities[Number4-1]=false;
                            }
                        }
                    }
                }
            }
        }
    }
}




void naked::nakedtriplerow(int RowNumber)
{
    for(int Number1=1; Number1<=9; Number1++)
    {
        for(int Number2=Number1+1; Number2<=9; Number2++)
        {
            for(int Number3=Number2+1; Number3<=9; Number3++)
            {
                int outerflag = 0;
                int store[3] = {-1,-1, -1};
                int index = 0;
                
                for(int i=0; i<9; i++)
                {
                    int FalseNum = 0;
                    int TrueNum= 0;
                    
                    if(sudoku[RowNumber-1][i].possibilities[Number1-1] || sudoku[RowNumber-1][i].possibilities[Number2-1] || sudoku[RowNumber-1][i].possibilities[Number3-1])
                    {
                        if(sudoku[RowNumber-1][i].possibilities[Number1-1])
                            TrueNum++;
                        if(sudoku[RowNumber-1][i].possibilities[Number2-1])
                            TrueNum++;
                        if(sudoku[RowNumber-1][i].possibilities[Number3-1])
                            TrueNum++;
                        
                        
                        for(int x=1; x<=9; x++)
                        {
                            if(!(sudoku[RowNumber-1][i].possibilities[x-1]))
                                FalseNum++;
                        }
                        if(FalseNum==(9-TrueNum))
                        {
                            outerflag++;
                            store[index] = i;
                            index++;
                        }
                    }
                }
                if(outerflag==3)
                {
                    cout<<"\nnaked triple row found at"<<RowNumber;
                    for(int i=0; i<9; i++)
                    {
                        if(i!=store[0] && i!=store[1] && i!=store[2])
                        {
                            sudoku[RowNumber-1][i].possibilities[Number1-1]=false;
                            sudoku[RowNumber-1][i].possibilities[Number2-1]=false;
                            sudoku[RowNumber-1][i].possibilities[Number3-1]=false;
                        }
                    }
                }
            }
        }
    }
    
}

void naked::nakedtriplecolumn(int ColumnNumber)
{
    for(int Number1=1; Number1<=9; Number1++)
    {
        for(int Number2=Number1+1; Number2<=9; Number2++)
        {
            for(int Number3=Number2+1; Number3<=9; Number3++)
            {
                int outerflag = 0;
                int store[3] = {-1,-1, -1};
                int index = 0;
                
                for(int i=0; i<9; i++)
                {
                    int FalseNum = 0;
                    int TrueNum= 0;
                    
                    if(sudoku[i][ColumnNumber-1].possibilities[Number1-1] || sudoku[i][ColumnNumber-1].possibilities[Number2-1] || sudoku[i][ColumnNumber-1].possibilities[Number3-1])
                    {
                        if(sudoku[i][ColumnNumber-1].possibilities[Number1-1])
                            TrueNum++;
                        if(sudoku[i][ColumnNumber-1].possibilities[Number2-1])
                            TrueNum++;
                        if(sudoku[i][ColumnNumber-1].possibilities[Number3-1])
                            TrueNum++;
                        
                        
                        for(int x=1; x<=9; x++)
                        {
                            if(!(sudoku[i][ColumnNumber-1].possibilities[x-1]))
                                FalseNum++;
                        }
                        if(FalseNum==(9-TrueNum))
                        {
                            outerflag++;
                            store[index] = i;
                            index++;
                        }
                    }
                }
                if(outerflag==3)
                {
                    cout<<"\nnaked triple column found at"<<ColumnNumber;
                    
                    for(int i=0; i<9; i++)
                    {
                        if(i!=store[0] && i!=store[1] && i!=store[2])
                        {
                            sudoku[i][ColumnNumber-1].possibilities[Number1-1]=false;
                            sudoku[i][ColumnNumber-1].possibilities[Number2-1]=false;
                            sudoku[i][ColumnNumber-1].possibilities[Number3-1]=false;
                        }
                    }
                }
            }
        }
    }
    
}

void naked::nakedpairrow(int RowNumber)
{
    for(int Number1=1; Number1<=9; Number1++)
    {
        for(int Number2=Number1+1; Number2<=9; Number2++)
        {
            
            int outerflag = 0;
            int store[2] = {-1,-1};
            int index = 0;
            
            for(int i=0; i<9; i++)
            {
                int innerflag = 0;
                
                if(sudoku[RowNumber-1][i].possibilities[Number1-1] && sudoku[RowNumber-1][i].possibilities[Number2-1])
                {
                    for(int x=1; x<=9; x++)
                    {
                        if(sudoku[RowNumber-1][i].possibilities[x-1])
                            innerflag++;
                    }
                    if(innerflag==2)
                    {
                        outerflag++;
                        store[index] = i;
                        index++;
                    }
                }
            }
            if(outerflag==2)
            {
                cout<<"\nnaked pair row found at"<<RowNumber;
                for(int i=0; i<9; i++)
                {
                    if(i!=store[0] && i!=store[1])
                    {
                        sudoku[RowNumber-1][i].possibilities[Number1-1]=false;
                        sudoku[RowNumber-1][i].possibilities[Number2-1]=false;
                    }
                }
            }
        }
    }
}

void naked::nakedpaircolumn(int ColumnNumber)
{
    for(int Number1=1; Number1<=9; Number1++)
    {
        for(int Number2=Number1+1; Number2<=9; Number2++)
        {
            
            int outerflag = 0;
            int store[2] = {-1,-1};
            int index = 0;
            
            for(int i=0; i<9; i++)
            {
                int innerflag = 0;
                
                if(sudoku[i][ColumnNumber-1].possibilities[Number1-1] && sudoku[i][ColumnNumber-1].possibilities[Number2-1])
                {
                    for(int x=1; x<=9; x++)
                    {
                        if(sudoku[i][ColumnNumber-1].possibilities[x-1])
                            innerflag++;
                    }
                    if(innerflag==2)
                    {
                        outerflag++;
                        store[index] = i;
                        index++;
                    }
                }
            }
            if(outerflag==2)
            {
                cout<<"\nnaked pair column found at"<<ColumnNumber;
                for(int i=0; i<9; i++)
                {
                    if(i!=store[0] && i!=store[1])
                    {
                        sudoku[i][ColumnNumber-1].possibilities[Number1-1]=false;
                        sudoku[i][ColumnNumber-1].possibilities[Number2-1]=false;
                    }
                }
            }
        }
    }
}

void naked::nakedpairbox(int RowNumber, int ColumnNumber)
{
    for(int Number1=1; Number1<=9; Number1++)
    {
        for(int Number2=Number1+1; Number2<=9; Number2++)
        {
            
            int outerflag = 0;
            int store[4] = {-1,-1, -1, -1};
            int index = 0;
            
            for(int i=RowNumber; i<RowNumber+3; i++)
            {
                for(int j=ColumnNumber; j<ColumnNumber+3; j++)
                {
                    int innerflag = 0;
                    
                    if(sudoku[i][j].possibilities[Number1-1] && sudoku[i][j].possibilities[Number2-1])
                    {
                        for(int x=1; x<=9; x++)
                        {
                            if(sudoku[i][j].possibilities[x-1])
                                innerflag++;
                        }
                        
                        if(innerflag==2)
                        {
                            outerflag++;
                            store[index] = i;
                            store[index+1] = j;
                            index+=2;
                        }
                    }
                }
            }
            if(outerflag==2)
            {
                cout<<"\nnaked pair box found at box indexes"<<RowNumber<<" "<<ColumnNumber;
                int newindex = 0;
                for(int i=RowNumber; i<RowNumber+3; i++)
                {
                    for(int j=ColumnNumber; j<ColumnNumber+3; j++)
                    {
                        if(i==store[newindex] && j==store[newindex+1])
                        {
                            newindex+=2;
                        }
                        else
                        {
                            sudoku[i][j].possibilities[Number1-1]=false;
                            sudoku[i][j].possibilities[Number2-1]=false;
                        }
                    }
                }
            }
        }
    }
    
}


bool PuzzleCompleted()
{
    
    
    
    
    for(int i=0; i<9; ++i)
    {
        for(int j=0; j<9; j++)
        {
            if(sudoku[i][j].is_filled==false)
                return false;
        }
    }
    return true;
}

/*void GetPuz()//Reads the sudoku from a file
 {
 fstream file("lc2.txt");
 char temp[10];
 int CurRow=0;
 if (!file) {
 //cout << "File Dumb";
 exit(0);
 }
 while(!file.eof())
 {
 file.getline(temp, 10);
 for (int i=0; i<9; ++i)
 {
 if (temp[i]!=48)
 {
 sudoku[CurRow][i].ChangeState(int(temp[i]-48));
 }
 else
 sudoku[CurRow][i].is_filled=false;
 }
 CurRow++;
 }
 }
 */
void ColumnHiddenSingles(int i)
{
    int no=0;
    
    int flag=0;
    for (int j=1; j<=9; j++)
    {
        flag=0;
        for (int k=0; k<9; k++)
        {
            if (sudoku[k][i].possibilities[j-1]==true)
            {
                
                flag++;
                no=k;
                
            }
            
        }
        if (flag==1)
        {
            //cout<<"\ncolumn hidden single found in column"<<i;
            sudoku[no][i].ChangeState(j);
            CheckAll();
        }
    }
    
    
}

void RowHiddenSingles(int i)
{
    int no=0;
    
    int flag=0;
    for (int j=1; j<=9; j++)
    {
        flag=0;
        for (int k=0; k<9; k++)
        {
            if (sudoku[i][k].possibilities[j-1]==true)
            {
                flag++;
                no=k;
            }
        }
        
        if (flag==1)
        {
            //cout<<"\nrow hidden single found in row"<<i;
            sudoku[i][no].ChangeState(j);
            CheckAll();
        }
    }
    
    
}

void BoxHiddenSingles(int x, int y)
{
    int flag=0;
    int h=0, l=0;
    for (int k=1; k<=9; k++)
    {
        flag=0;
        for (int i=x; i<x+3; ++i)
        {
            
            for (int j=y; j<y+3; j++)
            {
                if (sudoku[i][j].possibilities[k-1]==true&&sudoku[i][j].GetState()==0) {
                    flag++;
                    h=j;
                    l=i;
                }
            }
        }
        if (flag==1) {
            //cout<<"\nbox hidden single found in box indexes"<<x<<" "<<y;
            //////cout << ".." << h << ".. " << k << " >> " << "Single\n\n";
            sudoku[l][h].ChangeState(k);
            CheckAll();
            
            
        }
    }
}

void AllHiddenSingles()
{
    for (int i=0; i<9; ++i)
    {
        RowHiddenSingles(i);
    }
    
    
    for (int i=0; i<9; ++i)
    {
        ColumnHiddenSingles(i);
    }
    for (int i=0; i<9; i+=3) {
        for (int j=0; j<9; j+=3) {
            BoxHiddenSingles(i, j);
        }
    }
}

void DrawGrid()
{
    cout<<" --- --- --- --- --- --- --- --- ---\n";
    for(int i=0; i<9; ++i)
    {
        for(int m=0; m<3; m++)
        {
            for(int j=0; j<9; j++)
            {
                cout<<"|";
                if(sudoku[i][j].is_filled && m==0)
                {
                    cout<<"\'"<<sudoku[i][j].GetState()<<"\'";
                }
                
                
                if(sudoku[i][j].possibilities[m*3+0]==true&&!sudoku[i][j].is_filled)
                    cout<<m*3+1;
                else if(sudoku[i][j].is_filled==false||m!=0)
                    cout<<" ";
                if(sudoku[i][j].possibilities[m*3+1]==true&&!sudoku[i][j].is_filled)
                    cout<<m*3+2;
                else if(sudoku[i][j].is_filled==false||m!=0)
                    cout<<" ";
                if(sudoku[i][j].possibilities[m*3+2]==true&&!sudoku[i][j].is_filled)
                    cout<<m*3+3;
                else if(sudoku[i][j].is_filled==false||m!=0)
                    cout<<" ";
                
            }
            if(m==0)
                cout<<"\b\b\b|\n";
            else
                cout<<"|\n";
        }
        cout<<" --- --- --- --- --- --- --- --- ---\n";
    }
    
    cout<<"\n\n\n\n\n\n\n\n\n\n\n";
    
}

void CheckRow(int r) //actual row number. NOT INDEX.
{
    
    for(int i=1; i<=9; ++i)
    {
        for(int j=1; j<=9; j++)
        {
            if(sudoku[r-1][j-1].GetState()==i)
            {
                for(int k=0; k<9; k++)
                    sudoku[r-1][k].possibilities[i-1]=false;
                break;
            }
        }
        
    }
}

void CheckColumn(int c) //actual column number. NOT INDEX.
{
    
    for(int i=1; i<=9; ++i)
    {
        for(int j=1; j<=9; j++)
        {
            if(sudoku[j-1][c-1].GetState()==i)
            {
                for(int k=0; k<9; k++)
                    sudoku[k][c-1].possibilities[i-1]=false;
                break;
            }
        }
        
    }
}

void CheckBox(int x, int y) //super optimal. x and y are index numbers
{
    int a, b;
    a=x/3 * 3;
    b=y/3 * 3;
    if(sudoku[x][y].is_filled==true)
    {
        for(int i=a; i<=a+2; ++i)
        {
            for(int j=b; j<=b+2; j++)
            {
                sudoku[i][j].possibilities[sudoku[x][y].GetState()-1] = false;
            }
        }
    }
}
void CheckAll() //checks all rows, columns and boxes off. used once in the beginning. Ideally not reqd again.
{
    for(int i=1; i<=9; ++i)
    {
        CheckRow(i);
        CheckColumn(i);
    }
    
    for(int i=0; i<9; ++i)
    {
        for(int j=0; j<9; j++)
        {
            CheckBox(i, j);
        }
    }
    
}

void CheckAllSingles() //checks for any singles and marks them off!
{
    for(int i=0; i<9; ++i)
    {
        for(int j=0; j<9; j++)
        {
            int flag = -1;
            int store = -1;
            for(int k=0; k<9; k++)
            {
                if(sudoku[i][j].possibilities[k]==true) //to get flag and store
                {
                    flag++;
                    store = k;
                }
            }
            if(flag==0)             //if it is a single, change the state and check the row, column and boxes off.
            {
                //cout<<"\nsingle found at position"<<i<<" "<<j;
                sudoku[i][j].ChangeState(store+1);
                
            }
        }
    }
}

bool* ReturnBoxPossibilities(int x, int i, int j)
{
    static bool PossibleNumberArray[9];
    int counter=0;
    for(int a=i; a<=i+2; a++)
    {
        for(int b=j; b<=j+2; b++)
        {
            if (sudoku[a][b].possibilities[x-1]==true)
                PossibleNumberArray[counter]=true;
            else
                PossibleNumberArray[counter]=false;
            counter++;
            
        }
    }
    
    return PossibleNumberArray;
    
}

bool* ReturnColPossibilities(int x, int j)
{
    static bool PossibleNumberArray[9];
    int counter=0;
    for(int b=0; b<9; b++)
    {
        if (sudoku[b][j].possibilities[x-1]==true)
            PossibleNumberArray[counter]=true;
        else
            PossibleNumberArray[counter]=false;
        counter++;
        
    }
    return PossibleNumberArray;
}

bool* ReturnRowPossibilities(int x, int j)
{
    static bool PossibleNumberArray[9];
    int counter=0;
    for(int b=0; b<9; b++)
    {
        if (sudoku[j][b].possibilities[x-1]==true)
            PossibleNumberArray[counter]=true;
        else
            PossibleNumberArray[counter]=false;
        counter++;
        
    }
    return PossibleNumberArray;
}

void GetPuz(const char *puz)//Reads the sudoku from a file -- Not anymore
{
    /*fstream file("lc1.txt");
     
     
     if (!file) {
     //cout << "File Dumb";
     exit(0);
     }
     while(!file.eof())*/
    for (int i = 0; i < 81; i++) {
        completedString[i] = '0';
    }
    sudoku.clear();
    sudoku.resize(9);
    for (int i = 0; i < 9; ++i) {
            sudoku[i].resize(9);
    }
    
    int CurRow=0;
    vector<char> temp;
    for (int j = 0; j <= 81; ++j) {
        if ((j)%9!=0||j==0) {
            temp.push_back( puz[j]);
        }
        else{
            for (int i=0; i<9; ++i)
            {
                if (temp[i]!=48)
                {
                    sudoku[CurRow][i].ChangeState(int(temp[i]-48));
                }
                else
                    sudoku[CurRow][i].is_filled=false;
            }
            
            temp.clear();
            temp.push_back( puz[j]);
            CurRow++;
        }
    }
    temp.clear();
    
}

char* getStringCompleted()
{
    int cnt=0;
    for (int i=0; i<9; i++) {
        for (int j=0; j<9; j++) {
            completedString[cnt] = sudoku[i][j].GetState()+48;
            cnt++;
        }
    }
    return completedString;
}


int theMain()
{
    //DrawGrid();
    //GetPuz(puz);
    CheckAll();
    DrawGrid();
    int completed = 0;
    
    
        for(int i=0; i<10 && !PuzzleCompleted(); ++i)
        {
            
            AllHiddenSingles();
            CheckAll();
            if(PuzzleCompleted()){completed=1;break;}
            CheckAllSingles();
            CheckAll();
            if(PuzzleCompleted()){completed=1;break;}
            lockedcandidate::both();
            CheckAll();
            if(PuzzleCompleted()){completed=1;break;}
            lockedcandidate::both2();
            CheckAll();
            if(PuzzleCompleted()){completed=1;break;}
            naked::all();
            
            
            CheckAll();
            if(PuzzleCompleted()){completed=1;break;}
            
            
        }
    
    
    
    DrawGrid();
    return completed;
    
    
    
}
