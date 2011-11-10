%{
#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include "esil.h"

int yylex(void);
int yyerror(char *);

typedef struct Tnode tnode;
typedef struct TypeDef Typedef;
typedef struct Lsymbol lsymbol;
typedef struct Gsymbol gsymbol;
typedef struct FnCheck fncheck;
typedef struct TDataType tdatatype;
typedef struct ArgStruct argstruct;

lsymbol *lhead = NULL;
lsymbol *llast = NULL;

gsymbol *ghead = NULL;
gsymbol *glast = NULL;

Typedef *typehead = NULL;
Typedef *typelast = NULL;

fncheck *fnhead = NULL;
fncheck *fnlast = NULL;

argstruct *arghead = NULL;
argstruct *arglast = NULL;

tnode   *thead = NULL;
tnode *exprhead = NULL;
tnode *exprlast = NULL;


int main_flag=0;
int mem_count = 0;
int typedefsize = 0;
int traverse(tnode *);
int label=1,regcount=0;
int datatype,Datatype, DataType;

gsymbol *gtypedef = NULL;
gsymbol *gtypeDef = NULL;
gsymbol *gTypedef = NULL;


void checkFuncDefn();
void checkTypeDefn(tnode *);
void InstallArg(argstruct *);
void Linstall(char *,int, gsymbol *);
void checktype(tnode *,tnode *,tnode *);
void Arginstall(char *, int,int, gsymbol *);
void checkFunction(int, char *, argstruct *, gsymbol *);
void Ginstall(char *, int, int, int, argstruct *, Typedef *, gsymbol *);


gsymbol *Glookup(char *);
lsymbol *Llookup(char *);
tdatatype* getTypeDefDataType(tnode *);
tnode *treecreate(int ,int ,char *,int ,tnode *, tnode *, tnode *,lsymbol *, gsymbol *, tnode *, tnode *);


%}
%union {
	struct Tnode *ptr;
}

%token IF THEN ELSE ENDIF WHILE DO ENDWHILE RETURN DECL ENDDECL BEGINING END MAIN NOT
%token CONST ID READ WRITE INTEGER DOT GT GE LT LE EQ AND OR NE TYPEDEF BOOLEAN TRUE FALSE

%type <ptr> GT GE LT LE EQ AND OR NE TRUE FALSE IF WHILE RETURN NOT RetStmt  Variable  TypedefVar
%type <ptr> CONST ID '+'  '-'  '*' '/' '%' '=' READ WRITE Mainblock Stmt Body StmtList expr endif 

%left OR
%left AND
%left EQ NE
%left LT LE GT GE
%left '+' '-'
%left '*' '/' '%'
%right NOT
%right DOT

%%

Prog:		TypeDefblock GDefblock FdefList Mainblock	{  
									   
									checkFuncDefn();
									printf("\n\nSUCCESSFULLY GENERATED ASSEMBLY CODE\n");
								}
		;
		
TypeDefblock: 
		|TypeDefblock TypeDef
		;
		// *name,int type,int size, int binding, argstruct *arglist ,Typedef *typedeflist

TypeDef:	TYPEDEF ID '{' TypeDefList '}'			{	
									
									Ginstall($2->NAME, TYPEDEF_VARTYPE, typedefsize, 0, NULL, typehead, NULL);
									gsymbol *gtemp = Glookup($2->NAME);
									int bind = *(gtemp->BINDING);
									printf("\nInstalling %s with total size %d and at binding %d\n", $2->NAME, typedefsize, bind);
									Typedef *typedeftemp = gtemp->TYPEDEFLIST;
									while(typedeftemp)  {
										
										*(typedeftemp->BINDING) = bind + *(typedeftemp->BINDING);
										printf("\nVAr %s Binding %d SIZE %d ", typedeftemp->NAME, *(typedeftemp->BINDING), typedeftemp->SIZE);
										typedeftemp = typedeftemp->NEXT;
									}
									gtypedef = NULL;
									typehead = NULL;
									typelast = NULL;
									typedefsize = 0;
								}
		;

TypeDefList:	
		|TypeDefList TypeDefDecl
		;

TypeDefDecl:	TypeDefIdType TypeDefIdList ';'
		;

TypeDefIdType:	INTEGER						{	DataType = INT_VARTYPE;			}
		|BOOLEAN					{	DataType = BOOL_VARTYPE;		}
		|ID						{	
									gsymbol *gtemp;
									gtemp = Glookup($1->NAME);
									if(gtemp)  {
									
										if(gtemp->TYPE != TYPEDEF_VARTYPE) {
											yyerror("\nERR: Invalid Datatype for typedef declaration\n");
										}
									}
									
									else  {
									
										yyerror("\nERR: Invalid Datatype for typedef declaration\n");
									}
									
									if(gtemp->GTypeDefType!=NULL)
										yyerror("\nERR: Invalid Datatype for typedef declaration\n");
									
									DataType = TYPEDEF_VARTYPE;
									gtypedef = gtemp;
									
								}
		;

TypeDefIdList:	TypeDefId
		|TypeDefIdList ',' TypeDefId
		;

TypeDefId:	ID						{
									Typedef *typetemp = (Typedef *)malloc(sizeof(Typedef));
									typetemp->NAME = $1->NAME;
									typetemp->TYPE = DataType;
									typetemp->NEXT = NULL;
									typetemp->BINDING=(int*)malloc(sizeof(int));
									*(typetemp->BINDING) = typedefsize;
									if(DataType == TYPEDEF_VARTYPE)
										typetemp->GTypeDefPtr = gtypedef;
									else
										typetemp->GTypeDefPtr = NULL;
									
									if(typehead)  {
									
										typelast->NEXT = typetemp;
										typelast = typetemp;
									}
									
									else  {
									
										typehead = typelast = typetemp;
									}
									switch(DataType)  {
									
										case INT_VARTYPE:	typedefsize = typedefsize + 1;
													typetemp->SIZE = 1;
												 	break;
												 	
										case BOOL_VARTYPE:	
													typetemp->SIZE = 1;
													typedefsize = typedefsize + 1;
													break;
										
										
										case TYPEDEF_VARTYPE:	
													typetemp->SIZE = typetemp->GTypeDefPtr->SIZE;
													typedefsize = typedefsize + typetemp->GTypeDefPtr->SIZE;
													break;
									}
									
								}
		;

GDefblock:	DECL GDefList ENDDECL				{
			
									   FILE *fp;
									   fp=fopen("sim.asm","a");
									  
									   int i;
									   for(i=0;i<mem_count;i++)  {
									   
									   	fprintf(fp,"PUSH R%d\n",regcount);
									   
									   }
									   
									   mem_count = 1;
									   regcount = 0;
									   fprintf(fp,"JMP MAIN\n");
									   fclose(fp);
								}
		;

GDefList :							
							
		|GDefList GDecl				
		;

GDecl:		DataType GIdList	';'			
		;
		
DataType:	INTEGER						{ 	
									DataType = INT_VARTYPE;				
									gTypedef = NULL;
									//printf("\n12");
								}
								
		|BOOLEAN					{  	
									
									DataType = BOOL_VARTYPE;
									gTypedef = NULL;	
									//printf("\n1eq2");				
								}
		|ID						{	
									gsymbol *gtemp = NULL;
									gtemp = Glookup($1->NAME);
									if(gtemp)  {
									
										if(gtemp->TYPE != TYPEDEF_VARTYPE)
											yyerror("\nERR: Invalid Datatype for typedef element\n");
									
									}
									
									else  {
									
										yyerror("\nERR: Invalid Datatype for typedef element\n");
									
									}
									
									if(gtemp->GTypeDefType!=NULL)
										yyerror("\nERR: Invalid Datatype for typedef element\n");
									
									
									
									DataType = TYPEDEF_VARTYPE;
									gTypedef = gtemp;
									gtypeDef = gtemp;	
									
								}
		;
		
GIdList:	GId 					
								
		|GIdList ',' GId 				
		;
		
GId:		ID '[' CONST ']'   				{	
									Ginstall($1->NAME,DataType,$3->VALUE, 0, NULL, NULL, gTypedef);// 4:binding, 5:Arglist 6:typedef
								} 
								
		|ID '(' ArgList ')'				{	
									argstruct *temp = arghead;
									
									Ginstall($1->NAME, DataType, 0, label,  arghead, NULL, gtypeDef); // name, type, size, binding, arglist
									
									label++;
									
									arghead = NULL; arglast = NULL;
														
								}
		
		|ID						{ 	
									Ginstall($1->NAME,DataType,1, 0, NULL, NULL, gTypedef);		
									
								}
		;

ArgList :							{ 	}
		|Argument					{ 	}
		
		|ArgList ';' Argument				{ 	}

		;

Argument :	Type ArgIdList
		;

FArgDef :	
		| FArgList					{	InstallArg(arghead);	}
		;

FArgList :	Argument					{ 	}
		
		|ArgList ';' Argument				{ 	}

		
		;

ArgIdList :
		'&'ID						{	
									Arginstall($2->NAME, datatype,PASSBYREF, gTypedef);	
								}
	
		|ID						{	
									Arginstall($1->NAME, datatype,PASSBYVAL, gTypedef);			
								}
		
		|ArgIdList ',' '&'ID				{	
									
									Arginstall($4->NAME, datatype,PASSBYREF, gTypedef);			
								}
		
		|ArgIdList ',' ID				{	
									
									Arginstall($3->NAME, datatype,PASSBYVAL, gTypedef);			
								}
		;

FdefList :	

		| FdefList Fdef	
		;
		
Fdef : 		RType ID '(' FArgDef ')' '{' LDefblock Body '}'	{	
									checkFunction(Datatype, $2->NAME, arghead, gtypedef);
									
									
									arghead = NULL; arglast = NULL; gtypedef = NULL; gTypedef = NULL;
									FILE *fp;
									fp = fopen("sim.asm","a");
									$2->Gentry = Glookup($2->NAME);
									fprintf(fp,"f%d:\n",*($2->Gentry->BINDING));
									
									fprintf(fp,"PUSH BP\n");
									fprintf(fp,"MOV BP, SP\n");
									
									int i;
									for(i=1;i<mem_count;i++)  {
									
										fprintf(fp,"PUSH R%d\n",regcount);
									
									}
									
									fclose(fp);
									
									traverse($8);
									
									mem_count = 1;
									regcount = 0;
									lhead = NULL;
									llast = NULL;
									
								}
		;

Type:		INTEGER						{ 	
									datatype = INT_VARTYPE;		
									gTypedef = NULL;		
								}
								
		|BOOLEAN					{  	
									
									datatype = BOOL_VARTYPE;
									gTypedef = NULL;			
								}
		
		|ID						{	
									gsymbol *gtemp = NULL;
									gtemp = Glookup($1->NAME);
									if(gtemp)  {
									
										if(gtemp->TYPE != TYPEDEF_VARTYPE)
											yyerror("\nERR: Invalid Datatype for typedef element\n");
									
									}
									
									else  {
									
										yyerror("\nERR: Invalid Datatype for typedef element\n");
									
									}
									
									if(gtemp->GTypeDefType!=NULL)
										yyerror("\nERR: Invalid Datatype for typedef element\n");
									
									datatype = TYPEDEF_VARTYPE;
									gTypedef = gtemp;
								}
		;

RType:		INTEGER						{ 	
									Datatype = INT_VARTYPE;	
									gtypedef = NULL;			
								}
								
		|BOOLEAN					{  	
									
									Datatype = BOOL_VARTYPE;
									gtypedef = NULL;					
								}
		
		|ID						{	
									gsymbol *gtemp = NULL;
									gtemp = Glookup($1->NAME);
									if(gtemp)  {
									
										if(gtemp->TYPE != TYPEDEF_VARTYPE)
											yyerror("\nERR: Invalid Datatype for typedef element\n");
									
									}
									
									else  {
									
										yyerror("\nERR: Invalid Datatype for typedef element\n");
									
									}
									
									if(gtemp->GTypeDefType!=NULL)
										yyerror("\nERR: Invalid Datatype for typedef element\n");
									
									Datatype = TYPEDEF_VARTYPE;
									gtypedef = gtemp;
									
								}
		;
		
Mainblock:	INTEGER Main '(' ')' '{' LDefblock Body '}'     {	
									FILE *fp = fopen("sim.asm","a");
									fprintf(fp,"MAIN:\n");		
									
									fprintf(fp,"PUSH BP\n");
									fprintf(fp,"MOV BP, SP\n");
									
									int i;
									for(i=1;i<mem_count;i++)  {
									
										fprintf(fp,"PUSH R%d\n",regcount);
									
									}
									
									fclose(fp);	 
									traverse($7);    				
									lhead = llast = NULL;
									mem_count = 1;
								}
		
		;
		
Main:		MAIN						{	Datatype  = INT_VARTYPE;
									main_flag = 1;
								}
		;

