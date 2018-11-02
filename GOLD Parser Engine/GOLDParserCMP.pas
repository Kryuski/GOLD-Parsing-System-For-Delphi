unit GOLDParserCMP;

interface

uses
  Windows, Messages, SysUtils, Classes, GOLDParser, Token, Reduction, Rule, Symbol, stdCtrls;

type
  TLexicalError = procedure(Sender: TObject) of Object;
  TSyntaxError = procedure(Sender: TObject; Expected: string) of Object;
  TMsgInternalError = procedure(Sender: TObject) of Object;
  TMsgCommentError = procedure(Sender: TObject) of Object;
  TMsgReduction = procedure(Sender: TObject) of Object;
  TMsgTokenRead = procedure(Sender: TObject) of Object;

  TGOLDParserCMP = class(TComponent)
  private
    FLines: TStrings;
    FTrimReductions: Boolean;
    FGOLDParser: TGOLDParser;
    FCurrentLineNumber: Integer;
    FCurrentReduction: TReduction;
    FRuleTableCount: Integer;
    FCurrentToken: TToken;
    FGrammarFile: TFilename;
    FLexicalError: TLexicalError;
    FSyntaxError: TSyntaxError;
    FMsgReduction: TMsgReduction;
    FMsgTokenRead: TMsgTokenRead;
    FMsgInternalError: TMsgInternalError;
    FMsgCommentError: TMsgCommentError;
    procedure SetSource(src: TStrings);
    procedure SetTrimReductions(Value: Boolean);
    procedure SetCurrentReduction(Reduction: TReduction);
    function GetRuleTableEntry(Index: Integer): TRule;
    function GetSymbolTableCount: Integer;
    function GetSymbolTableEntry(Index: Integer): TSymbol;
    function GetTokenCount: Integer;
    function GetTokens(Index: Integer): TToken;
  protected
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Parse: TReduction;
    procedure Reset;
    procedure Clear;
    procedure PushInputToken(TheToken: TToken);
    function Parameter(ParamName: string): string;
    function PopInputToken: TToken;
    property CurrentLineNumber: Integer read FCurrentLineNumber;
    property CurrentReduction: TReduction read FCurrentReduction write SetCurrentReduction;
    property CurrentToken: TToken read FCurrentToken;
    property RuleTableEntry[Index: Integer]: TRule read GetRuleTableEntry;
    property SymbolTableCount: Integer read GetSymbolTableCount;
    property SymbolTableEntry[Index: Integer]: TSymbol read GetSymbolTableEntry;
    property TokenCount: Integer read GetTokenCount;
    property Tokens[Index: Integer]: TToken read GetTokens;
  published
    property Source: TStrings read FLines write SetSource;
    property GrammarFile: TFileName read FGrammarFile write FGrammarFile;
    property TrimReductions: Boolean read FTrimReductions write SetTrimReductions;
    property OnLexicalError: TLexicalError read FLexicalError write FLexicalError;
    property OnSyntaxError: TSyntaxError read FSyntaxError write FSyntaxError;
    property OnMsgReduction: TMsgReduction read FMsgReduction write FMsgReduction;
    property OnMsgTokenRead: TMsgTokenRead read FMsgTokenRead write FMsgTokenRead;
    property OnInternalError: TMsgInternalError read FMsgInternalError write FMsgInternalError;
    property OnMsgCommentError: TMsgCommentError read FMsgCommentError write FMsgCommentError;
  end;

procedure Register;

implementation

constructor TGOLDParserCMP.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);

   FGOLDParser := TGOLDParser.Create;
   FGOLDParser.TrimReductions := True;
   FTrimReductions := True;
   FLines := TStringList.Create;

end;

destructor TGOLDParserCMP.Destroy;
begin

   FLines.Free;
   FGOLDParser.Free;
   inherited Destroy;
end;

procedure TGOLDParserCMP.SetSource(src: TStrings);
begin
   FLines.Assign(src);
end;

