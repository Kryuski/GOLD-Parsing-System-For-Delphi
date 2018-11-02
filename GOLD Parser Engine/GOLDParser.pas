unit GOLDParser;

{
'===================================================================
' Class Name:
'    GOLDParser (basic version)
'
' Instancing:
'      Public; Creatable  (VB Setting: 5 - MultiUse)
'
' Purpose:
'    This is the main class in the GOLD Parser Engine and is used to perform
'    all duties required to the parsing of a source text string. This class
'    contains the LALR(1) State Machine code, the DFA State Machine code,
'    character table (used by the DFA algorithm) and all other structures and
'    methods needed to interact with the developer.
'
'Author(s):
'   Devin Cook
'
'Public Dependencies:
'   Token, Rule, Symbol, Reduction
'
'Private Dependencies:
'   ObjectList, SimpleDatabase, SymbolList, StringList, VariableList, TokenStack
'
'Revision History:
'   June 9, 2001:
'      Added the ReductionMode property and modified the Reduction object (which was
'      used only for internal use). In addition the Reduction property was renamed to
'      CurrentReduction to avoid possible name conflicts in different programming languages
'      (which this VB source will be converted to eventually)
'   Sept 5, 2001:
'      I was alerted to an error in the engine logic by Szczepan Holyszewski [rulatir@poczta.arena.pl].
'      When reading tokens inside a block quote, the line-comment token would still eliminate the rest
'      of a line - possibly eliminating the block quote end.
'   Nov 28, 2001:
'      Fixed several errors.
'   December 2001:
'      Added the TrimReductions property and required logic
'===================================================================
 Conversion to Delphi:
      Beany
      Beany@cloud.demon.nl

 Conversion status: Done, not tested

 Delphi Version: 6.0

 Delphi GOLDParser version: 0.1 (very alpha!)


 Conversion Readme:

 This is a pretty straightforward conversion of the GOLDParser VB version.
 The most important difference is the GrammarReader and the SourceFeeder classes.
 These classes take care of reading the grammar and feeding the parser with code
 wich must be parsed. The reading of the grammar looks the same as in the VB
 version, but the LookaheadStream is not being used. The feeding of the source
 is also being done without the LookaheadStream.

 TODO's(in no particulair order):

 1. DONE 22 April 2002: Get rid of the Variant type's. It can be done without.
    The code will run faster without Variants. They can also produce weird errors.
 2. Optimize the code. Its currently a pretty straightforward conversion. It
    can be done better, wich will result in cleaner and faster code.
 3. Intensive testing. I did some tests, wich succeeded, but I want to test it
    more to be sure it does what it is supposed to do. Any input on this
    would be helpfull! ;)
 4. DONE 24 April 2002(well, I hope so!): Check if there are no memory leaks. I have the feeling there are some, but
    I have to get in to it.
 5. Write some documentation
 6. ALTHOUGH IT LOOKS LIKE ITS DONE: ALMOST DONE, JUST SOME MINOR THINGS: Make
    a nice component of this all so it can be easily used with a Delphi
    application
 7. DONE 23 April 2002: Make sure the interface has the same functionality compared to the VB
    ActiveX version.



 Warranty: None ofcourse :) If it works for you, GOOD! If it doesnt, don't demand
 that I will fix it. You can ask me, but I can't guarantee anything!



'================================================================================
'
'                 The GOLD Parser Freeware License Agreement
'                 ==========================================
'
'this software Is provided 'as-is', without any expressed or implied warranty.
'In no event will the authors be held liable for any damages arising from the
'use of this software.
'
'Permission is granted to anyone to use this software for any purpose. If you
'use this software in a product, an acknowledgment in the product documentation
'would be deeply appreciated but is not required.
'
'In the case of the GOLD Parser Engine source code, permission is granted to
'anyone to alter it and redistribute it freely, subject to the following
'restrictions:
'
'   1. The origin of this software must not be misrepresented; you must not
'      claim that you wrote the original software.
'
'   2. Altered source versions must be plainly marked as such, and must not
'      be misrepresented as being the original software.
'
'   3. This notice may not be removed or altered from any source distribution
'
'================================================================================
}

interface

uses
   Classes, SysUtils, contnrs,
   Variables, LRAction, FAState, Rule, Symbol,
   Token, SourceFeeder;

