===============================================================================
D7GRAMMAR
===============================================================================
(c) Rob F.M. van den Brink, The Netherlands
R.F.M.vandenBrink@hccnet.nl
Aug, 2006 (version 1.1)

Version history
 V1.0 - June 2006, derived from scratch, using Delphi 7.0 help and code files
 V1.1 - Aug 2006,  lots of refinements to cover almost evberything of the language
                   Consumes assembler code as well.
-----------------------------------------------------------------------



SUMMARY
This grammar parses almost everything of the Delphi 7 variant of object pascal.
It relies on the 'error production' and 'nested comments' that are supported by
the 'inline parser engine', defined by Pascal_Engine.pgt (also from me; download 
separately, and see 'example 2' in that zip-file).
When you generate a parser from this grammar, the code size will be around 2.5 Mbyte 
due to the huge tables (1048 LALR states, with more then 36000 edges). 
However, the resulting executable should not exceed 300 kbyte, and is shorter than
the compiled grammar table (*.CGT-file). 


I created D7Grammar.grm from scratch, and it is very complete. However there are 
still a few issues to be resolved that needs special features that currently beyond 
the capabilities of GoldParser.


KNOWN LIMITATIONS:
(1) Cannot handle comment directives like {$ifdef Windows} ... {$endif} 
    When parts of the source code is uncommented in this way, the grammer will
    still read it, and mai fail.
(2) The parser consumes all assembler statements, but is too tolerant in accepting
    input. Groups of several <AsmItem> does not belong to a single <AsmInstruction>
    because a 'newline' is regarded as whitespace while it should be a terminator here.
(3) Lexemes like 'protected' , 'forward' can be both a keyword as well as an identifier
    in Delphi (even in the same object declaration), and when these lexemes should mean
    an identifier, the current grammar cannot handle it correctly.
    For several of them a workaround was created, but a better solution should be 
    developped.
(4) Strings with characters above #127 cannot be handled by the current Grammar. 
    This should be very simple, but if the grammar defines string characters
    as the range {#32 .. #255}, Goldparser also adds {#376} and {#956}. 
    This looks like a bug in Gold Parser.
(5) The inclusion of an adequate number of error productions (SynError) is still 
    to be done.
(6) constructs that are considered (for the timebeing) as too weird, are not
    supported; see below.
The addition of error productions to the grammar is not mature enough to recover 
from almost all errors made in practice, but ik can already do an amazing job)
-----------------------------------------------------------------------
This grammar supports also most of 'weird' constructs that Borland has added 
to Delphi. This refers to the inconsistent syntax for several directives 
like in <CallConvention> and <MethodDirective>. Sometimes these directives have
to be separated by an ';' sometimes not and somtimes both is alowed.  
An example of a syntax that was considered as too weird to be covered by this 
grammar was found in library routine "IdSSLOpenSSLHeaders.pas" (comes with Delphi) 
  VAR
     IdSslCtxSetVerifyDepth : procedure(ctx: PSSL_CTX; depth: Integer); cdecl = nil;
     IdSslCtxGetVerifyDepth : function (ctx: PSSL_CTX):Integer;  cdecl = nil;
In a consistent syntax, cdecl should refer to some variable that is set to "nil', but
the ';' does not close the <TypeSpec> and the rest is still part of the syntax