LDefblock: 	DECL LDefList ENDDECL				
		;

LDefList:	 						
								
		|LDefList LDecl ';'				
		;
		
LDecl:		Type LIdList					
		;

LIdList:	LId 						
								
		|LIdList ',' LId 				
		;

LId:		ID						{  	gsymbol *gtemp = NULL;
									gtemp = Glookup($1->NAME);
									if(gtemp)  {
									
										if(gtemp->TYPE == TYPEDEF_VARTYPE && gtemp->TYPEDEFLIST !=NULL)
											yyerror("\nERR : You cannot reuse typedef variable name\n");
									
									}
									//printf("\ncalling Linstall 12");
									Linstall($1->NAME,datatype, gTypedef);			
								}
		;


Body : 		BEGINING StmtList RetStmt END			{	
									tnode *temp;
									temp = treecreate(DUMMY_TYPE,DUMMY_NODETYPE,NULL,0,NULL,NULL,NULL,NULL, NULL, NULL, NULL);
									temp->Ptr1 = $2;
									temp->Ptr2 = $3;
									$$ = temp;  				
								} 
		;

StmtList:	 						{	$$ = NULL;				}

		| StmtList Stmt ';'				{
								 	tnode *temp;
									temp = treecreate(DUMMY_TYPE,DUMMY_NODETYPE,NULL,0,NULL,NULL,NULL,NULL, NULL, NULL, NULL);
							  		temp->Ptr1=$1;
							  		temp->Ptr2=$2;
							  		$$=temp;
							  	}
		;

exprlist:	
		|expr						{	
									if(!exprhead)  {
										exprhead = exprlast = $1;
									}
									
									else  {
										exprlast->Ptr3 = $1;
										exprlast = $1;
									}
								}
		
		| exprlist ',' expr				{
									if(!exprhead)  {
										exprhead = exprlast = $3;
									}
									
									else  {
										exprlast->Ptr3 = $3;
										exprlast = $3;
									}
								}
		;

TypedefVar:	ID DOT Variable					{ 	
								  	
								  	lsymbol *ltemp;
								  	gsymbol *gtemp;
								  	ltemp = Llookup($1->NAME);
								  	if(!ltemp)  {
								  		gtemp = Glookup($1->NAME) ;
								  		$1->Gentry = gtemp;
								  		if(gtemp && gtemp->TYPEDEFLIST==NULL)  {
								  			
								  			if((gtemp->SIZE)>1)  {
								  				yyerror("\nERR: Invalid array index\n");
								  			}
								  			
								  			if(gtemp->TYPE != TYPEDEF_VARTYPE)  {
								  		
								  				printf("\nERR:%s is not a typedef variable\n", $1->NAME);
								  				yyerror("");
								  		
								  			}
								  			$1->Gentry = gtemp;
								  		}
								  		else  {
								  			printf("\nERR: You have not declared %s \n",$1->NAME);
								  			yyerror("");
								  		}	
								  	}
								  	else  {
								  		$1->Lentry = ltemp;
								  		if(ltemp->TYPE != TYPEDEF_VARTYPE)  {
								  		
								  			printf("\nERR:%s is not a typedef variable\n", $1->NAME);
								  			yyerror("");
								  		
								  		}
								  		$1->Lentry = ltemp;
								  	}
								  			
									$1->Ptr4 = $3;
									$$ = $1;
									checkTypeDefn($1);
								}
		
		|ID '[' expr ']' DOT Variable			{	
									gsymbol *gtemp;
									tdatatype *typedefdatatype;
									
									gtemp = Glookup($1->NAME);
								  	if(gtemp && gtemp->TYPEDEFLIST==NULL)  {
										$1->Gentry = gtemp;
									  	
									  	if(gtemp->TYPE != TYPEDEF_VARTYPE)  {
									  	
									  		printf("\nERR: %s is not a typedef variable\n", gtemp->NAME);
									  		yyerror("");
									  	
									  	}
									  	
									  	if(gtemp->SIZE == 1)
									  		yyerror("\nERR: Invalid array index\n");
									  	
									  	if($3->TYPE==BOOLEAN_TYPE)
									  		yyerror("\nERR:  invalid array index\n");
									  	else if ($3->TYPE == VOID_TYPE){
										  	if ($3->NODETYPE==ID_NODETYPE)  {
									  	
									  			if($3->Gentry)  {
									  				
									  				if($3->Gentry->TYPE == TYPEDEF_VARTYPE)  {
									  					typedefdatatype = getTypeDefDataType($3);
														if(typedefdatatype->TYPE != INT_VARTYPE)
															yyerror("\nERR: invalid array index\n");
									  				}
									  				
									  				if($3->Gentry->TYPE==BOOL_VARTYPE)
									  					yyerror("\nERR: invalid array index\n");
									  				
								  		
									  			}
								  		
									  			else  {
									  				
									  				if($3->Lentry->TYPE == TYPEDEF_VARTYPE)  {
									  					typedefdatatype = getTypeDefDataType($3);
														if(typedefdatatype->TYPE != INT_VARTYPE)
															yyerror("\nERR: invalid array index\n");
									  				}
								  		
								  					if($3->Lentry->TYPE==BOOL_VARTYPE)
								  						yyerror("\nERR: invalid array index\n");
								  				}
								  			}
								  			else  {
								  				yyerror("\nERR:  Not id type right child\n");
								  			}
								  		}
								  		else  {
								  		
								  		}
								 	 }	
									  else  {
										printf("\nERR : You have not declared %s \n",$1->NAME);
							  			yyerror("");
									  }
									
									
									$1->Ptr4 = $6;
									$$ = $1;
									checkTypeDefn($1);
									
								}
		;	
	
Variable:	
		ID						{ 	
									
									$$ = $1;		
								}
								
		|ID DOT Variable				{ 	
									$1->Ptr4 = $3;
									$$ = $1;		
								}
		;		


expr:	 	NOT expr					{
									checktype($2,$1,NULL);
									$1->Ptr1 = $2;
									$$ = $1;
		
								}

		|expr '+' expr					{	//printf("\n %d %d " , $1->VALUE, $3->VALUE);
									checktype($1,$2,$3);
									$2->Ptr1=$1;$2->Ptr2=$3;
									$$=$2; 
								}
								
		|expr '-' expr					{	
									checktype($1,$2,$3);
							   		$2->Ptr1=$1;$2->Ptr2=$3;
							   		$$=$2;
								}
								
		|expr '*' expr					{
									checktype($1,$2,$3);
							   		$2->Ptr1=$1;$2->Ptr2=$3;
							   		$$=$2;
								}
									
		|expr '/' expr					{
									checktype($1,$2,$3);
							  	 	$2->Ptr1=$1;$2->Ptr2=$3;
							   		$$=$2;
								}
								
		|expr '%' expr					{
									checktype($1,$2,$3);
								   	$2->Ptr1=$1;$2->Ptr2=$3;
								   	$$=$2;
								}
								
		| TypedefVar					{	$$ = $1;				}
								
									
		|expr LT expr					{
									checktype($1,$2,$3);
							   		$2->Ptr1=$1;$2->Ptr2=$3;
							  		$$=$2;
								}
								
									
		|expr LE expr					{
									checktype($1,$2,$3);
							   		$2->Ptr1=$1;$2->Ptr2=$3;
							   		$$=$2;
								}
									
		|expr GT expr					{
									checktype($1,$2,$3);
							   		$2->Ptr1=$1;$2->Ptr2=$3;
							   		$$=$2;
								}
								
		|expr GE expr					{
									checktype($1,$2,$3);
							   		$2->Ptr1=$1;$2->Ptr2=$3;
							   		$$=$2;
								}
								
		|expr EQ expr					{
									checktype($1,$2,$3);
							  	 	$2->Ptr1=$1;$2->Ptr2=$3;
							   		$$=$2;
								}	
								
		|expr NE expr					{	checktype($1,$2,$3);
							   		$2->Ptr1=$1;$2->Ptr2=$3;
							   		$$=$2;
								}
								
		|expr AND expr					{	checktype($1,$2,$3);
									$2->Ptr1=$1;$2->Ptr2=$3;
							   		$$=$2;
								}	
								
		|expr OR expr					{	checktype($1,$2,$3);
							   		$2->Ptr1=$1;$2->Ptr2=$3;
							   		$$=$2;
								}
								
		|'(' expr ')'					{	$$=$2;					}
								
		|CONST						{	$$=$1;		//printf("\n%d matched\n", $1->VALUE);			
								}
		
		| ID '(' exprlist ')'				{
		
									gsymbol *gtemp;
									gtemp = Glookup($1->NAME);
									
									if(!gtemp || gtemp->SIZE !=0)
										yyerror("\nERR: Function not declared\n");
									
									$1->ArgList = exprhead;
									
									$1->Gentry = gtemp;
									
									checktype(exprhead, $1, NULL);
									
									exprhead=NULL;
									exprlast=NULL;
									
									$$ = $1;
								
								}	
			
		| ID '[' expr ']'				{
								 	gsymbol *gtemp;
								 	tdatatype *typedefdatatype;
								 	
									gtemp = Glookup($1->NAME);
								  	if(gtemp)  {
										$1->Gentry = gtemp;
										
										if((gtemp->TYPE = TYPEDEF_VARTYPE)&&(gtemp->TYPEDEFLIST != NULL))
								  				yyerror("\nERR: Referring a typedef variable\n");
									  	
									  	if($3->TYPE==BOOLEAN_TYPE)
									  		yyerror("\nERR: invalid array index\n");
									  	else if ($3->TYPE == VOID_TYPE){
										  	if ($3->NODETYPE==ID_NODETYPE)  {
									  	
									  			if($3->Gentry)  {
									  				
									  				if($3->Gentry->TYPE == TYPEDEF_VARTYPE)  {
									  					typedefdatatype = getTypeDefDataType($3);
														if(typedefdatatype->TYPE != INT_VARTYPE)
															yyerror("\nERR: invalid array index\n");
									  				}
									  			
									  				if($3->Gentry->TYPE==BOOL_VARTYPE)
									  					yyerror("\nERR: invalid array index\n");
									  				
									  			}
								  		
									  			else  {
								  					if($3->Lentry->TYPE == TYPEDEF_VARTYPE)  {
									  					typedefdatatype = getTypeDefDataType($3);
														if(typedefdatatype->TYPE != INT_VARTYPE)
															yyerror("\nERR: invalid array index\n");
									  				}
								  					
								  					if($3->Lentry->TYPE==BOOL_VARTYPE)
								  						yyerror("\nERR: invalid array index\n");
								  				}
								  			}
								  			else  {
								  				yyerror("\nERR: Not id type right child\n");
								  			}
								  		}
								  		else  {
								  		
								  		
								  		}
								 	 }	
									  else  {
										printf("\nERR : You have not declared %s \n",$1->NAME);
							  			yyerror("");
									  }
									  $1->Ptr1 = $3;
									  $$ = $1;
								}
								
		|ID						{	
								 	lsymbol *ltemp;
								  	gsymbol *gtemp;
								  	ltemp = Llookup($1->NAME);
								  	if(!ltemp)  {
								  		gtemp = Glookup($1->NAME) ;
								  		if(gtemp)  {
								  			$1->Gentry = gtemp;
								  			
								  			if((gtemp->TYPE = TYPEDEF_VARTYPE)&&(gtemp->TYPEDEFLIST != NULL))
								  				yyerror("\nERR: Referring a typedef variable\n");
								  			
								  			if((gtemp->SIZE)>1)  {
								  				yyerror("\nERR: Invalid array index\n");
								  			}
								  		}
								  		else  {
								  			printf("\nERR: You have not declared %s \n",$1->NAME);
								  			yyerror("");
								  		}	
								  	}
								  	else  {
								  		$1->Lentry = ltemp;
								  	
								  	}
								  	$$ = $1;
								  
								}
									
		|TRUE						{	$$=$1;					}
										
		|FALSE						{	$$=$1;					}	
		
		
		;

	
endif:		ELSE StmtList ENDIF 				{ 	$$=$2; 					}
									
		| ENDIF 					{ 	$$=NULL; 				}
		;	

