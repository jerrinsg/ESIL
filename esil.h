#define INT_TYPE		1
#define BOOLEAN_TYPE		2
#define VOID_TYPE		3

#define DUMMY_TYPE 		0
#define DUMMY_NODETYPE		0

#define NUMBER_NODETYPE		0
#define PLUS_NODETYPE		1
#define MINUS_NODETYPE		2
#define MULT_NODETYPE		3
#define DIV_NODETYPE		4
#define ASSIGN_NODETYPE		5
#define MODULO_NODETYPE		6

#define READ_NODETYPE		1
#define WRITE_NODETYPE		2
#define ID_NODETYPE		4
#define IF_NODETYPE		6
#define WHILE_NODETYPE		9
#define RETURN_NODETYPE		11

#define LT_NODETYPE		1
#define LE_NODETYPE		2
#define GT_NODETYPE		3
#define GE_NODETYPE		4
#define EQ_NODETYPE		5
#define NE_NODETYPE		6
#define AND_NODETYPE		7
#define OR_NODETYPE		8
#define TRUE_NODETYPE		9
#define	FALSE_NODETYPE		10
#define NOT_NODETYPE  		11

#define BOOL_VARTYPE		15
#define INT_VARTYPE		16
#define TYPEDEF_VARTYPE		17

#define PASSBYVAL		0
#define PASSBYREF		1

struct Lsymbol  {
	int TYPE;
	char *NAME;
	int *BINDING;			// Address of the Identifier in Memory
	struct Gsymbol *GTypeDefType;
	struct Lsymbol *NEXT;		// Pointer to next Symbol Table Entry 

};

struct Tnode {
	int TYPE; 
	int VALUE; 
	char* NAME; 
	int NODETYPE;
	struct Tnode *ArgList;
	struct Lsymbol *Lentry; 
	struct Gsymbol *Gentry; 
	struct Tnode *Ptr1, *Ptr2, *Ptr3, *Ptr4;
};

struct TDataType  {		// THIS STRUCTURE IS USED TO GET INFO ABOUT DATASTRUCTURE ELEMENTS
				// CONTAINS ITS TYPE AND POINTER TO THE CORRESPONDING GST IF TYPE IS TYPEDEF_VARTYPE
	int TYPE;
	int SIZE;
	int *BINDING;
	struct Gsymbol *GTypeDefType;
};

struct ArgStruct {

	int TYPE;
	char *NAME;
	int PASSTYPE;
	struct ArgStruct *NEXT;
	struct Gsymbol *GTypeDefType;
};

struct FnCheck  {

	int LABEL;
	struct FnCheck *NEXT;

};

struct TypeDef  {

	int TYPE;
	int SIZE;
	char *NAME;
	int *BINDING;
	struct TypeDef *NEXT;
	struct Gsymbol *GTypeDefPtr;

};

struct Gsymbol {

	int TYPE;
	int SIZE;
	char *NAME;
	int *BINDING; 
	struct Gsymbol *NEXT;
	struct ArgStruct *ARGLIST;
	struct TypeDef *TYPEDEFLIST;
	struct Gsymbol *GTypeDefType;
};
