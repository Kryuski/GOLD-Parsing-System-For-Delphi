program GOLDParserEngineSource;

uses
  Forms,
  GrammarReader in 'GrammarReader.pas',
  Variables in 'Variables.pas',
  Symbol in 'Symbol.pas',
  Rule in 'Rule.pas',
  FAState in 'fasTATE.pas',
  LRAction in 'LRAction.pas',
  GOLDParser in 'GOLDParser.pas',
  Token in 'Token.pas',
  SourceFeeder in 'SourceFeeder.pas',
  MemLeakFinder in 'MemLeakFinder.pas',
  MainForm in 'MainForm.pas' {Main};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMain, Main);
  Application.Run;
end.