Stmt:		READ '(' ID '[' expr ']' ')'			{			
								  	gsymbol *gtemp;
								  	tdatatype *typedefdatatype;
								  	
								  	gtemp = Glookup($3->NAME);
								  	if(gtemp)  {
								  		$3->Gentry = gtemp;
								  		
								  		
								  		
								  		if(gtemp->TYPE == TYPEDEF_VARTYPE)  {
								  		
								  			yyerror("\nERR: Reading a typedef variable\n");
								  			
								  		}
								  		
								  		
								  		if($3->Gentry->TYPE==BOOL_VARTYPE)  {
								  		       printf("\nERR : Trying to read value for boolean variable %s \n",$3->NAME);
							  			       yyerror("");
								  		}
								  		if($5->TYPE==BOOLEAN_TYPE)
								  			yyerror("\nERR: invalid array index\n");
								  		else if(($5->TYPE==VOID_TYPE) && ($5->NODETYPE==ID_NODETYPE))  {
								  	
								  			if($5->Gentry)  {
								  				
								  				if($5->Gentry->TYPE == TYPEDEF_VARTYPE)  {
									  				typedefdatatype = getTypeDefDataType($5);
													if(typedefdatatype->TYPE != INT_VARTYPE)
														yyerror("\nERR: invalid array index\n");
									  			}
								  		
								  				if($5->Gentry->TYPE==BOOL_VARTYPE)
								  					yyerror("\nERR: invalid array index\n");
								  			}
								  		
								  			else  {
								  				
								  				if($5->Lentry->TYPE == TYPEDEF_VARTYPE)  {
									  				typedefdatatype = getTypeDefDataType($5);
													if(typedefdatatype->TYPE != INT_VARTYPE)
														yyerror("\nERR: invalid array index\n");
									  			}
								  				
								  				if($5->Lentry->TYPE==BOOL_VARTYPE) 
								  					yyerror("\nERR: invalid array index\n");
								  			}
								  		}
								  	}	
								  	else  {
										printf("\nERR: You have not declared %s \n",$3->NAME);
							  			yyerror("");
								  	}
								  	$3->Ptr1 = $5;
								  	$1->Ptr1 = $3;
								  	$$ = $1;
								  
								}
								

		|READ '(' ID ')'				{	
								  	lsymbol *ltemp;
								  	gsymbol *gtemp;
								  	ltemp = Llookup($3->NAME);
								  	if(!ltemp)  {
								  		gtemp = Glookup($3->NAME) ;
								  		if(gtemp)  {
								  		
								  			if(gtemp->TYPE = TYPEDEF_VARTYPE)
								  				yyerror("\nERR: Reading a typedef variable\n");
								  			
								  			$3->Gentry = gtemp;
								  			if((gtemp->SIZE)>1)  {
								  				yyerror("\nERR: Invalid array index\n");
								  			}
								  			if(gtemp->TYPE!=INT_VARTYPE)  {
							  				 printf("ERR : Trying to read value for boolean variable %s \n",$3->NAME);
							  					yyerror("");	
									 	 	}
								  		}
								  		else  {
								  			printf("\nERR: You have not declared %s ",$3->NAME);
								  			yyerror("\n");
								  		}
								  	}
								  	else  {
								  		$3->Lentry = ltemp;
								  		if($3->Lentry->TYPE!=INT_VARTYPE)  {
							  			       printf("\nERR : Trying to read value for boolean variable %s \n",$3->NAME);
							  				yyerror("");	
									  	}
								  	}
								 	$1->Ptr1 = $3;
								 	$$ = $1;
								}
								
		|READ '(' TypedefVar ')'			{
									tdatatype *typedefdatatype;
									typedefdatatype = getTypeDefDataType($3);
									if(typedefdatatype->TYPE != INT_VARTYPE)
										yyerror("\nTrying to read value for invalid datatype\n");
									
									$1->Ptr1 = $3;
									$$ = $1;
									
								}
		
		|WRITE '(' expr ')'				{	
									tdatatype *typedefdatatype;
									if($3->TYPE==BOOLEAN_TYPE)  
							  	  		yyerror("ERR: Writing boolean value\n");
			  						if($3->TYPE==VOID_TYPE)  {
									  	if($3->NODETYPE==ID_NODETYPE)  {
									  		if($3->Lentry)  {
									  		
									  			if($3->Lentry->TYPE == TYPEDEF_VARTYPE)  {
									  				typedefdatatype = getTypeDefDataType($3);
													if(typedefdatatype->TYPE != INT_VARTYPE)
														yyerror("\nERR: Writing invalid value\n");
									  			}
									  		
												if($3->Lentry->TYPE==BOOL_VARTYPE)  {
													yyerror("ERR: Writing boolean value\n");
												}
											}
											else if($3->Gentry)  {
											
										       if(($3->Gentry->TYPE = TYPEDEF_VARTYPE)&&($3->Gentry->TYPEDEFLIST != NULL))
								  					yyerror("\nERR: Referring a typedef variable\n");
											
												if($3->Gentry->TYPE == TYPEDEF_VARTYPE)  {
								  					typedefdatatype = getTypeDefDataType($3);
													if(typedefdatatype->TYPE != INT_VARTYPE)
														yyerror("\nERR: Writing invalid value\n");
									  			}
											
												if($3->Gentry->TYPE==BOOL_VARTYPE)  {
												
													yyerror("ERR: writing boolean value\n");
												}
											}
										}
									}
									$1->Ptr1=$3;
							  		$$ = $1;
								
								}
								
		|IF '(' expr ')' THEN StmtList endif		{	
									checktype($3,$1,NULL);
									$1->Ptr1=$3;
									$1->Ptr2=$6;
									$1->Ptr3=$7;
									$$=$1;
		
								}
								
		|WHILE '(' expr ')' DO StmtList ENDWHILE	{	
									checktype($3,$1,NULL);
									$1->Ptr1=$3;
									$1->Ptr2=$6;
									$$=$1;
								}
								
		|TypedefVar '=' expr				{	//printf("\nCALLING CHECKTYPE\n");
									checktype($1,$2,$3);
								  	$2->Ptr1 = $1;
								  	$2->Ptr2 = $3;
								  	$$ = $2;
		
								}
								
		|ID '[' expr ']' '=' expr			{	
									gsymbol *gtemp;
									tdatatype *typedefdatatype;
									
								 	gtemp = Glookup($1->NAME);
									if(gtemp)  {
								  		$1->Gentry = gtemp;
								  		
								  		if((gtemp->TYPE = TYPEDEF_VARTYPE)&&(gtemp->TYPEDEFLIST != NULL))
								  				yyerror("\nERR: Referring a typedef variable\n");
								  	
								  		if($3->TYPE==BOOLEAN_TYPE)
								  			yyerror("ERR: invalid array index\n");
								  		else if (($3->TYPE==VOID_TYPE) && ($3->NODETYPE=ID_NODETYPE))  {
								  	
								  			if($3->Gentry)  {
								  			
								  				if($3->Gentry->TYPE == TYPEDEF_VARTYPE)  {
									  				typedefdatatype = getTypeDefDataType($3);
													if(typedefdatatype->TYPE != INT_VARTYPE)
														yyerror("\nERR: invalid array index\n");
									  			}
									  				
								  				if($3->Gentry->TYPE==BOOL_VARTYPE)
								  					yyerror("\nERR: invalid array index\n");
								  			}
								  		
								  			else  {
								  			if($3->Lentry->TYPE==BOOL_VARTYPE)
								  				yyerror("\nERR: invalid array index\n");
								  			}
									  	}
								  	
									  }	
									  else  {
										printf("\nERR: You have not declared %s ",$1->NAME);
							  			yyerror("\n");
									  }
								  
								 	checktype($1,$5,$6);
								  	$1->Ptr1 = $3;
								  	$5->Ptr1 = $1;
								  	$5->Ptr2 = $6;
								  	$$ = $5;
									
								}
								
		|ID '=' expr					{	
								 	lsymbol *ltemp;
								  	gsymbol *gtemp;
								  	ltemp = Llookup($1->NAME);
								  	if(!ltemp)  {
								  		gtemp = Glookup($1->NAME) ;
								  		
								  		if(gtemp)  {
								  			$1->Gentry = gtemp;
								  			if((gtemp->SIZE)>1)  {
								  				yyerror("\nERR: Invalid array index\n");
								  			}
								  		
								  		}
								  		else  {
								  			printf("\nERR: You have not declared %s\n ",$1->NAME);
								  			yyerror("\n");
								  		}
								  		
								  		if((gtemp->TYPE = TYPEDEF_VARTYPE)&&(gtemp->TYPEDEFLIST != NULL))
								  				yyerror("\nERR: Referring a typedef variable\n");
								  	}
								  	else  {
								  		$1->Lentry = ltemp;
								  	}
								  
								  	checktype($1,$2,$3);
								  	$2->Ptr1=$1;
								  	$2->Ptr2=$3;
								  	$$ = $2;
								
								}
		
								
		;

RetStmt:	RETURN	expr ';'				{	
									checktype($2,$1,NULL);	
									$1->Ptr1 = $2;		
									$$ = $1;
								}
		;
		
%%

int main (void) {	

	FILE *fp;
	fp = fopen("sim.asm","w");	
	fprintf(fp,"START\n");
	fprintf(fp,"MOV SP, 0\n");
	fprintf(fp,"MOV BP, 0\n");
	fclose(fp);
	yyparse();
	fp = fopen("sim.asm","a");
	fprintf(fp,"HALT\n");
	fclose(fp);
}

int yyerror (char *msg)  {
	fprintf (stderr, "%s\n", msg);
	exit(1);
}

tdatatype * getTypeDefDataType(tnode *ttemp)  {

	int bind;
	tdatatype *tdata = (tdatatype *)malloc(sizeof(tdatatype));
	tdata->BINDING = (int *)malloc(sizeof(int));
	gsymbol *gtypedeftype = NULL;
	tnode *lookahead = NULL;
	
	if(!ttemp)
		printf("\nTTEMP IS  NULL\n");
	
	if((ttemp->Gentry))  {
		gtypedeftype = ttemp->Gentry->GTypeDefType;
		bind = *(ttemp->Gentry->BINDING);
	}
	
	else  if(ttemp->Lentry){
		gtypedeftype = ttemp->Lentry->GTypeDefType;
		bind = *(ttemp->Lentry->BINDING);
	
	}
	
	int flag=0;
	Typedef *typedeflist = NULL;
	typedeflist = gtypedeftype->TYPEDEFLIST;
	
	lookahead = ttemp->Ptr4;
	if(!lookahead)  {
		
		if(ttemp->Gentry)  {
			tdata->TYPE = ttemp->Gentry->TYPE;
			tdata->GTypeDefType = ttemp->Gentry->GTypeDefType;
			tdata->SIZE = ttemp->Gentry->GTypeDefType->SIZE;
			*(tdata->BINDING) = bind;
		}
		else  {
			tdata->TYPE = ttemp->Lentry->TYPE;
			tdata->SIZE = ttemp->Lentry->GTypeDefType->SIZE;
			tdata->GTypeDefType = ttemp->Lentry->GTypeDefType;
			*(tdata->BINDING) = bind;
		}
		
		//printf("\nReturning following info for %s \n TYPE : %d \n SIZE : %d\n BINDING : %d\n", ttemp->NAME, tdata->TYPE, tdata->SIZE, *(tdata->BINDING));
		
		return(tdata);
	}
	
	while(ttemp)  {
		lookahead = ttemp->Ptr4;
		//printf(" %s ", ttemp->NAME);
		
		
		if(lookahead)  {
			flag = 0;
			while(typedeflist)  {
				
				if(typedeflist->TYPE != TYPEDEF_VARTYPE )  {
						if((strcmp(typedeflist->NAME, lookahead->NAME)==0)&&(lookahead->Ptr4 == NULL))  {
						
						}
						
						else  {	
				
							bind = bind + typedeflist->SIZE;
							printf("\nIncreasing %d for element %s\n", typedeflist->SIZE, typedeflist->NAME);
						}
				}
				
				if((strcmp(typedeflist->NAME, lookahead->NAME)==0)&&(lookahead->Ptr4 == NULL))  {
				
					tdata->TYPE = typedeflist->TYPE;
					*(tdata->BINDING) = bind;
					switch(tdata->TYPE)  {
					
						case INT_VARTYPE:	
						case BOOL_VARTYPE:	
									tdata->SIZE = 1;
									break;
						
						case TYPEDEF_VARTYPE:   tdata->SIZE = typedeflist->GTypeDefPtr->SIZE;
									break;
					
					}
					tdata->GTypeDefType = typedeflist->GTypeDefPtr;
					flag=1;
					//printf("\nRETURNUNG %d ", tdata->TYPE);
					//if(tdata->GTypeDefType)
						//printf("\nRETURNUNG %s ", tdata->GTypeDefType->NAME);
						//printf("\nReturning following info for %s \n TYPE : %d \n SIZE : %d\n BINDING : %d\n", lookahead->NAME, tdata->TYPE, tdata->SIZE, *(tdata->BINDING));
					return(tdata);
					
				}
				
				if(strcmp(typedeflist->NAME, lookahead->NAME)==0){
					flag=1;
					break;
				
				}
				
				typedeflist = typedeflist->NEXT;
			
			}
			
			if(flag == 0 )  {
				printf("\nERR: %s does not have an element %s\n", ttemp->NAME, lookahead->NAME);
				yyerror("");
			}
			
			if(lookahead->Ptr4)  {
				if(typedeflist->TYPE != TYPEDEF_VARTYPE)  {
					printf("\nERR: %s is not a typedef variable\n", lookahead->NAME);
					yyerror("");
				}
			}
		
			if(typedeflist->GTypeDefPtr)
				gtypedeftype = typedeflist->GTypeDefPtr;
			if(gtypedeftype->TYPEDEFLIST)
				typedeflist = gtypedeftype->TYPEDEFLIST;
		
		}
		
		ttemp = lookahead;
	}
	
}