procedure TGOLDParserCMP.SetTrimReductions(Value: Boolean);
begin

   FTrimReductions := Value;

end;

function TGOLDParserCMP.Parse: TReduction;
var
   Done: Boolean;
   Response: Integer;
   ReductionNumber: Integer;
   txt: string;
   n: Integer;
begin

   Result := nil;
   ReductionNumber := 0;
   if FGOLDParser.LoadCompiledGrammar(FGrammarFile) then
   begin
      FGOLDParser.OpenTextString(FLines.Text);
      FGOLDParser.TrimReductions := FTrimReductions;

      Done := False;
      while not Done do
      begin
         Response := FGOLDParser.Parse;

         FCurrentLineNumber := FGOLDParser.CurrentLineNumber;
         FCurrentToken := FGOLDParser.CurrentToken;
         FRuleTableCount := FGOLDParser.RuleTableCount;

         case Response of
         gpMsgLexicalError:
            begin
               if Assigned(FLexicalError) then
                  FLexicalError(Self);
               Done := True;
            end;
         gpMsgSyntaxError:
            begin
               if Assigned(FSyntaxError) then
               begin
                  txt := '';
                  for n := 0 to FGOLDParser.TokenCount - 1 do
                     txt := txt + ' ' + FGOLDParser.Tokens(n).Name;
                  FSyntaxError(Self, Trim(txt));
               end;
               Done := True;
            end;
         gpMsgReduction:
            begin
               Inc(ReductionNumber);
               FGOLDParser.CurrentReduction.Tag := ReductionNumber;   //Mark the reduction
               if Assigned(FMsgReduction) then
                  FMsgReduction(Self);
            end;
         gpMsgAccept:
            begin
               //=== Success!
               //DrawReductionTree(GP.CurrentReduction);
               Result := FGOLDParser.CurrentReduction;
               Done := True;
            end;
         gpMsgTokenRead:
            begin
               if Assigned(FMsgTokenRead) then
                  FMsgTokenRead(Self);
            end;
         gpMsgInternalError:
            begin
               if Assigned(FMsgInternalError) then
                  FMsgInternalError(Self);
               Done := True;
            end;
         gpMsgCommentError:
            begin
               if Assigned(FMsgCommentError) then
                  FMsgCommentError(Self);
               Done := True;
            end;
         end;
      end;
   end;

end;

procedure TGOLDParserCMP.SetCurrentReduction(Reduction: TReduction);
begin

   FGOLDParser.CurrentReduction := Reduction;

end;

function TGOLDParserCMP.GetRuleTableEntry(Index: Integer): TRule;
begin

   Result := FGOLDParser.RuleTableEntry[Index];

end;

function TGOLDParserCMP.GetSymbolTableCount: Integer;
begin

   Result := FGOLDParser.SymbolTableCount;

end;

function TGOLDParserCMP.GetSymbolTableEntry(Index: Integer): TSymbol;
begin

   Result := FGOLDParser.SymbolTableEntry[Index];

end;

function TGOLDParserCMP.GetTokenCount: Integer;
begin

   Result := FGOLDParser.TokenCount;

end;

function TGOLDParserCMP.GetTokens(Index: Integer): TToken;
begin
   Result := FGOLDParser.Tokens(Index);
end;

procedure TGOLDParserCMP.Reset;
begin
   FGOLDParser.Reset;
end;

procedure TGOLDParserCMP.Clear;
begin
   FGOLDParser.Clear;
end;

function TGOLDParserCMP.Parameter(ParamName: string): string;
begin

   Result := FGOLDParser.Parameter(ParamName);

end;

function TGOLDParserCMP.PopInputToken: TToken;
begin

   Result := FGOLDParser.PopInputToken;

end;

procedure TGOLDParserCMP.PushInputToken(TheToken: TToken);
begin

   FGOLDParser.PushInputToken(TheToken);

end;

procedure Register;
begin
  RegisterComponents('GOLDParser', [TGOLDParserCMP]);
end;

end.