const

   gpMsgEmpty = 0;                   // Nothing
   gpMsgTokenRead = 1;               // Each time a token is read, this message is generated.
   gpMsgReduction = 2;               // When the engine is able to reduce a rule,
                                     // this message is returned. The rule that was
                                     // reduced is set in the GOLDParser's ReduceRule property.
                                     // The tokens that are reduced and correspond the
                                     // rule's definition are stored in the Tokens() property.
   gpMsgAccept = 3;                  // The engine will returns this message when the source
                                     // text has been accepted as both complete and correct.
                                     // In other words, the source text was successfully analyzed.
   gpMsgNotLoadedError = 4;          // Before any parsing can take place,
                                     // a Compiled Grammar Table file must be loaded.
   gpMsgLexicalError = 5;            // The tokenizer will generate this message when
                                     // it is unable to recognize a series of characters
                                     // as a valid token. To recover, pop the invalid
                                     // token from the input queue.
   gpMsgSyntaxError = 6;             // Often the parser will read a token that is not expected
                                     // in the grammar. When this happens, the Tokens() property
                                     // is filled with tokens the parsing engine expected to read.
                                     // To recover: push one of the expected tokens on the input queue.
   gpMsgCommentError = 7;            // The parser reached the end of the file while reading a comment.
                                     // This is caused when the source text contains a "run-away"
                                     // comment, or in other words, a block comment that lacks the
                                     // delimiter.
   gpMsgInternalError = 8;           // Something is wrong, very wrong

   ParseResultEmpty = 0;
   ParseResultAccept = 1;
   ParseResultShift = 2;
   ParseResultReduceNormal = 3;
   ParseResultReduceEliminated = 4;
   ParseResultSyntaxError = 5;
   ParseResultInternalError = 6;

type

  TCompareMode = (vbBinaryCompare, vbTextCompare);

  TGOLDParser = class
  private
    FGrammarReader: TObject;
    FVariableList: TVariableList;
    FSymbolTable: TSymbolTable;
    FInitialDFAState: Integer;
    FInitialLALRState: Integer;
    FCharacterSetTable: TStringList;
    FRuleTable: TRuleTable;
    FDFA: TFStateTable;
    FActionTables: TLRActionTables;

    FTablesLoaded: Boolean;
    FTrimReductions: Boolean;

    FErrorSymbol: TSymbol;
    FEndSymbol: TSymbol;

    FCompareMode: TCompareMode;

    FCurrentLALR: Integer;
    FLineNumber: Integer;
    FCommentLevel: Integer;
    FHaveReduction: Boolean;

    FStack: TTokenStack;
    FTokens: TTokenStack;
    FInputTokens: TTokenStack;

    FSource: TSourceFeeder;
    procedure PrepareToParse;
    function RetrieveToken(Source: TSourceFeeder): TToken;
    procedure DiscardRestOfLine;
    function ParseToken(NextToken: TToken): Integer;
    function GetCurrentReduction: TReduction;
    procedure SetCurrentReduction(NewReduction: TReduction);
    function GetCurrentToken: TToken;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    // Resets the GOLDParser. The parser's internal tables are not affected.
    procedure Clear;
    // The GOLDParser is reset and the internal tables are cleared.
    procedure PushInputToken(TheToken: TToken);
    // Pushes the token onto the front of the GOLDParser's internal input queue.
    // It will be the next token analyzed by the parsing engine.
    function LoadCompiledGrammar(const FileName : string) : boolean; overload;
    function LoadCompiledGrammar(const Stream : TStream) : boolean; overload;
    // If the Compiled Grammar Table file is successfully loaded
    // the method returns True; otherwise False. This method must
    // be called before any Parse calls are made.
    function OpenTextString(Text: String): Boolean;
    // Opens the SourceString for parsing. If successful the method returns True; otherwise False.
    function ReadTextString: string;
    function Parse: Integer;
    // Executes a parse.  When this method is called, the parsing engine
    // reads information from the source text (either a string or a file)
    // and then reports what action was taken. This ranges from a token
    // being read and recognized from the source, a parse reduction, or a type of error.
    function Parameter(ParamName: string): string;
    // Returns a string containing the value of the specified parameter.
    // The ParameterName is the same as the parameters entered in the
    // grammar's description. These include: Name, Version, Author, About,
    // Case Sensitive and Start Symbol. If the name specified is invalid,
    // this method will return an empty string.
    function PopInputToken: TToken;
    // Removes the next token from the front of the parser's internal input queue.
    property TrimReductions: Boolean read FTrimReductions write FTrimReductions;
    // Returns/sets the TrimReductions flag. When this property is set to True,
    // the parser engine will automatically trim (i.e. remove) unneeded reductions
    // from the parse tree. For more information please click here.
    property CurrentReduction: TReduction read GetCurrentReduction write SetCurrentReduction;
    // Returns/sets the reduction made by the parsing engine.
    // When a reduction takes place, this property will be set to
    // a Reduction object which will store the reduced rule and its related tokens.
    // This property may be reassigned a customized object if the developer so desire.
    // The value of this property is only valid when the Parse() method returns
    //the gpMsgReduction message.
    property CurrentLineNumber: Integer read FLineNumber;
    // Returns the current line in the source text.
    property CurrentToken: TToken read GetCurrentToken;
    // Returns the token that is ready to be parsed by the engine.
    // This property is only valid when when the gpMsgTokenRead message is
    // returned from the Parse method.
    property VariableList : TVariableList read FVariableList;
    property SymbolTable : TSymbolTable read FSymbolTable;
    // Returns the parser's internal Symbol Table.
    property CharacterSetTable : TStringList read FCharacterSetTable;
    property RuleTable : TRuleTable read FRuleTable;
    // Returns the parser's Rule Table
    property DFA : TFStateTable read FDFA;
    property ActionTables : TLRActionTables read FActionTables;
    property InitialDFAState : integer read FInitialDFAState write FInitialDFAState;
    property InitialLALRState : integer read FInitialLALRState write FInitialLALRState;
    property TokenTable : TTokenStack read FTokens;
    // Returns the token Table.
  end;