void checkFunction(int datatype, char *name, argstruct *argptr2, gsymbol *gtypedeftype)  {
	gsymbol *gtemp = Glookup(name);
	fncheck *ftemp = fnhead;
	
	if(!gtemp)
		yyerror("Function undeclared");
	
	while(ftemp)  {
	
		if(ftemp->LABEL== *(gtemp->BINDING))
			yyerror("Redefinition of function");
		ftemp = ftemp->NEXT;
	}
	
	
	if((gtemp->SIZE)>0)
		yyerror("Function undeclared");
	
	if(datatype != gtemp->TYPE)
		yyerror("1.Invalid return type");
	
	
	if(datatype == TYPEDEF_VARTYPE)  {
		if((gtypedeftype->NAME)!=(gtemp->GTypeDefType->NAME))  {
			yyerror("2.Invalid return type");
		}
	}
	struct ArgStruct *argptr1 = gtemp->ARGLIST; 
	
	int flag=1;
	
	while(argptr1 && argptr2)  {
	
	
		if(strcmp(argptr1->NAME, argptr2->NAME)!=0)  {
			flag=0;
			break;
		}
		
		if(argptr1->TYPE != argptr2->TYPE)  {
			flag=0;
			break;
		}
		
		if(argptr1->PASSTYPE != argptr2->PASSTYPE)  {
		
			flag=0;
			break;
		
		}
		
		if(argptr1->GTypeDefType != argptr2->GTypeDefType)  {
		
			flag=0;
			break;
		
		}
		
		argptr1 = argptr1->NEXT;			
		argptr2 = argptr2->NEXT;
	}
	
	if(argptr1 || argptr2)
		flag=0;
	
	if(!flag)
		yyerror("Argument list did not match for function declaration");
	
	// no errors detected, add function to list of defined + declared functions
	ftemp = (fncheck *)malloc(sizeof(fncheck));
	ftemp->LABEL = *(gtemp->BINDING);
	ftemp->NEXT = NULL;	
		
	
	if(!fnhead)  {
	
		fnhead = fnlast = ftemp;	
	}
	
	else  {
	
		fnlast->NEXT = ftemp;
		fnlast = ftemp;
	}
}


void InstallArg( argstruct *arg)  {
	
	printf("\nREturn type is %d\n", Datatype);
	if(gtypedef && Datatype == TYPEDEF_VARTYPE)
		printf(" TypeDef type is %s\n", gtypedef->NAME);
	
	
	int n=0,size;
	
	if(Datatype == TYPEDEF_VARTYPE)
		size = (-3 - (gtypedef->SIZE) + 1);
	else
		size = -3;
	
	
	argstruct *argtemp;
	argtemp = arg;
	
	while(argtemp)  {
		
		if(argtemp->TYPE == TYPEDEF_VARTYPE)
			n = n+argtemp->GTypeDefType->SIZE;
		else
			n = n+1;
		
		argtemp=argtemp->NEXT;
	}
	
	printf("\nTotal size to be reserved for arguments is %d\nBase value where to start installing arguments is %d\n", n, size);
	
	while(arg)  {
	
		mem_count = size - n + 1;
		//printf("\ncalling Linstall 1 with type %d", arg->TYPE);
		Linstall(arg->NAME, arg->TYPE, arg->GTypeDefType);
		
		if(arg->TYPE == TYPEDEF_VARTYPE)
			n = n-arg->GTypeDefType->SIZE;
		else
			n=n-1;
		
		arg=arg->NEXT;
	}
	
	mem_count = 1;
}

void Arginstall(char *name, int type,int passtype, gsymbol *Gtypedef)  {
	
	argstruct *temp = arghead;
	while(temp)  {
	
		if(strcmp(name, temp->NAME)==0)
			yyerror("Variable name used multiple times in function argument");	
		temp = temp->NEXT;
	}
	
	temp = (argstruct *)malloc(sizeof(argstruct));
	temp->NAME = name;
	temp->GTypeDefType = Gtypedef;
	temp->TYPE = type;
	temp->NEXT = NULL;
	temp->PASSTYPE = passtype;
	
	if(!arghead)	{
		arghead = arglast = temp;			
	}
	
	else  {
		
		arglast->NEXT = temp;
		arglast = temp;
	
	}
}

struct Tnode *treecreate(int type,int nodetype,char *name,int value,tnode *ptr1, tnode *ptr2, tnode *ptr3,lsymbol *lentry, gsymbol *gentry, tnode *arglist, tnode *ptr4) {
	tnode *temp = (tnode *)malloc(sizeof(tnode));
	temp->TYPE = type;
	temp->NODETYPE = nodetype;
	temp->NAME = name;
	temp->VALUE = value;
	temp->Ptr1 = ptr1;
	temp->Ptr2 = ptr2;
	temp->Ptr3 = ptr3;
	temp->Ptr4 = ptr4;
	temp->Lentry = lentry;
	temp->Gentry = gentry;
	temp->ArgList = arglist;
	return(temp);
 }

lsymbol *Llookup(char *name)  {

	lsymbol *temp = lhead;
	
	while(temp)  {
		if(strcmp(name,temp->NAME)==0) 
			return temp;
		temp = temp->NEXT;
	}
	
	return NULL;
}

void checkFuncDefn() {

	int flag;
	fncheck *ftemp;
	gsymbol *gtemp = ghead; 
	while(gtemp)  {
		flag=0;
		if(gtemp->SIZE==0)  {
			ftemp = fnhead;		
			while(ftemp)  {
				if((ftemp->LABEL) == *(gtemp->BINDING))
					flag=1;
				ftemp=ftemp->NEXT;
			}
			
			if(flag==0)  {
				printf("\nERR: You have not defined the declared function %s\n",gtemp->NAME);
				yyerror(""); 
			}
		}
		gtemp=gtemp->NEXT;
	}
	return;
}

