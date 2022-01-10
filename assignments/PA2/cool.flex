/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{

/***************************************************************************
 * DECLARATIONS
 **************************************************************************/

#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

#ifndef max
#define max(a,b)            (((a) > (b)) ? (a) : (b))
#endif

#ifndef min
#define min(a,b)            (((a) < (b)) ? (a) : (b))
#endif

typedef enum QuoteKind {

QuoteKindNone,
QuoteKindDoubleQuotedString,
QuoteKindSingleQuotedString,
QuoteKindMultilineComment,

} QuoteKind;

static QuoteKind quoteKind = QuoteKindNone;

static char * quotedContent = NULL;
static size_t quotedContentCount = 0;
static size_t quotedContentCapacity = 0;

static void reallocateQuotedContentIfNeeded(size_t wantedCapacity);
static void appendQuotedContent(const char * substring);
static void clearQuotedContent();

void appendQuotedContent(const char * substring) {
  size_t substringLength = strlen(substring);
  size_t wanted = quotedContentCount + substringLength + 1;
  reallocateQuotedContentIfNeeded(wanted);
  strcat(quotedContent, substring);
  quotedContentCount += substringLength;
}

static void clearQuotedContent() {
  free(quotedContent);
  quotedContent = NULL;
  quotedContentCount = 0;
  quotedContentCapacity = 0;
}

void reallocateQuotedContentIfNeeded(size_t wantedCapacity) {
  if (quotedContentCapacity > wantedCapacity) {
    return;
  }

  size_t goodCapacity = max(quotedContentCapacity * 2, 1);
  while (goodCapacity < wantedCapacity) {
    goodCapacity *= 2;
  }

  if (quotedContent == NULL) {
    quotedContent = (char *)malloc(goodCapacity);
  } else {
    quotedContent = (char *)realloc(quotedContent, goodCapacity);
  }

  quotedContentCapacity = goodCapacity;
}

bool isInQuote(void) {
  return quoteKind != QuoteKindNone;
}

size_t nestedQuoteLevel = 0;

%}

DIGIT                   [0-9]
ID                      [A-Za-z_][A-Za-z0-9_]*
LEFT_PAREN              \(
RIGHT_PAREN             \)
LEFT_BRACE              \{
RIGHT_BRACE             \}
SEMICOLON               ;
COLON                   :
COMMA                   ,
MULTILINE_COMMENT_BEGIN \(\*
MULTILINE_COMMENT_END   \*\)
KEYWORDS                class|inherits|init|SELF_TYPE|self|if|then|else|fi|let|in|while|loop|pool|new
OPERATORS               <-|\.|\+|\-|\*|\/|\<|\>|\[|\]|==|=|\\

%%

{DIGIT}+  {
  if (isInQuote()) {
    appendQuotedContent(yytext);
  } else {
    printf("An integer: %s (%d)\n", yytext, atoi(yytext));
  }
}

{DIGIT}+"."{DIGIT}* {
  if (isInQuote()) {
    appendQuotedContent(yytext);
  } else {
    printf("A float: %s (%g)\n", yytext, atof(yytext));
  }
}

{SEMICOLON} {
  if (isInQuote()) {
    appendQuotedContent(yytext);
  } else {
    printf("Semicolon: %s\n", yytext);
  }
}

{COLON} {
  if (isInQuote()) {
    appendQuotedContent(yytext);
  } else {
    printf("Colon: %s\n", yytext);
  }
}

{COMMA} {
  if (isInQuote()) {
    appendQuotedContent(yytext);
  } else {
    printf("Comma: %s\n", yytext);
  }
}

{LEFT_PAREN} {
  if (isInQuote()) {
    appendQuotedContent(yytext);
  } else {
    printf("Left parenthesis: %s\n", yytext);
  }
}

{RIGHT_PAREN} {
  if (isInQuote()) {
    appendQuotedContent(yytext);
  } else {
    printf("Right parenthesis: %s\n", yytext);
  }
}

{LEFT_BRACE} {
  if (isInQuote()) {
    appendQuotedContent(yytext);
  } else {
    printf("Left brace: %s\n", yytext);
  }
}

{RIGHT_BRACE} {
  if (isInQuote()) {
    appendQuotedContent(yytext);
  } else {
    printf("Right brace: %s\n", yytext);
  }
}

{KEYWORDS} {
  if (isInQuote()) {
    appendQuotedContent(yytext);
  } else {
    printf( "A keyword: %s\n", yytext);
  }
}

{ID} {
  if (isInQuote()) {
    appendQuotedContent(yytext);
  } else {
    printf( "An identifier: %s\n", yytext );
  }
}

{OPERATORS} {
  if (isInQuote()) {
    appendQuotedContent(yytext);
  } else {
    printf("An operator: %s\n", yytext);
  }
}

[ \t]+ {
  if (isInQuote()) {
    appendQuotedContent(yytext);
  } else {
    printf("Whitespaces: \"%s\"\n", yytext);
  }
}

(\n|\n\r)+ {
  if (isInQuote()) {
    appendQuotedContent(yytext);
  } else {
    /* Only supports UNIX and Windows newline */
    printf("Newline: \"%s\"\n", yytext );
  }
}

{MULTILINE_COMMENT_BEGIN} {
  switch (quoteKind) {
    case QuoteKindNone:
      quoteKind = QuoteKindMultilineComment;
      nestedQuoteLevel += 1;
      break;
    case QuoteKindMultilineComment:
      nestedQuoteLevel += 1;
      appendQuotedContent(yytext);
      break;
    case QuoteKindSingleQuotedString:
      appendQuotedContent(yytext);
      break;
    case QuoteKindDoubleQuotedString:
      appendQuotedContent(yytext);
      break;
  }
}

{MULTILINE_COMMENT_END} {
  switch (quoteKind) {
    case QuoteKindNone:
      // ERROR: Comment ended before start.
      printf("Comment end: %s\n", yytext);
      break;
    case QuoteKindMultilineComment:
      nestedQuoteLevel -= 1;
      if (nestedQuoteLevel == 0) {
        quoteKind = QuoteKindNone;
        printf("Comment: \"(*%s*)\"\n", quotedContent);
        clearQuotedContent();
      }
      break;
    case QuoteKindSingleQuotedString:
      appendQuotedContent(yytext);
      break;
    case QuoteKindDoubleQuotedString:
      appendQuotedContent(yytext);
      break;
  }
}

"\"" {
  switch (quoteKind) {
    case QuoteKindNone:
      quoteKind = QuoteKindDoubleQuotedString;
      break;
    case QuoteKindMultilineComment:
      appendQuotedContent(yytext);
      break;
    case QuoteKindDoubleQuotedString:
      quoteKind = QuoteKindNone;
        printf("String Literal: \"%s\"\n", quotedContent);
        clearQuotedContent();
      break;
    case QuoteKindSingleQuotedString:
      appendQuotedContent(yytext);
      break;
  }
}

"\'" {
  switch (quoteKind) {
    case QuoteKindNone:
      quoteKind = QuoteKindSingleQuotedString;
      break;
    case QuoteKindMultilineComment:
      appendQuotedContent(yytext);
      break;
    case QuoteKindDoubleQuotedString:
      appendQuotedContent(yytext);
      break;
    case QuoteKindSingleQuotedString:
      quoteKind = QuoteKindNone;
        printf("String Literal: \'%s\'\n", quotedContent);
        clearQuotedContent();
      break;
  }
}

. {
  printf("Unrecognized character: %s\n", yytext);
}

%%