implementation

uses GrammarReader;

constructor TGOLDParser.Create;
begin
   inherited Create;
   FStack := TTokenStack.Create;
   FTokens := TTokenStack.Create;
   FInputTokens := TTokenStack.Create;
   FGrammarReader := TGrammarReader.Create(Self);
   FSource := TSourceFeeder.Create;
   FVariableList := TVariableList.Create;
   FSymbolTable := TSymbolTable.Create;
   FCharacterSetTable := TStringList.Create;
   FRuleTable := TRuleTable.Create;
   FDFA := TFStateTable.Create;
   FActionTables := TLRActionTables.Create;;
   FTablesLoaded := False;
   FTrimReductions := False;
end;

destructor TGOLDParser.Destroy;
begin
   FActionTables.Free;
   FDFA.Free;
   FRuleTable.Free;
   FCharacterSetTable.Free;
   FSymbolTable.Free;
   FVariableList.Free;
   FSource.Free;
   FGrammarReader.Free;
   FInputTokens.Free;
   FTokens.Free;
   FStack.Free;
   inherited Destroy;
end;

procedure TGOLDParser.Reset;
var i : integer;
begin
  for i := 0 to SymbolTable.Count - 1 do
    case SymbolTable[i].Kind of
      SymbolTypeError : FErrorSymbol := SymbolTable[i];
      SymbolTypeEnd   : FEndSymbol := SymbolTable[i];
    end;

  if (VariableList.Value['Case Sensitive'] = 'True')
  then FCompareMode := vbBinaryCompare
  else FCompareMode := vbTextCompare;

  FCurrentLALR := FInitialLALRState;
  FLineNumber := 1;
  FCommentLevel := 0;
  FHaveReduction := False;

  FTokens.Clear;
  FInputTokens.Clear;
  FStack.Clear;
end;

procedure TGOLDParser.Clear;
// The GOLDParser is reset and the internal tables are cleared.
begin
  FSymbolTable.Clear;
  FSymbolTable.Clear;
  FRuleTable.Clear;
  FCharacterSetTable.Clear;
  FVariableList.Clear;
  FTokens.Clear;
  FInputTokens.Clear;
  Reset;
end;

function TGOLDParser.LoadCompiledGrammar(const FileName : string) : boolean;
      // If the Compiled Grammar Table file is successfully loaded
      // the method returns True; otherwise False. This method must
      // be called before any Parse calls are made.