void checktype(tnode *t1,tnode *t2,tnode *t3) {
	int flag = 1; int type;
	tdatatype *typedefdatatype;
	tdatatype *typedefdatatype_2;
	switch(t2->TYPE)  {
	
		case INT_TYPE  :  
				  switch(t2->NODETYPE)  {
				  	case PLUS_NODETYPE   :
				  	case MINUS_NODETYPE  :
				  	case MULT_NODETYPE   :
				  	case DIV_NODETYPE    :
				  	case MODULO_NODETYPE :
								  if((t1->TYPE==BOOLEAN_TYPE)||(t3->TYPE==BOOLEAN_TYPE))
								  	flag=0;
				  	
								  if(t1->TYPE==VOID_TYPE)  {
								  	if(t1->Lentry!=NULL)  {
								  		if(t1->Lentry->TYPE == TYPEDEF_VARTYPE)  {
								  			//printf("\ncalling getTypeDefDataType 1\n");
											typedefdatatype = getTypeDefDataType(t1);
											if(typedefdatatype->TYPE != INT_VARTYPE)
												flag=0;
								  		
								  		}
								  		
								  		else if(t1->Lentry->TYPE==BOOL_VARTYPE)
									  		flag=0;
									}
									else  {
										if(t1->Gentry->TYPE == TYPEDEF_VARTYPE)  {
								  		
								  			//printf("\ncalling getTypeDefDataType 2\n");
								  			typedefdatatype = getTypeDefDataType(t1);
											if(typedefdatatype->TYPE != INT_VARTYPE)
												flag=0;
								  		
								  		}
								  		
								  		else if(t1->Gentry->TYPE==BOOL_VARTYPE)
											flag=0;
									}
								  }
						  	
								  if(t3->TYPE==VOID_TYPE)  {
								  	if(t3->NODETYPE!=ID_NODETYPE)
									  	flag=0;
									  	
									if(t3->Lentry)  {
										if(t3->Lentry->TYPE == TYPEDEF_VARTYPE)  {
											//printf("\ncalling getTypeDefDataType 3\n");
											typedefdatatype = getTypeDefDataType(t3);
											if(typedefdatatype->TYPE != INT_VARTYPE)
												flag=0;
								  		
								  		
								  		}
								  		
								  		else if(t3->Lentry->TYPE==BOOL_VARTYPE)
											flag=0;
									}
									
									else  {
										if(t3->Gentry->TYPE == TYPEDEF_VARTYPE)  {
								  			
								  			//printf("\ncalling getTypeDefDataType 4\n");
								  			typedefdatatype = getTypeDefDataType(t3);
											if(typedefdatatype->TYPE != INT_VARTYPE)
												flag=0;
								  		
								  		}
								  		
								  		else if(t3->Gentry->TYPE==BOOL_VARTYPE)
											flag=0;
									}
								  }
								  break;

					case ASSIGN_NODETYPE :  
								   if(t1->Lentry!=NULL)  {
								  	type=t1->Lentry->TYPE;
								  }
								  else  {
								  	type=t1->Gentry->TYPE;
								  
								  }
								  
								  if(type==TYPEDEF_VARTYPE)  {
								  	//printf("\nTYPEDEF MATCHED\n");
								  //printf("\ncalling getTypeDefDataType 5\n");	
								  typedefdatatype = getTypeDefDataType(t1);
								  	
								  	if(typedefdatatype->TYPE == INT_VARTYPE)  {
								  	
								  		if(t3->TYPE==BOOLEAN_TYPE)  {
								  			flag=0;
								  		}
								  		else if(t3->TYPE==VOID_TYPE)  {
								  			if(t3->Lentry)  {
								  		
								  				if(t3->Lentry->TYPE == TYPEDEF_VARTYPE)  {
								  					//printf("\nsencond match\n");
												//printf("\ncalling getTypeDefDataType 6\n");	
												typedefdatatype = getTypeDefDataType(t3);
													if(typedefdatatype->TYPE != INT_VARTYPE)
														flag=0;
													
								  				}
								  		
								  				if(t3->Lentry->TYPE==BOOL_VARTYPE)  {
								  					flag=0;
								  				}	
								  			}
								  			else  {
								  				if(t3->Gentry->TYPE == TYPEDEF_VARTYPE)  {
								  			
													//printf("\ncalling getTypeDefDataType 7\n");
													typedefdatatype = getTypeDefDataType(t3);
													if(typedefdatatype->TYPE != INT_VARTYPE)
														flag=0;
								  				}
								  			
								  				if(t3->Gentry->TYPE==BOOL_VARTYPE)  {
								  					flag=0;
								  				}
								  			}
								  		}
								  	
								  	}
								  	
								  	if(typedefdatatype->TYPE == BOOL_VARTYPE)  {
								  				
						  				if(t3->TYPE==INT_TYPE)  {
									  		flag=0;
									  	}
								  	
									  	else if(t3->TYPE==VOID_TYPE) {
											if(t3->Lentry) {
										
												if(t3->Lentry->TYPE == TYPEDEF_VARTYPE)  {
								  		
												//printf("\ncalling getTypeDefDataType a\n");
												typedefdatatype = getTypeDefDataType(t3);
												if(typedefdatatype->TYPE != BOOL_VARTYPE)
													flag=0;
									  			}
											
												if(t3->Lentry->TYPE==INT_VARTYPE)  {
													flag=0;
												}
											}
										
											else  {
												if(t3->Gentry->TYPE == TYPEDEF_VARTYPE)  {
								  		
									  			//printf("\ncalling getTypeDefDataType b\n");	
									  			typedefdatatype = getTypeDefDataType(t3);
													if(typedefdatatype->TYPE != BOOL_VARTYPE)
														flag=0;
									  			}
											
												if(t3->Gentry->TYPE==INT_VARTYPE)  {
													flag=0;
												}
											}  		
								  		}
								  	
								  	}
								  	
								  	if(typedefdatatype->TYPE == TYPEDEF_VARTYPE)  {
								  	
								  		if(t3->TYPE==INT_TYPE || t3->TYPE==BOOLEAN_TYPE )  {
									  		flag=0;
									  	}
									  	
									  	if(t3->TYPE==VOID_TYPE && t3->NODETYPE==ID_NODETYPE)  {
									  	
									  		if(t3->Lentry)  {
									  		
									  	      if((t3->Lentry->TYPE == INT_VARTYPE) || (t3->Lentry->TYPE == BOOL_VARTYPE)){
									  			flag=0;
									  			
									  			}
									  			else  {
									  			
									  		//printf("\ncalling getTypeDefDataType c\n");		
									  		typedefdatatype_2 = getTypeDefDataType(t3);
									  		   if(typedefdatatype->GTypeDefType != typedefdatatype_2->GTypeDefType)  {
									  		   	
									  		      		flag=0;	
									  		      		
									  		      		}
									  				
									  			}
									  		}
									  		
									  		else if(t3->Gentry)  {
									  			
									  	     if((t3->Gentry->TYPE == INT_VARTYPE) || (t3->Gentry->TYPE == INT_VARTYPE))  {
									  			flag=0;
									  			
									  			}
									  			
									  			else  {
									  			
									  		//printf("\ncalling getTypeDefDataType d\n");		
									  		typedefdatatype_2 = getTypeDefDataType(t3);
									  		   if(typedefdatatype->GTypeDefType != typedefdatatype_2->GTypeDefType)  {
									  		   	
									  		      		flag=0;	
									  		      		
									  		      		}
									  			}
									  		}
									  	
									  	}
								  	
								  	}
								  
								 }
								  
								 else if(type==INT_VARTYPE ) {
								  	if(t3->TYPE==BOOLEAN_TYPE)  {
								  		flag=0;
								  	}
								  	else if(t3->TYPE==VOID_TYPE)  {
								  		if(t3->Lentry)  {
								  		
								  			if(t3->Lentry->TYPE == TYPEDEF_VARTYPE)  {
								  		
										//printf("\ncalling getTypeDefDataType e\n");		
										typedefdatatype = getTypeDefDataType(t3);
												if(typedefdatatype->TYPE != INT_VARTYPE)
													flag=0;
								  			}
								  		
								  			if(t3->Lentry->TYPE==BOOL_VARTYPE)  {
								  				flag=0;
								  			}	
								  		}
								  		else  {
								  			if(t3->Gentry->TYPE == TYPEDEF_VARTYPE)  {
								  		
								  		//printf("\ncalling getTypeDefDataType f\n");		
								  		typedefdatatype = getTypeDefDataType(t3);
												if(typedefdatatype->TYPE != INT_VARTYPE)
													flag=0;
								  			}
								  			
								  			if(t3->Gentry->TYPE==BOOL_VARTYPE)  {
								  				flag=0;
								  			}
								  		}
								  	}
								  }
								  else if(type==BOOL_VARTYPE  ){
								  	
								  	if(t3->TYPE==INT_TYPE)  {
								  		flag=0;
								  	}
								  	
								  	else if(t3->TYPE==VOID_TYPE) {
										if(t3->Lentry) {
										
											if(t3->Lentry->TYPE == TYPEDEF_VARTYPE)  {
								  		
									//printf("\ncalling getTypeDefDataType g\n");			
									typedefdatatype = getTypeDefDataType(t3);
												if(typedefdatatype->TYPE != BOOL_VARTYPE)
													flag=0;
								  			}
											
											if(t3->Lentry->TYPE==INT_VARTYPE)  {
												flag=0;
											}
										}
										
										else  {
											if(t3->Gentry->TYPE == TYPEDEF_VARTYPE)  {
								  		
								  	//printf("\ncalling getTypeDefDataType g\n");			
								  	typedefdatatype = getTypeDefDataType(t3);
												if(typedefdatatype->TYPE != BOOL_VARTYPE)
													flag=0;
								  			}
											
											if(t3->Gentry->TYPE==INT_VARTYPE)  {
												flag=0;
											}
										}  		
								  	}
								  }
								
								  break;
				  }
		
				  break;
		case BOOLEAN_TYPE :
				  switch(t2->NODETYPE)  {
				  
				  	case LT_NODETYPE  :
				  	case LE_NODETYPE  :
				  	case GT_NODETYPE  :
				  	case GE_NODETYPE  :
				  	case EQ_NODETYPE  :
				  	case NE_NODETYPE  :
				  			     if((t1->TYPE==BOOLEAN_TYPE)||(t3->TYPE==BOOLEAN_TYPE))
				  				flag=0;
				 	 	
					    		     if(t1->TYPE==VOID_TYPE)  {
							 	if(t1->NODETYPE!=ID_NODETYPE)
							     		flag=0;
							     	
							     	if(t1->Lentry)  {
							     		
							     		if(t1->Lentry->TYPE == TYPEDEF_VARTYPE)  {
								  		
										//printf("\n1CALLING CHECKTYPE\n");
									//printf("\ncalling getTypeDefDataType i\n");	
									typedefdatatype = getTypeDefDataType(t1);
										if(typedefdatatype->TYPE != INT_VARTYPE)
											flag=0;
								  	}
								  		
								  	else if(t1->Lentry->TYPE==BOOL_VARTYPE)
							     			flag=0;
							     	}
							     	
							     	else  {
							     		if(t1->Gentry->TYPE == TYPEDEF_VARTYPE)  {
								  		
							  			//printf("\n2CALLING CHECKTYPE\n");
							  		//printf("\ncalling getTypeDefDataType j\n");	
							  		typedefdatatype = getTypeDefDataType(t1);
										if(typedefdatatype->TYPE != INT_VARTYPE)
											flag=0;
							  		}
							  		
							  		else if(t1->Gentry->TYPE==BOOL_VARTYPE)
							     			flag=0;
							     	}
					  		     }
					  		     
				  			     if(t3->TYPE==VOID_TYPE)  {
				  				if(t3->NODETYPE!=ID_NODETYPE)
							     		flag=0;
							     	
							     	if(t3->Lentry)  {
							     		
							     		if(t3->Lentry->TYPE == TYPEDEF_VARTYPE)  {
								  		//printf("\n3CALLING CHECKTYPE\n");
									//printf("\ncalling getTypeDefDataType k\n");	
									typedefdatatype = getTypeDefDataType(t3);
										if(typedefdatatype->TYPE != INT_VARTYPE)
											flag=0;
								  	}
								  		
								  	else if(t3->Lentry->TYPE ==BOOL_VARTYPE)
							     			flag=0;
							     	}
							     	
							     	else  {
							     		if(t3->Gentry->TYPE == TYPEDEF_VARTYPE)  {
								  			
								  		//printf("\n4CALLING CHECKTYPE\n");
								  		typedefdatatype = getTypeDefDataType(t3);
										if(typedefdatatype->TYPE != INT_VARTYPE)
										flag=0;
								  	}
								  		
								  	else if(t3->Gentry->TYPE == BOOL_VARTYPE)
							     			flag=0;
							     	}
		     					     }
		     					     break;
				  	
				  	case AND_NODETYPE :
				  	case OR_NODETYPE  :
				  			     if((t1->TYPE==INT_TYPE)||(t3->TYPE==INT_TYPE))
				  			     	flag = 0;
				  			     	
				  			     if(t1->TYPE==VOID_TYPE)  {
								if(t1->NODETYPE!=ID_NODETYPE)
							     		flag=0;
							     		
							     	if(t1->Lentry)  {
							     		
							     		if(t1->Lentry->TYPE == TYPEDEF_VARTYPE)  {
								  		//printf("\ncalling getTypeDefDataType l\n");
										typedefdatatype = getTypeDefDataType(t1);
										if(typedefdatatype->TYPE != BOOL_VARTYPE)
											flag=0;
								  	}
								  		
								  	else if(t1->Lentry->TYPE == INT_VARTYPE)
								     		flag=0;
							     	}
							     	else  {
							     		if(t1->Gentry->TYPE == TYPEDEF_VARTYPE)  {
								  		//printf("\ncalling getTypeDefDataType m\n");
							  			typedefdatatype = getTypeDefDataType(t1);
										if(typedefdatatype->TYPE != BOOL_VARTYPE)
											flag=0;
							  		}
							  		
							  		else if(t1->Gentry->TYPE == INT_VARTYPE)
							     			flag=0;
							     	}
							     }
					  	
				  			     if(t3->TYPE==VOID_TYPE)  {
				  				if(t3->NODETYPE!=ID_NODETYPE)
							     		flag=0;
							     		
							     	if(t3->Lentry)  {
								     	if(t3->Lentry->TYPE == TYPEDEF_VARTYPE)  {
								  		//printf("\ncalling getTypeDefDataType n\n");
										typedefdatatype = getTypeDefDataType(t3);
										if(typedefdatatype->TYPE != BOOL_VARTYPE)
											flag=0;
								  	}
								  		
								  	else if(t3->Lentry->TYPE == INT_VARTYPE)
								     		flag=0;
							     	}
							     	else  {
							     		if(t3->Gentry->TYPE == TYPEDEF_VARTYPE)  {
								  			//printf("\ncalling getTypeDefDataType o\n");
								  		typedefdatatype = getTypeDefDataType(t3);
										if(typedefdatatype->TYPE != BOOL_VARTYPE)
										flag=0;
								  	}
								  		
								  	else if(t3->Gentry->TYPE == INT_VARTYPE)
							     			flag=0;
							     	}
		     					     }
		     					     break;
		     					     
		     			case NOT_NODETYPE  :
		     						if(t1->TYPE==INT_TYPE)
		     							flag=0;
		     						if(t1->TYPE==VOID_TYPE)  {
		     						
		     							if(t1->NODETYPE!=ID_NODETYPE)  {
		     								flag=0;
		     							}
		     							
		     							else {
		     							
		     								if(t1->Lentry)  {
		     								
		     									if(t1->Lentry->TYPE == TYPEDEF_VARTYPE)  {
								  		//printf("\ncalling getTypeDefDataType p\n");
												typedefdatatype = getTypeDefDataType(t1);
												if(typedefdatatype->TYPE != BOOL_VARTYPE)
												flag=0;
								  			}
								  		
								  			else if(t1->Lentry->TYPE == INT_VARTYPE)
		     										flag=0;
		     								}
		     								
		     								else if(t1->Gentry)  {
		     									if(t1->Gentry->TYPE == TYPEDEF_VARTYPE)  {
								  		//printf("\ncalling getTypeDefDataType q\n");
							  					typedefdatatype = getTypeDefDataType(t1);
												if(typedefdatatype->TYPE != BOOL_VARTYPE)
													flag=0;
							  				}
							  		
							  				else if(t1->Gentry->TYPE == INT_VARTYPE)
		     										flag=0;
		     								}
		     							}
		     						}
		     						break;
				  }	
				  
				  break;
				  
		case VOID_TYPE  	  :
				  switch(t2->NODETYPE)  {
					
					case ID_NODETYPE   :	
					
								if(t2->Gentry->SIZE==0)  {  // implies function
									int flag=1;
									tnode *ptr1 = t1;
									argstruct *ptr2 = t2->Gentry->ARGLIST;
									
									while(ptr1 && ptr2)  {
									
										if(ptr2->PASSTYPE==PASSBYREF)  {
										
											if(ptr1->TYPE==INT_TYPE || ptr1->TYPE==BOOLEAN_TYPE)
												flag=0;
											
											if(ptr1->TYPE==VOID_TYPE)  {
											
												if(ptr1->NODETYPE==ID_NODETYPE)  {
												
													if(ptr1->Gentry)  {
													
														if(ptr1->Gentry->SIZE == 0)
															flag=0;
													
													}
												
												}
											}
										}
									
									
										if(ptr2->TYPE==INT_VARTYPE)  {
										
											if(ptr1->TYPE==BOOLEAN_TYPE)
												flag=0;
											else if(ptr1->TYPE==VOID_TYPE)  {
											
												if(ptr1->NODETYPE==ID_NODETYPE)  {
												
													if(ptr1->Lentry)  {
													
														if(ptr1->Lentry->TYPE == TYPEDEF_VARTYPE)  {
								  							//printf("\ncalling getTypeDefDataType r	\n");
														       typedefdatatype = getTypeDefDataType(ptr1);
															if(typedefdatatype->TYPE != INT_VARTYPE)
																flag=0;
											  			}
														
													
														if(ptr1->Lentry->TYPE==BOOL_VARTYPE)
															flag=0;
													
													}
													
													else if(ptr1->Gentry)  {
														
														if(ptr1->Gentry->TYPE == TYPEDEF_VARTYPE)  {
								  							//printf("\ncalling getTypeDefDataType s\n");
							  							       typedefdatatype = getTypeDefDataType(ptr1);
															if(typedefdatatype->TYPE != INT_VARTYPE)
																flag=0;
							  							}
														
														if(ptr1->Gentry->TYPE==BOOL_VARTYPE)
															flag=0;
													}
													
													else
														flag=0;
												
												}

												else
													flag=0;
											}
										}
										
										else if(ptr2->TYPE== BOOL_VARTYPE)  {
										
											if(ptr1->TYPE==INT_TYPE)
												flag=0;
											else if(ptr1->TYPE==VOID_TYPE)  {
											
												if(ptr1->NODETYPE==ID_NODETYPE)  {
												
													
													if(ptr1->Lentry)  {
													
														if(ptr1->Lentry->TYPE == TYPEDEF_VARTYPE)  {
								  							//printf("\ncalling getTypeDefDataType t\n");
														       typedefdatatype = getTypeDefDataType(ptr1);
															if(typedefdatatype->TYPE != BOOL_VARTYPE)
																flag=0;
											  			}
													
													
														if(ptr1->Lentry->TYPE==INT_VARTYPE)
															flag=0;
													
													}
													
													else if(ptr1->Gentry)  {
													
														if(ptr1->Gentry->TYPE == TYPEDEF_VARTYPE)  {
								  							//printf("\ncalling getTypeDefDataType u\n");
							  							       typedefdatatype = getTypeDefDataType(ptr1);
															if(typedefdatatype->TYPE != BOOL_VARTYPE)
																flag=0;
							  							}
													
														if(ptr1->Gentry->TYPE==INT_VARTYPE)
															flag=0;
													}
													
													else
														flag=0;
												
												}
												
												else
													flag=0;
											}
											
											else
												flag=0;
										}
										
										else if(ptr2->TYPE== TYPEDEF_VARTYPE)  {
										
											if(ptr1->TYPE == INT_TYPE || ptr1->TYPE == BOOLEAN_TYPE)  
												flag=0;
										
											if(ptr1->NODETYPE==ID_NODETYPE)  {
											
												if(ptr1->Lentry)  {
												
													if(ptr1->Lentry->TYPE == TYPEDEF_VARTYPE)  {
								  						//printf("\ncalling getTypeDefDataType v\n");
														typedefdatatype = getTypeDefDataType(ptr1);
														if(typedefdatatype->TYPE != TYPEDEF_VARTYPE)
															flag=0;
													   if(typedefdatatype->GTypeDefType != ptr2->GTypeDefType)
													   		flag = 0;
											  		}
													
													else
														flag = 0;
												
												}
												
												else if(ptr1->Gentry)  {
												
													if(ptr1->Gentry->TYPE == TYPEDEF_VARTYPE)  {
								  						//printf("\ncalling getTypeDefDataType w\n");
														typedefdatatype = getTypeDefDataType(ptr1);
														if(typedefdatatype->TYPE != TYPEDEF_VARTYPE)
															flag=0;
													   if(typedefdatatype->GTypeDefType != ptr2->GTypeDefType)
													   		flag = 0;
											  		}
													
													else
														flag = 0;
													
												}
											}
										
										}
										
										ptr1=ptr1->Ptr3;
										ptr2=ptr2->NEXT;
									}
									
									if(ptr1 || ptr2)
										flag=0;
									
									if(flag==0)
										yyerror("\nERR: Arguments did not match\n");
								
								}
					
								break;
				  	case IF_NODETYPE   :  
				  			     if(t1->TYPE==INT_TYPE)	
				  			     	flag=0;
				  			     if(t1->TYPE==VOID_TYPE)  {
				  			     	if(t1->NODETYPE!=ID_NODETYPE)
							     		flag=0;
							     	if(t1->Lentry)  {
							     		if(t1->Lentry->TYPE == TYPEDEF_VARTYPE)  {
								  		//printf("\ncalling getTypeDefDataType x\n");
										typedefdatatype = getTypeDefDataType(t1);
										if(typedefdatatype->TYPE != BOOL_VARTYPE)
											flag=0;
								  	}
								  		
								  	else if(t1->Lentry->TYPE == INT_VARTYPE)
							     			flag=0;
							     	}
							     	
							     	else {
							     		if(t1->Gentry->TYPE == TYPEDEF_VARTYPE)  {
								  		//printf("\ncalling getTypeDefDataType y\n");
							  			typedefdatatype = getTypeDefDataType(t1);
										if(typedefdatatype->TYPE != BOOL_VARTYPE)
											flag=0;
							  		}
							  		
							  		else if(t1->Gentry->TYPE == INT_VARTYPE)
							     			flag=0;
							     	}
							     }
				  			     break;
				  	case WHILE_NODETYPE:
				  			     if(t1->TYPE==INT_TYPE)	
				  			     	flag=0;
				  			     if(t1->TYPE==VOID_TYPE)  {
				  			     	if(t1->NODETYPE!=ID_NODETYPE)
							     		flag=0;
							     	if(t1->Lentry)  {
							     		if(t1->Lentry->TYPE == TYPEDEF_VARTYPE)  {
								  		//printf("\ncalling getTypeDefDataType z\n");
										typedefdatatype = getTypeDefDataType(t1);
										if(typedefdatatype->TYPE != BOOL_VARTYPE)
											flag=0;
								  	}
								  		
								  	else if(t1->Lentry->TYPE == INT_VARTYPE)
							     			flag=0;
							     	}
							     	else {
							     	
							     		if(t1->Gentry->TYPE == TYPEDEF_VARTYPE)  {
								  		//printf("\ncalling getTypeDefDataType 1a\n");
							  			typedefdatatype = getTypeDefDataType(t1);
										if(typedefdatatype->TYPE != BOOL_VARTYPE)
											flag=0;
							  		}
							  		
							  		else if(t1->Gentry->TYPE == INT_VARTYPE)
							     			flag=0;
							     	}
							     }
				  			     break;
				  			     
				  	case RETURN_NODETYPE :
				  				if(Datatype == INT_VARTYPE)  {
				  				
				  					if(t1->TYPE==BOOLEAN_TYPE)  {
				  						flag = 0;
				  					}
				  					if(t1->TYPE==VOID_TYPE)  {
				  						if(t1->NODETYPE!=ID_NODETYPE)  {
				  							flag = 0;
				  						}
				  						if(t1->Lentry)  {
				  						
				  							if(t1->Lentry->TYPE == TYPEDEF_VARTYPE)  {
								  				//printf("\ncalling getTypeDefDataType 1b\n");
												typedefdatatype = getTypeDefDataType(t1);
												if(typedefdatatype->TYPE != INT_VARTYPE)
													flag=0;
								  			}
								  		
								  			else if(t1->Lentry->TYPE == BOOL_VARTYPE)  {
												flag=0;					  		
					  						}
				  						}
				  						else {
				  							if(t1->Gentry->TYPE == TYPEDEF_VARTYPE)  {
								  				//printf("\ncalling getTypeDefDataType 1c\n");
							  					typedefdatatype = getTypeDefDataType(t1);
												if(typedefdatatype->TYPE != INT_VARTYPE)
													flag=0;
							  				}
							  		
							  				else if(t1->Gentry->TYPE == BOOL_VARTYPE)
				  								flag=0;
				  						}
				  					}
				  				}
				  				
				  				
				  				else  {
				  				
					  				if(Datatype == BOOL_VARTYPE)  {
					  				
					  					if(t1->TYPE==INT_TYPE)  {
				  							flag = 0;
				  						}
				  						if(t1->TYPE==VOID_TYPE)  {
				  							if(t1->NODETYPE!=ID_NODETYPE)  {
				  								flag = 0;
				  							}
				  							if(t1->Lentry)  {
					  							
					  							if(t1->Lentry->TYPE == TYPEDEF_VARTYPE)  {
								  					//printf("\ncalling getTypeDefDataType 1d\n");
													typedefdatatype = getTypeDefDataType(t1);
													if(typedefdatatype->TYPE != BOOL_VARTYPE)
														flag=0;
								  				}
								  		
								  				else 
					  								if(t1->Lentry->TYPE == INT_VARTYPE)  {
														flag=0;					  		
					  							}
				  							}
				  							else {
				  								if(t1->Gentry->TYPE == TYPEDEF_VARTYPE)  {
								  				//printf("\ncalling getTypeDefDataType 1e\n");
							  					typedefdatatype = getTypeDefDataType(t1);
												if(typedefdatatype->TYPE != BOOL_VARTYPE)
													flag=0;
							  					}
							  		
							  					else if(t1->Gentry->TYPE == INT_VARTYPE)
				  									flag=0;
				  							}
				  						}
					  				}
				  					if(Datatype == TYPEDEF_VARTYPE)  {
					  					
					  					if((t1->TYPE==INT_TYPE) || (t1->TYPE==BOOLEAN_TYPE))  {
				  							flag = 0;
				  						}
					  					if(t1->TYPE==VOID_TYPE)  {
					  						if(t1->Lentry)  {
					  					
					  							if((t1->Lentry->TYPE == INT_VARTYPE) || (t1->Lentry->TYPE == BOOL_VARTYPE))  
													flag=0;	
					  						
					  							else if(t1->Lentry->TYPE == TYPEDEF_VARTYPE)  {
					  								//printf("\ncalling getTypeDefDataType 1f\n");
					  								typedefdatatype = getTypeDefDataType(t1);
					  								if(gtypedef != typedefdatatype->GTypeDefType)
					  									flag=0;
					  						
					  							}	
					  						}
					  						
					  						else if(t1->Gentry)  {
					  						
					  							if((t1->Gentry->TYPE == INT_VARTYPE) || (t1->Gentry->TYPE == BOOL_VARTYPE))  
													flag=0;	
													
					  							else if(t1->Gentry->TYPE == TYPEDEF_VARTYPE)  {
					  								//printf("\ncalling getTypeDefDataType 1g\n");
					  								typedefdatatype = getTypeDefDataType(t1);
					  								if(gtypedef != typedefdatatype->GTypeDefType)
					  									flag=0;
					  						
					  							}
					  						}
					  					}
					  				
					  				}
				  				}
				  				
				  				if(flag==0)
				  					yyerror("\nERR: Invalid return type");
				  				break;
				  }
				  break;
	}
	if(!flag)  {
		printf("ERR : Type mismatch at %d %d\n",t2->TYPE,t2->NODETYPE	);
		yyerror("");
	}
}

