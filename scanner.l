%{
#define C	300
#define V	301
#define I	302
#define F	303
#define Ch	304
#define B	305
#define S	306
#define T	307
#define X	399

%}

%%
(\/\/\ .*\n?)|(\/\*(.|\n)*\*\/) { return C; } // comentario // ou /**/
var(\ (int|fl|db|str|char|bool))?\ [A-Za-z_][A-Za-z0-9_]*       { return V; } // var
(?<![\w-])-?[1-9][0-9]*			{ return I;    } // int
(0|[1-9][0-9]*)\.[0-9]+         { return F;  } // float/double
'.'                             { return Ch;   } // char
true|false                      { return B;   } // boolean
\"([^"\\]*(\\.[^"\\]*)*)\"      { return S; } // strings
[ \n\t]+						{ return T; }
.								{ return T; }
<<EOF>>							{ return X; }

%%

int main(int argc, char *argv[])
{
	FILE *f_in;
	int tipoToken;
	int totalComment = 0,
		totalDec = 0,
		totalInt = 0,
		totalFl = 0,
		totalChar = 0,
		totalBool = 0,
		totalString = 0;

	if(argc == 2)
	{
		if(f_in == fopen(argv[1], "r"))
		{
			yyin = f_in;
		}
		else
		{
			perror(argv[0]);
		}
	}
	else
	{
		yyin = stdin;
	}

	while((tipoToken = yylex()) != X)
	{
		switch (tipoToken)
		{
			case C:
				++totalComment;
				break;
			case V:
				++totalDec;
				break;
			case I:
				++totalInt;
				break;
			case F:
				++totalFl;
				break;
			case Ch:
				++totalChar;
				break;
			case B:
				++totalBool;
				break;
			case S:
				++totalString;
				break;
		}
	}

	printf("Arquivo tem:\n");
	printf("\t %d comentarios\n", totalComment);
	printf("\t %d declaracoes de variavel\n", totalDec);
	printf("\t %d valores inteiros\n", totalInt);
	printf("\t %d valores de ponto flutuante\n", totalFl);
	printf("\t %d caracteres\n", totalChar);
	printf("\t %d boolean\n", totalBool);
	printf("\t %d string\n", totalString);
}