begin
  Reset;
  Result := (FGrammarReader as TGrammarReader).LoadTables(Filename);
end;

function TGOLDParser.OpenTextString(Text: String): Boolean;
    // Opens the SourceString for parsing. If successful the method returns True; otherwise False.
begin
  Reset;
  FSource.Text := Text;
  PrepareToParse;
  Result := True;
end;

function TGOLDParser.ReadTextString: string;
begin
  Result := FSource.Text;
end;

procedure TGOLDParser.PrepareToParse;
var Start: TToken;
begin
   //Added 12/23/2001: The token stack is empty until needed
   Start := TToken.Create;
   Start.State := FInitialLALRState;
   Start.ParentSymbol := SymbolTable[(FGrammarReader as TGrammarReader).StartSymbol];
   FStack.Push(Start);
end;

function TGOLDParser.Parse: Integer;
    // Executes a parse.  When this method is called, the parsing engine
    // reads information from the source text (either a string or a file)
    // and then reports what action was taken. This ranges from a token
    // being read and recognized from the source, a parse reduction, or a type of error.
var Done : Boolean;
    ReadToken : TToken;
    ParseResult : Integer;
begin
  Result := gpMsgEmpty;
  if (FActionTables.Count < 1) or (FDFA.Count < 1) then Result := gpMsgNotLoadedError
  else begin
    Done := False;
    while not Done do begin
      if FInputTokens.Count = 0 then begin             //We must read a token
        ReadToken := RetrieveToken(FSource);
        if not Assigned(ReadToken) then begin
          Result := gpMsgInternalError;
          Done := True;
        end else
          if ReadToken.Kind <> SymbolTypeWhitespace then begin
            FInputTokens.Push(ReadToken);
            if (FCommentLevel = 0) and (ReadToken.Kind <> SymbolTypeCommentLine)
               and (ReadToken.Kind <> SymbolTypeCommentStart) then
            begin
              Result := gpMsgTokenRead;
              Done := True;
            end;
          end else ReadToken.Free;
        end else if FCommentLevel > 0 then begin        //We are in a block comment
          ReadToken := FInputTokens.Pop;
          if Assigned(ReadToken) then
            case ReadToken.Kind of
              SymbolTypeCommentStart : Inc(FCommentLevel);
              SymbolTypeCommentEnd   : Dec(FCommentLevel);
              SymbolTypeEnd          : begin
                                         Result := gpMsgCommentError;
                                         Done := True;
                                       end;
            else
                 //Do nothing, ignore
                 //The 'comment line' symbol is ignored as well
            end;

          ReadToken.Free;
        end else begin
          ReadToken := FInputTokens.Top;
          if Assigned(ReadToken) then
            case ReadToken.Kind of
              SymbolTypeCommentStart : begin
                                         Inc(FCommentLevel);
                                         FInputTokens.Pop;                           //Remove it
                                       end;
              SymbolTypeCommentLine  : begin
                                         FInputTokens.Pop;                           //Remove it and rest of line
                                         DiscardRestOfLine;                          //Procedure also increments the line number
                                       end;
              SymbolTypeError        : begin
                                         Result := gpMsgLexicalError;
                                         Done := True;
                                       end;
            else begin                                     //FINALLY, we can parse the token
                   ParseResult := ParseToken(ReadToken);
                    //NEW 12/2001: Now we are using the internal enumerated constant
                   case ParseResult of
                     ParseResultAccept : begin
                       Result := gpMsgAccept;
                       Done := True;
                     end;
                     ParseResultInternalError : begin
                       Result := gpMsgInternalError;
                       Done := True;
                     end;
                     ParseResultReduceNormal : begin
                       Result := gpMsgReduction;
                       Done := True;
                     end;
                     ParseResultShift : FInputTokens.Pop; //A simple shift, we must continue
                                                          //Okay, remove the top token, it is on the stack
                     ParseResultSyntaxError :  begin
                       Result := gpMsgSyntaxError;
                       Done := True;
                     end;
                   end;
                 end;
            end;
        end;
      end;
   end;
end;