void Linstall(char *name,int type, gsymbol *gtypedeftype)  {

	lsymbol *temp;
	temp = Llookup(name);
	if(temp)  {
		printf("\nERR: You have already declared %s \n",name);
		yyerror("");
	}
	else   {
		temp = (lsymbol *)malloc(sizeof(lsymbol));
		temp->NAME = name;
		temp->TYPE = type;
		temp->GTypeDefType = gtypedeftype;
		temp->BINDING = (int *)malloc(sizeof(int));
		*(temp->BINDING) = mem_count;
		
		printf("\nInstalling %s at binding %d\n", name, mem_count);
		
		if(type == TYPEDEF_VARTYPE)  {
		
			mem_count = mem_count + gtypedeftype->SIZE;
		
		}
		
		else
			mem_count = mem_count + 1;
			
		temp->NEXT = NULL;
		
		if(lhead==NULL)  
			lhead = llast = temp;		 
		else  {
			llast->NEXT = temp;
			llast = temp;
		}
	}
}

int traverse(tnode *temp)  {
	
	int temp_label;
	tdatatype *typedefdatatype;
	int reg_count;
	gsymbol *gtemp = NULL;
	int i,count = 0;
	FILE *fp;
	
	if(temp)  {
		
		switch(temp->TYPE)  {
		
			case DUMMY_TYPE  : 	traverse(temp->Ptr1);
						traverse(temp->Ptr2);
						break;
		
			case VOID_TYPE    : 
				switch(temp->NODETYPE)  {
					  	
					case READ_NODETYPE : 	
								
								fp = fopen("sim.asm","a");
								fprintf(fp,"IN R%d\n",regcount);
								regcount++;
								
								if(temp->Ptr1->Gentry)  {
									if(temp->Ptr1->Gentry->TYPE == TYPEDEF_VARTYPE)  {
										//printf("\ncalling getTypeDefDataType 1h\n");
										typedefdatatype = getTypeDefDataType(temp->Ptr1);
										fprintf(fp, "MOV R%d, %d\n", regcount, *(typedefdatatype->BINDING));
										regcount++;
									
									}
										
									else if((temp->Ptr1->Gentry->SIZE)>1)  {
										
										fprintf(fp,"MOV R%d, %d\n",regcount, *(temp->Ptr1->Gentry->BINDING));
										regcount++;
										
										fclose(fp);
										traverse(temp->Ptr1->Ptr1);
										// THE LAST REGISTER WOULD CONTAIN ARRAY INDEX
										
										fp = fopen("sim.asm","a");
										
										fprintf(fp,"ADD R%d, R%d\n",regcount-2,regcount-1);
										
										regcount--;
										
									}
											
									else  {
										fprintf(fp,"MOV R%d, %d\n", regcount, *(temp->Ptr1->Gentry->BINDING));
										regcount++;
									}
											
								}
								else if(temp->Ptr1->Lentry)  {
								
									fprintf(fp,"MOV R%d, BP\n",regcount);
									regcount++;
									
									if(temp->Ptr1->Lentry->TYPE == TYPEDEF_VARTYPE)  {
										//printf("\ncalling getTypeDefDataType 1i\n");
										typedefdatatype = getTypeDefDataType(temp->Ptr1);
										fprintf(fp, "MOV R%d, %d\n", regcount, *(typedefdatatype->BINDING));
										regcount++;
									}
									
									else  {
										
										fprintf(fp,"MOV R%d, %d\n", regcount, *(temp->Ptr1->Lentry->BINDING));
										regcount++;
									
									}
									
									fprintf(fp,"ADD R%d, R%d\n", regcount-2, regcount-1);
									regcount--;
									
											
								}
								else
									printf("\nERR: No memory allocated for var");
										
								
								fprintf(fp,"MOV [R%d], R%d\n",regcount-1, regcount-2);
								regcount = regcount-2;
								
								fclose(fp);
								break;
							
					case WRITE_NODETYPE:    
								
								traverse(temp->Ptr1);

								fp = fopen("sim.asm","a");
								fprintf(fp,"OUT R%d\n",regcount-1);
								regcount--;
								fclose(fp);
								break;
										
					case ID_NODETYPE:	
								
								count = 0;
								if(temp->Gentry)  {
									printf("\nID %s with size %d CALLED", temp->NAME, temp->Gentry->SIZE);
									if(temp->Gentry->TYPE == TYPEDEF_VARTYPE && temp->Gentry->SIZE != 0)  {
										printf("\nhere 127\n");
										fp = fopen("sim.asm","a");
										//printf("\ncalling getTypeDefDataType 1j\n");
										typedefdatatype = getTypeDefDataType(temp);
										
										if(typedefdatatype->TYPE == TYPEDEF_VARTYPE)  {
										
											for(i=0;i<typedefdatatype->SIZE;i++)  {
												count++;
											    fprintf(fp, "MOV R%d, %d\n", regcount, *(typedefdatatype->BINDING)+i);
												regcount++;
											
											}
										
										}
										
										else  {
											count++;
											fprintf(fp, "MOV R%d, %d\n", regcount, *(typedefdatatype->BINDING));
											regcount++;
										
										}
										
										fclose(fp);
									
									}
									
									else if((temp->Gentry->SIZE)>1)  {
										printf("\nhere 312\n");
										fp = fopen("sim.asm","a");
										count++;
										fprintf(fp,"MOV R%d, %d\n",regcount, *(temp->Gentry->BINDING));
										regcount++;
										fclose(fp);
										
										
										traverse(temp->Ptr1);
										// now regcount-1 stores the array index
										
										fp = fopen("sim.asm","a");
										fprintf(fp,"ADD R%d, R%d\n",regcount-2,regcount-1);
										regcount--;
										fclose(fp);
										
									}
									else if((temp->Gentry->SIZE)==1) {
										fp = fopen("sim.asm","a");
										count++;
										fprintf(fp,"MOV R%d, %d\n", regcount, *(temp->Gentry->BINDING));
										regcount++;
										fclose(fp);
									}
									
									else if((temp->Gentry->SIZE)==0)  {
										printf("\nhere 123\n");
										reg_count = regcount;
										
										int i;
										fp = fopen("sim.asm","a");
										for(i=0;i<regcount;i++)  {
										
											fprintf(fp,"PUSH R%d\n",i);
										
										}
										fclose(fp);
										regcount = 0;
										tnode *argtemp = temp->ArgList;
										while(argtemp)  {
											printf("\nhere 4\n");
											traverse(argtemp);
											fp = fopen("sim.asm","a");
											if((argtemp->TYPE == VOID_TYPE) && (argtemp->NODETYPE == ID_NODETYPE))  {
											
											
												if(argtemp->Gentry)  {
												
													if(argtemp->Gentry->TYPE == TYPEDEF_VARTYPE)  {
													//printf("\ncalling getTypeDefDataType 1k\n");
														typedefdatatype = getTypeDefDataType(argtemp);
														if(typedefdatatype->TYPE == TYPEDEF_VARTYPE)  {
														
															for(i=0;i<typedefdatatype->SIZE;i++)  {
															
															      fprintf(fp,"PUSH R%d\n", regcount-typedefdatatype->SIZE+i);
															
															}
															regcount = regcount - typedefdatatype->SIZE;
														}
														
														else  {
															fprintf(fp,"PUSH R%d\n",regcount-1);
															regcount--;
														}
													}
													
													else  {
														fprintf(fp,"PUSH R%d\n",regcount-1);
														regcount--;	
													}
												}
												
												else if(argtemp->Lentry)  {
												
													if(argtemp->Lentry->TYPE == TYPEDEF_VARTYPE)  {
													//printf("\ncalling getTypeDefDataType 1l\n");	
														typedefdatatype = getTypeDefDataType(argtemp);
														if(typedefdatatype->TYPE == TYPEDEF_VARTYPE)  {
														
															for(i=0;i<typedefdatatype->SIZE;i++)  {
															
															      fprintf(fp,"PUSH R%d\n", regcount-typedefdatatype->SIZE+i);
															
															}
															regcount = regcount - typedefdatatype->SIZE;
														
														}
														
														else  {
															fprintf(fp,"PUSH R%d\n",regcount-1);
															regcount--;
														}
													}
													
													else  {
														fprintf(fp,"PUSH R%d\n",regcount-1);
														regcount--;	
													}
												}
												
												else
													yyerror("\nsomething wrong\n");
											}
											
											else  {
											
												fprintf(fp,"PUSH R%d\n",regcount-1);
												regcount--;
											
											}
											
											fclose(fp);
											
											argtemp = argtemp->Ptr3;
										}
										printf("\nhere 1\n");
										count = 0;
										fp = fopen("sim.asm","a");
										/* PUSHING RETURN VALUE */
										if(temp->Gentry)  {
										
											if(temp->Gentry->TYPE == TYPEDEF_VARTYPE)  {
											
												for(i=0;i<(temp->Gentry->GTypeDefType->SIZE);i++)  {
													count++;
													fprintf(fp,"PUSH R%d\n",regcount);
												}
											}
											
											else {
												count++;
												fprintf(fp,"PUSH R%d\n",regcount);
											}
										}
										
										else if(temp->Lentry)  {
										
											if(temp->Lentry->TYPE == TYPEDEF_VARTYPE)  {
											
												for(i=0;i<(temp->Lentry->GTypeDefType->SIZE);i++)  {
													count++;
													fprintf(fp,"PUSH R%d\n",regcount);
												}
											}
											
											else {
												count++;
												fprintf(fp,"PUSH R%d\n",regcount);
											
											}
										
										}
										/* PUSHING RETURN VALUE */
										printf("\nhere 12\n");
										fprintf(fp,"CALL f%d\n",*(temp->Gentry->BINDING));
										fclose(fp);
										
										/*
										
										POP REMAINS !!!!!
										 
										*/
										regcount = reg_count;
										fp = fopen("sim.asm","a");
										
										for(i=0;i<count;i++)  {
										
											fprintf(fp,"POP R%d\n", regcount+count-1-i);
										
										}
										
										regcount = regcount+count;
										fclose(fp);
										
										argtemp = temp->ArgList;
										argstruct *argstructtemp;
										argstructtemp = temp->Gentry->ARGLIST;
										
										while(argstructtemp && argtemp)  {
											fp = fopen("sim.asm","a");
											count = 0;
											if(argstructtemp->TYPE == TYPEDEF_VARTYPE)  {
											
												for(i=0;i<(argstructtemp->GTypeDefType->SIZE);i++)  {
													
													count++;
													fprintf(fp,"POP R%d\n",regcount +(argstructtemp->GTypeDefType->SIZE)-i-1 );
													regcount++;	
												}
											
											}
											
											else  {
												count++;
												fprintf(fp,"POP R%d\n",regcount);
												regcount++;
											}
											
											
											if(argstructtemp->PASSTYPE == PASSBYREF)  {
												
												
												if(argtemp->Lentry)  {
												
													if(argtemp->Lentry->TYPE == TYPEDEF_VARTYPE)  {
													
														for(i=0;i<count;i++)  {
														
															fprintf(fp,"MOV R%d, %d\n", regcount, *(argtemp->Lentry->BINDING)+i);
															regcount++;
														}
													
													}
													
													else  {
														
														fprintf(fp,"MOV R%d, %d\n", regcount, *(argtemp->Lentry->BINDING));
														regcount++;
													
													}
												
													fprintf(fp,"MOV R%d, BP\n", regcount);
													regcount++;
													
													for(i=0;i<count;i++)  {
													
														fprintf(fp, "ADD R%d, R%d\n", regcount-count+i-1, regcount-1); 
													}
													regcount--;
													
												}
												
												else  {
													if(argtemp->Gentry->TYPE == TYPEDEF_VARTYPE)  {
													
														for(i=0;i<count;i++)  {
														
															fprintf(fp,"MOV R%d, %d\n", regcount, *(argtemp->Gentry->BINDING)+i);
															regcount++;
														}
													
													}
													
													else  {
													
														fprintf(fp,"MOV R%d, %d\n", regcount, *(argtemp->Gentry->BINDING));
														regcount++;
													
													}
												}
												
												for(i=0;i<count;i++)  {
												
													fprintf(fp,"MOV [R%d], R%d\n", regcount-count+i, regcount-(2*count)+i);
												
												
												}
												
												regcount=regcount-count;
											
											}
											
											regcount=regcount-count;
											
											argtemp = argtemp->Ptr3;
											argstructtemp = argstructtemp->NEXT;
											fclose(fp);
										}
										
										
										
										for(i=reg_count-1;i>=0;i--)  {
										
											fp = fopen("sim.asm","a");
											fprintf(fp,"POP R%d\n", i);
											fclose(fp);
										}
										
										regcount = reg_count+1;
										return;
									}
									
								}
								else if(temp->Lentry)  {
									
									if(temp->Lentry->TYPE == TYPEDEF_VARTYPE)  {
									
										fp = fopen("sim.asm","a");
										//printf("\ncalling getTypeDefDataType 1m\n");
										typedefdatatype = getTypeDefDataType(temp);
										
										if(typedefdatatype->TYPE == TYPEDEF_VARTYPE)  {
										
											for(i=0;i<typedefdatatype->SIZE;i++)  {
												count++;
											    fprintf(fp, "MOV R%d, %d\n", regcount, *(typedefdatatype->BINDING)+i);
												regcount++;
											
											}
										}
										
										else  {
											count++;
											fprintf(fp, "MOV R%d, %d\n", regcount, *(typedefdatatype->BINDING));
											regcount++;
										}
										
										fclose(fp);
									
									}
									else  {
										fp = fopen("sim.asm","a");
										count++;
										fprintf(fp,"MOV R%d, %d\n", regcount, *(temp->Lentry->BINDING));
										regcount++;
										fclose(fp);
									}
											
									fp = fopen("sim.asm","a");
									fprintf(fp,"MOV R%d, BP\n", regcount);
									regcount++;
									fclose(fp);		
											
											
											
									//printf("\nID called");
									fp = fopen("sim.asm","a");
									
									for(i=0;i<count;i++)  {
									
										fprintf(fp, "ADD R%d, R%d\n", regcount-2-i, regcount-1);
									
									}
									regcount--;
									
									/*
									fprintf(fp,"ADD R%d, R%d\n", regcount-2, regcount-1);
									regcount--;
									*/
									fclose(fp);
												
								}
										
								else 
									printf("\nERR: No memory allocated for var");
			
								fp = fopen("sim.asm","a");

								//fprintf(fp, "MOV R%d, [R%d]\n", regcount-1, regcount-1);
								
								for(i=0;i<count;i++)  {
								
									fprintf(fp, "MOV R%d, [R%d]\n", regcount-1-i, regcount-1-i);
								}
								

								fclose(fp);
								break;
							
					case IF_NODETYPE :
								
								traverse(temp->Ptr1);
								
								label = label + 2;
								temp_label = label;

								fp = fopen("sim.asm","a");
								
								fprintf(fp,"JZ R%d, LABEL%d\n",regcount-1,temp_label-2);
								regcount--;
								
								fclose(fp);
								
								traverse(temp->Ptr2);
								
								fp = fopen("sim.asm","a");
								fprintf(fp,"JMP LABEL%d\n",temp_label-1);
								
								fprintf(fp,"LABEL%d:\n",temp_label-2);
								fclose(fp);
								label++;
								traverse(temp->Ptr3);
								fp = fopen("sim.asm","a");
								fprintf(fp,"LABEL%d:\n",temp_label-1);
								label++;
								fclose(fp);
								break;
								
										
					case WHILE_NODETYPE : 
								fp = fopen("sim.asm","a");
								fprintf(fp,"LABEL%d:\n",label);
								label=label+2;
								temp_label = label-1;
								fclose(fp);
								
								traverse(temp->Ptr1);
								
								fp = fopen("sim.asm","a");
								fprintf(fp,"JZ R%d, LABEL%d\n",regcount-1, temp_label);
								regcount--;
								fclose(fp);
								
								traverse(temp->Ptr2);
								
								fp = fopen("sim.asm","a");
								fprintf(fp,"JMP LABEL%d\n",temp_label-1);
								fprintf(fp,"LABEL%d:\n", temp_label);
								fclose(fp);
								break;
								
									
					case RETURN_NODETYPE :	
								if(main_flag == 0) {
									traverse(temp->Ptr1);
								
									fp = fopen("sim.asm","a");
									
									fprintf(fp,"MOV R%d, BP\n",regcount);
									regcount++;
								
									fprintf(fp,"MOV R%d, -2\n",regcount);
									regcount++;
								
									fprintf(fp,"ADD R%d, R%d\n", regcount-2, regcount-1);
								
									regcount--;
								
									fprintf(fp,"MOV [R%d], R%d\n",regcount-1, regcount-2);
									regcount = regcount -2;
								
									int i;
									
									for(i=1;i<mem_count;i++)  {
										fprintf(fp,"POP R%d\n",regcount);
								
									}
									
									fprintf(fp,"POP BP\n");
									fprintf(fp,"RET\n");
									fclose(fp);
									}
								break;
			  	}
					  	break;

			case INT_TYPE	  : 
				switch(temp->NODETYPE)  {

				case NUMBER_NODETYPE: 	
							fp = fopen("sim.asm","a");
							fprintf(fp,"MOV R%d, %d\n",regcount, temp->VALUE);
							regcount++;
							fclose(fp);
							break;
					
				case PLUS_NODETYPE  :	
							traverse(temp->Ptr1);
							traverse(temp->Ptr2);
							fp = fopen("sim.asm","a");
							fprintf(fp,"ADD R%d, R%d\n", regcount-2, regcount-1);
							regcount--;
							fclose(fp);
							break;
				
				case MINUS_NODETYPE : 	
							traverse(temp->Ptr1);
							traverse(temp->Ptr2);
							fp = fopen("sim.asm","a");
							fprintf(fp,"SUB R%d, R%d\n", regcount-2, regcount-1);
							regcount--;
							fclose(fp);
							break;
				
				case MULT_NODETYPE  : 	
							traverse(temp->Ptr1);
							traverse(temp->Ptr2);
							fp = fopen("sim.asm","a");
							fprintf(fp,"MUL R%d, R%d\n", regcount-2, regcount-1);
							regcount--;
							fclose(fp);
							
							break;
				
				case DIV_NODETYPE   : 	
							fp = fopen("sim.asm","a");
							traverse(temp->Ptr1);
							traverse(temp->Ptr2);
							
							fprintf(fp,"DIV R%d, R%d\n", regcount-2, regcount-1);
							regcount--;
							
							fclose(fp);
							
							break;
				
				case ASSIGN_NODETYPE:	
							count = 0;
							if(temp->Ptr1->Lentry)  {
								fp = fopen("sim.asm","a");
								if(temp->Ptr1->Lentry->TYPE == TYPEDEF_VARTYPE)  {
								
									typedefdatatype = getTypeDefDataType(temp->Ptr1);
								
									if(typedefdatatype->TYPE == TYPEDEF_VARTYPE)  {
										
										for(i=0;i<typedefdatatype->SIZE;i++)  {
											count++;
											fprintf(fp, "MOV R%d, %d\n", regcount, *(typedefdatatype->BINDING)+i);
											regcount++;
											
										}
									}
								
									else  {
										count++;
										fprintf(fp, "MOV R%d, %d\n", regcount, *(typedefdatatype->BINDING));
										regcount++;
									}
								}
								else  {
								
									count++;
									fprintf(fp,"MOV R%d, %d\n", regcount, *(temp->Ptr1->Lentry->BINDING));
									regcount++;
								}
								
								fprintf(fp,"MOV R%d, BP\n", regcount);
								regcount++;
								
								for(i=0;i<count;i++)  {
								
									fprintf(fp, "ADD R%d, R%d\n", regcount-2-i, regcount-1);
								
								}
								regcount--;
								
								fclose(fp);
							}
							
							else if(temp->Ptr1->Gentry)  {
							
								if(temp->Ptr1->Gentry->TYPE == TYPEDEF_VARTYPE)  {
									fp = fopen("sim.asm","a");
								
									typedefdatatype = getTypeDefDataType(temp->Ptr1);
									
									if(typedefdatatype->TYPE == TYPEDEF_VARTYPE)  {
									
										for(i=0;i<typedefdatatype->SIZE;i++)  {
											count++;
											fprintf(fp, "MOV R%d, %d\n", regcount, *(typedefdatatype->BINDING)+i);
											regcount++;
											
										}
									}
									
									else  {
										count++;
										fprintf(fp, "MOV R%d, %d\n", regcount, *(typedefdatatype->BINDING));
										regcount++;
									}
									fclose(fp);
								}
								
								else  {
								
									if((temp->Ptr1->Gentry->SIZE)>1)  {
										count++;
										fp = fopen("sim.asm","a");
										fprintf(fp,"MOV R%d, %d\n", regcount, *(temp->Ptr1->Gentry->BINDING));
										regcount++;
										fclose(fp);
									
										traverse(temp->Ptr1->Ptr1);
										
										fp = fopen("sim.asm","a");
										fprintf(fp,"ADD R%d, R%d\n", regcount-2, regcount-1);
										regcount--;
										fclose(fp);
										
									}
									else  {
										count++;
										fp = fopen("sim.asm","a");
										fprintf(fp,"MOV R%d, %d\n", regcount, *(temp->Ptr1->Gentry->BINDING));
										regcount++;
										fclose(fp);
								
									}
								}
							
							}
							
							traverse(temp->Ptr2);
							
							
							fp = fopen("sim.asm","a");
							
							for(i=0;i<count;i++)  {
							
								fprintf(fp, "MOV [R%d], R%d\n", (regcount-(2*count)+i), regcount-count+i);
							}
							
							regcount=regcount-(2*count);
							
							fclose(fp);
							break;
							
				case MODULO_NODETYPE:   
							
							traverse(temp->Ptr1);
							traverse(temp->Ptr2);
							
							fp = fopen("sim.asm","a");
							fprintf(fp,"MOD R%d, R%d\n", regcount-2, regcount-1);
							regcount--;
							
							fclose(fp);
							
							break;
				}
				break;
					  
			case BOOLEAN_TYPE : 
				
				switch(temp->NODETYPE)  {
				
				case NOT_NODETYPE:	
							traverse(temp->Ptr1);
							
							fp = fopen("sim.asm","a");
							
							fprintf(fp,"MOV R%d, 1\n",regcount);
							regcount++;
							
							fprintf(fp,"MOV R%d, 2\n",regcount);
							regcount++;
							
							fprintf(fp,"ADD R%d, R%d\n", regcount-3, regcount-2);
							
							fprintf(fp,"MOD R%d, R%d\n", regcount-3, regcount-1);
							
							regcount = regcount -2 ;
							fclose(fp);
							break;
					
				case LT_NODETYPE  :	traverse(temp->Ptr1);
							traverse(temp->Ptr2);
							
							fp = fopen("sim.asm","a");
							fprintf(fp,"LT R%d, R%d\n", regcount-2, regcount-1);
							regcount--;
							fclose(fp);
							
							break;

				case LE_NODETYPE  :	traverse(temp->Ptr1);
							traverse(temp->Ptr2);
							
							fp = fopen("sim.asm","a");
							
							fprintf(fp,"LE R%d, R%d\n", regcount-2, regcount-1);
							regcount--;
							fclose(fp);
							
							break;

				case GT_NODETYPE  :	traverse(temp->Ptr1);
							traverse(temp->Ptr2);
							
							fp = fopen("sim.asm","a");
							
							fprintf(fp,"GT R%d, R%d\n", regcount-2, regcount-1);
							regcount--;
							
							fclose(fp);
							
							break;
							
				case GE_NODETYPE  :	traverse(temp->Ptr1);
							traverse(temp->Ptr2);
							
							fp = fopen("sim.asm","a");
							
							fprintf(fp,"GE R%d, R%d\n", regcount-2, regcount-1);
							regcount--;
							
							fclose(fp);
							
							break;
							
				case EQ_NODETYPE  :	traverse(temp->Ptr1);
							traverse(temp->Ptr2);
							
							fp = fopen("sim.asm","a");
							
							fprintf(fp,"EQ R%d, R%d\n", regcount-2, regcount-1);
							regcount--;
							fclose(fp);
							
							break;
							
				case NE_NODETYPE  :	traverse(temp->Ptr1);
							traverse(temp->Ptr2);
							
							fp = fopen("sim.asm","a");
							
							fprintf(fp,"NE R%d, R%d\n", regcount-2, regcount-1);
							regcount--;
							fclose(fp);
							break;
							
				case AND_NODETYPE :	traverse(temp->Ptr1);
							traverse(temp->Ptr2);
							
							fp = fopen("sim.asm","a");
							
							fprintf(fp,"MUL R%d, R%d\n", regcount-2, regcount-1);
							regcount--;
							fclose(fp);
							break;
							
				case OR_NODETYPE  :	
							traverse(temp->Ptr1);
							traverse(temp->Ptr2);

							fp = fopen("sim.asm","a");
							
							fprintf(fp,"MOV R%d, 2\n", regcount);
							regcount++;
							
							fprintf(fp,"ADD R%d, R%d\n", regcount-3, regcount-2);
							
							fprintf(fp,"MOD R%d, R%d\n", regcount-3, regcount-1);
							
							regcount = regcount - 2;

							fclose(fp);
							
							break;
							

				case TRUE_NODETYPE :    
							fp = fopen("sim.asm","a");				
							fprintf(fp,"MOV R%d, %d\n", regcount, 1);
							regcount++;
							fclose(fp);
							break;
							
				case FALSE_NODETYPE:    fp = fopen("sim.asm","a");							
							fprintf(fp,"\nMOV R%d, %d", regcount, 0);
							regcount++;
							fclose(fp);
							break;
					
					}
					break;
		}
	}
}

