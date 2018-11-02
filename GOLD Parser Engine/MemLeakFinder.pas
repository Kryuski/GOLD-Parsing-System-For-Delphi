unit MemLeakFinder;

interface

uses
   Classes, Dialogs, SysUtils;

var
   LRActionCount: Integer = 0;
   TokenCount: Integer = 0;
   TokenCountTotal: Integer = 0;
   ReductionCount: Integer = 0;
   ReductionCountTotal: Integer = 0;
   RuleCount: Integer = 0;
   SymbolCount: Integer = 0;
   LRActionTableCount: Integer = 0;
   TokenStackCount: Integer = 0;
   VariablesCount: Integer = 0;
   FAStateCount: Integer = 0;

   procedure ShowResults;
   procedure Log(s: string);

implementation

procedure ShowResults;
var
   Results: TStringList;
begin

   Results := TStringList.Create;

   Results.Add('TLRAction: ' + IntToStr(LRActionCount));
   Results.Add('TToken: ' + IntToStr(TokenCount) + ', Total tokens created: ' + IntToStr(TokenCountTotal));
   Results.Add('TReduction: ' + IntToStr(ReductionCount) + ', Total reductions created: ' + IntToStr(ReductionCountTotal));
   Results.Add('TRule: ' + IntToStr(RuleCount));
   Results.Add('TSymbol: ' + IntToStr(SymbolCount));
   Results.Add('TLRActionTable: ' + IntToStr(LRActionTableCount));
   Results.Add('TTokenStack: ' + IntToStr(TokenStackCount));
   Results.Add('TVariables: ' + IntToStr(VariablesCount));
   Results.Add('FAStateCount: ' + IntToStr(FAStateCount));

   if FileExists('c:\dev\GOLDParser.MemLeaks.txt') then
      DeleteFile('c:\dev\GOLDParser.MemLeaks.txt');

   Results.SaveToFile('c:\dev\GOLDParser.MemLeaks.txt');

   Results.Free;

end;

procedure Log(s: string);
var
   LogFile: TStringList;
begin

   LogFile := TStringList.Create;

   LogFile.LoadFromFile('c:\dev\GOLDParser.log.txt');

   LogFile.Add(s);

   if FileExists('c:\dev\GOLDParser.log.txt') then
      DeleteFile('c:\dev\GOLDParser.log.txt');

   LogFile.SaveToFile('c:\dev\GOLDParser.log.txt');

   LogFile.Free;

end;

end.