function TGOLDParser.RetrieveToken(Source: TSourceFeeder): TToken;      //Symbol Index
var Done: Boolean;
    Found: Boolean;
    CurrentDFA: Integer;
    CurrentPosition: Integer;
    LastAcceptState: Integer;
    LastAcceptPosition: Integer;
    ch: string;
    n: Integer;
    CharSetIndex: Integer;
    comp1, comp2: string;
    Target: Integer;
begin
  Result := TToken.Create;

  Done := False;
  CurrentDFA := FInitialDFAState;           //The first state is almost always #1.
  CurrentPosition := 1;                    //Next byte in the input LookaheadStream
  LastAcceptState := -1;                   //We have not yet accepted a character string
  LastAcceptPosition := -1;

  Target := 0;

  if not FSource.Done then begin
    while not Done do begin
      ch := FSource.ReadFromBuffer(CurrentPosition, False, False);
      if ch = '' then Found := False
      else begin
        n := 0;
        Found := False;

        while (n < DFA[CurrentDFA].EdgeCount) and (not Found) do begin
          CharSetIndex := DFA[CurrentDFA].Edges[n].Characters;
          comp1 := CharacterSetTable.Strings[CharSetIndex];
          comp2 := ch;
          if FCompareMode = vbTextCompare then begin
            comp1 := UpperCase(comp1);
            comp2 := UpperCase(comp2);
          end;

          if Pos(comp2, comp1) <> 0 then begin
            Found := True;
            Target := DFA[CurrentDFA].Edges[n].TargetIndex;
          end;
          Inc(n);
        end;
      end;

       //======= This block-if statement checks whether an edge was found from the current state.
       //======= If so, the state and current position advance. Otherwise it is time to exit the main loop
       //======= and report the token found (if there was it fact one). If the LastAcceptState is -1,
       //======= then we never found a match and the Error Token is created. Otherwise, a new token
       //======= is created using the Symbol in the Accept State and all the characters that
       //======= comprise it.

      if Found then begin
            //======= This code checks whether the target state accepts a token. If so, it sets the
            //======= appropiate variables so when the algorithm in done, it can return the proper
            //======= token and number of characters.
        if DFA[Target].AcceptSymbol <> -1 then begin
          LastAcceptState := Target;
          LastAcceptPosition := CurrentPosition;
        end;

        CurrentDFA := Target;
        Inc(CurrentPosition);
      end else begin                                          //No edge found
        Done := True;
        if LastAcceptState = -1 then begin                //Tokenizer cannot recognize symbol
          Result.ParentSymbol := FErrorSymbol;
          Result.DataVar := FSource.ReadFromBuffer(1, True, True);
        end else begin                                            //Create Token, read characters
          Result.ParentSymbol := SymbolTable[DFA[LastAcceptState].AcceptSymbol];
          Result.DataVar := FSource.ReadFromBuffer(LastAcceptPosition, True, True);    //The data contains the total number of accept characters
        end;
      end;

         //DoEvents
    end;
  end else begin
    Result.DataVar := '';
    Result.ParentSymbol := FEndSymbol;
  end;

   //======= Count Carriage Returns and increment the Line Number. This is done for the
   //======= Developer and is not necessary for the DFA algorithm
  for n := 1 To Length(Result.DataVar) do
    if Result.DataVar[n] = #13 then Inc(FLineNumber);

end;

procedure TGOLDParser.DiscardRestOfLine;
var sTemp: string;
begin
  //Kill the current line - basically for line comments
  sTemp := FSource.ReadLine;
   //01/26/2002: Fixed bug. Inc counter
  Inc(FLineNumber);
end;

function TGOLDParser.ParseToken(NextToken: TToken): Integer;
var Index: Integer;
    RuleIndex: Integer;
    CurrentRule: TRule;
    Head: TToken;
    NewReduction: TReduction;
    n: Integer;