gsymbol *Glookup(char *name)  {  

	gsymbol *temp = ghead;
	
	while(temp)  {
		if(strcmp(name,temp->NAME)==0) 
			return temp;
		temp = temp->NEXT;
	}
	
	return NULL;
}

void Ginstall(char *name,int type,int size, int binding, argstruct *arglist ,Typedef *typedeflist, gsymbol *gtypedeftype )  {

	gsymbol *temp;
	temp = Glookup(name);
	if(temp)  {
		printf("\nERR: You have already declared %s \n",name);
		yyerror("");
	}
	else   {
		temp = (gsymbol *)malloc(sizeof(gsymbol));
		temp->NAME = name;
		temp->TYPE = type;
		temp->SIZE = size;
		temp->TYPEDEFLIST = typedeflist;
		temp->ARGLIST = arglist;
		temp->BINDING = (int *)malloc(sizeof(int));
		if(binding==0)  {
			*(temp->BINDING) = mem_count;
			mem_count = mem_count + size;
			
		}
		else  {
	
			*(temp->BINDING) = binding;		
		
		}
		temp->NEXT = NULL;
		temp->GTypeDefType = gtypedeftype;
		
		if(ghead==NULL)  
			ghead = glast = temp;		 
		else  {
			glast->NEXT = temp;
			glast = temp;
		}
	}
}