begin
   Result := ParseResultEmpty;

   Index := ActionTables[FCurrentLALR].ActionIndexForSymbol(NextToken.ParentSymbol.TableIndex);

   if Index <> -1 then begin             //Work - shift or reduce
     FHaveReduction := False;       //Will be set true if a reduction is made
     FTokens.Clear;

     case ActionTables[FCurrentLALR][Index].Action of
       ActionAccept : begin
         FHaveReduction := True;
         Result := ParseResultAccept;
       end;
       ActionShift : begin
         FCurrentLALR := ActionTables[FCurrentLALR][Index].Value;
         NextToken.State := FCurrentLALR;
         FStack.Push(NextToken);
         Result := ParseResultShift;
       end;
       ActionReduce : begin
            //Produce a reduction - remove as many tokens as members in the rule & push a nonterminal token
         RuleIndex := ActionTables[FCurrentLALR][Index].Value;
         CurrentRule := RuleTable[RuleIndex];

            //======== Create Reduction
         if (FTrimReductions) and (CurrentRule.ContainsOneNonTerminal) then begin
               //NEW 12/2001
               //The current rule only consists of a single nonterminal and can be trimmed from the
               //parse tree. Usually we create a new Reduction, assign it to the Data property
               //of Head and push it on the stack. However, in this case, the Data property of the
               //Head will be assigned the Data property of the reduced token (i.e. the only one
               //on the stack).
               //In this case, to save code, the value popped of the stack is changed into the head.

            Head := FStack.Pop;
            Head.ParentSymbol := CurrentRule.RuleNonterminal;
            Result := ParseResultReduceEliminated;
         end else begin                                          //Build a Reduction
           FHaveReduction := True;
           NewReduction := TReduction.Create(CurrentRule);
           for n := 0 to CurrentRule.SymbolCount - 1 do
             NewReduction.InsertToken(0, FStack.Pop);
           Head := TToken.Create;
           Head.Reduction := NewReduction;
           Head.ParentSymbol := CurrentRule.RuleNonterminal;

           Result := ParseResultReduceNormal;
         end;

            //========== Goto
         Index := FStack.Top.State;

            //========= If n is -1 here, then we have an Internal Table Error!!!!
         n := ActionTables[Index].ActionIndexForSymbol(CurrentRule.RuleNonterminal.TableIndex);
         if n <> -1 then begin
           FCurrentLALR := ActionTables[Index][n].Value;
           Head.State := FCurrentLALR;
           FStack.Push(Head);
         end else Result := ParseResultInternalError;
       end;
     end;
   end else begin
      //=== Syntax Error! Fill Expected Tokens
    FTokens.Clear;
    for n := 0 to ActionTables[FCurrentLALR].Count - 1 do begin
         //01/26/2002: Fixed bug. EOF was not being added to the expected tokens
      case ActionTables[FCurrentLALR][n].Symbol.Kind of
        SymbolTypeTerminal, SymbolTypeEnd : begin
          Head := TToken.Create;
          Head.DataVar := '';
          Head.ParentSymbol := ActionTables[FCurrentLALR][n].Symbol;
          FTokens.Push(Head);
        end;
      end;
    end;
       //If pTokens.Count = 0 Then Stop
    Result := ParseResultSyntaxError;
  end;
end;

function TGOLDParser.GetCurrentToken: TToken;
    // Returns the token that is ready to be parsed by the engine.
    // This function is only valid when when the gpMsgTokenRead message is
    // returned from the Parse method.
begin
   Result := FInputTokens.Top;
end;

function TGOLDParser.GetCurrentReduction: TReduction;
begin
  if FHaveReduction then Result := FStack.Top.Reduction
  else Result := nil;
end;

procedure TGOLDParser.SetCurrentReduction(NewReduction: TReduction);
begin
  if FHaveReduction then FStack.Top.Reduction := NewReduction;
end;

function TGOLDParser.Parameter(ParamName: string): string;
    // Returns a string containing the value of the specified parameter.
    // The ParameterName is the same as the parameters entered in the
    // grammar's description. These include: Name, Version, Author, About,
    // Case Sensitive and Start Symbol. If the name specified is invalid,
    // this method will return an empty string.
begin
  Result := FVariableList.Value[ParamName];
end;

function TGOLDParser.PopInputToken: TToken;
    // Removes the next token from the front of the parser's internal input queue.
begin
   Result := FInputTokens.Pop;
end;

procedure TGOLDParser.PushInputToken(TheToken: TToken);
    // Pushes the token onto the front of the GOLDParser's internal input queue.
    // It will be the next token analyzed by the parsing engine.
begin
   FInputTokens.Push(TheToken);
end;

function TGOLDParser.LoadCompiledGrammar(const Stream: TStream): boolean;
begin
  Reset;
  Result := (FGrammarReader as TGrammarReader).LoadTables(Stream);
end;

end.