void checkTypeDefn(tnode *ttemp)  {

	gsymbol *gtypedeftype = NULL;
	tnode *lookahead = NULL;
	

	if(!(ttemp->Lentry))  {
		gtypedeftype = ttemp->Gentry->GTypeDefType;
	}
	
	else  {
		gtypedeftype = ttemp->Lentry->GTypeDefType;
	
	}
	
	int flag=0;
		
	Typedef *typedeflist = NULL;
	typedeflist = gtypedeftype->TYPEDEFLIST;
	
	while(ttemp)  {
		lookahead = ttemp->Ptr3;
		//printf(" %s ", ttemp->NAME);
		
		if(lookahead)  {
			flag=0;
			
			while(typedeflist)  {
			
				if(strcmp(typedeflist->NAME, lookahead->NAME)==0)  {
					flag=1;
					break;
				
				}
				typedeflist = typedeflist->NEXT;
			
			}
			
			if(flag==0)  {
			
				printf("\nERR: %s does not have an element %s\n", ttemp->NAME, lookahead->NAME);
				yyerror("");
			
			}
			
			if(lookahead->Ptr3)  {
				if(typedeflist->TYPE != TYPEDEF_VARTYPE)  {
					printf("\nERR: %s is not a typedef variable\n", lookahead->NAME);
					yyerror("");
				}
			}
			
			if(typedeflist->GTypeDefPtr)
				gtypedeftype = typedeflist->GTypeDefPtr;
			if(gtypedeftype->TYPEDEFLIST)
				typedeflist = gtypedeftype->TYPEDEFLIST;
		
		}
		ttemp = lookahead;
	}

	return;
}
