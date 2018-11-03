unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, GrammarReader, StdCtrls, GOLDParser, Symbol, ComCtrls, Token;

type
  TMain = class(TForm)
    cmdParse: TButton;
    GroupBox1: TGroupBox;
    txtTestInput: TMemo;
    Label1: TLabel;
    txtCGTFilePath: TEdit;
    Label2: TLabel;
    chkTrimReductions: TCheckBox;
    cmdClose: TButton;
    OpenDialog1: TOpenDialog;
    cmdOpenFile: TButton;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    GroupBox2: TGroupBox;
    txtParseTree: TMemo;
    Memo1: TMemo;
    TabSheet3: TTabSheet;
    TreeView1: TTreeView;
    procedure cmdParseClick(Sender: TObject);
    procedure DrawReductionTree(TheReduction: TReduction);
    procedure DrawReduction(TheReduction: TReduction; Indent: Integer);
    procedure PrintParseTree(Text: String);
    procedure cmdCloseClick(Sender: TObject);
    procedure cmdOpenFileClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    SL : TStringList;
    procedure AddToReport(Msg1, Msg2, Msg3, Msg4 : string; LN : integer);
    procedure DrawTTree(Reduction : TReduction);
  public
    { Public declarations }
  end;

var
  Main: TMain;

implementation

const

// SYMBOL_CONSTANTS
   SYMBOL_EOF           = 0;  (* (EOF) *)
   SYMBOL_ERROR         = 1;  (* (Error) *)
   SYMBOL_WHITESPACE    = 2;  (* (Whitespace) *)
   SYMBOL_MINUS         = 3;  (* '-' *)
   SYMBOL_AMP           = 4;  (* & *)
   SYMBOL_LPARAN        = 5;  (* '(' *)
   SYMBOL_RPARAN        = 6;  (* ')' *)
   SYMBOL_TIMES         = 7;  (* '*' *)
   SYMBOL_COMMA         = 8;  (* ; *)
   SYMBOL_DIV           = 9;  (* / *)
   SYMBOL_PLUS          = 10;  (* '+' *)
   SYMBOL_EQ            = 11;  (* = *)
   SYMBOL_ID            = 12;  (* Id *)
   SYMBOL_NUMBERLITERAL = 13;  (* NumberLiteral *)
   SYMBOL_RUNDE         = 14;  (* runde *)
   SYMBOL_STRINGLITERAL = 15;  (* StringLiteral *)
   SYMBOL_ADDEXP        = 16;  (* <Add Exp> *)
   SYMBOL_FUNCTION2OP   = 17;  (* <Function 2 Op> *)
   SYMBOL_MULTEXP       = 18;  (* <Mult Exp> *)
   SYMBOL_NEGATEEXP     = 19;  (* <Negate Exp> *)
   SYMBOL_STATEMENT     = 20;  (* <Statement> *)
   SYMBOL_VALUE         = 21;  (* <Value> *)

// RULE_CONSTANTS
   RULE_STATEMENTIDEQ          = 0;  (* <Statement> ::= Id = <Add Exp> *)
   RULE_ADDEXPPLUS             = 1;  (* <Add Exp> ::= <Mult Exp> '+' <Add Exp> *)
   RULE_ADDEXPMINUS            = 2;  (* <Add Exp> ::= <Mult Exp> '-' <Add Exp> *)
   RULE_ADDEXPAMP              = 3;  (* <Add Exp> ::= <Mult Exp> & <Add Exp> *)
   RULE_ADDEXP                 = 4;  (* <Add Exp> ::= <Mult Exp> *)
   RULE_MULTEXPTIMES           = 5;  (* <Mult Exp> ::= <Negate Exp> '*' <Mult Exp> *)
   RULE_MULTEXPDIV             = 6;  (* <Mult Exp> ::= <Negate Exp> / <Mult Exp> *)
   RULE_MULTEXP                = 7;  (* <Mult Exp> ::= <Negate Exp> *)
   RULE_NEGATEEXPMINUS         = 8;  (* <Negate Exp> ::= '-' <Value> *)
   RULE_NEGATEEXP              = 9;  (* <Negate Exp> ::= <Value> *)
   RULE_VALUEID                = 10;  (* <Value> ::= Id *)
   RULE_VALUESTRINGLITERAL     = 11;  (* <Value> ::= StringLiteral *)
   RULE_VALUENUMBERLITERAL     = 12;  (* <Value> ::= NumberLiteral *)
   RULE_VALUELPARANRPARAN      = 13;  (* <Value> ::= '(' <Add Exp> ')' *)
   RULE_VALUELPARANCOMMARPARAN = 14;  (* <Value> ::= <Function 2 Op> '(' <Add Exp> , <Add Exp> ')' *)
   RULE_FUNCTION2OPRUNDE       = 15;  (* <Function 2 Op> ::= runde *)


{$R *.dfm}

procedure TMain.cmdParseClick(Sender: TObject);
var
   GP: TGOLDParser;
   txt: string;
   Response: Integer;
   Done: Boolean;
   ReductionNumber: Integer;
   n: Integer;
begin

   SL.Clear;
   
   ReductionNumber := 0;
   GP := TGOLDParser.Create;

   if GP.LoadCompiledGrammar(txtCGTFilePath.Text) then
   begin
      txt := txtTestInput.Text;

      GP.OpenTextString(txt);
      GP.TrimReductions := chkTrimReductions.Checked;
      txtParseTree.Clear;

      Done := False;
      while not Done do
      begin
         Response := GP.Parse;

         case Response of
         gpMsgLexicalError:
            begin
               AddToReport('Lexical Error', 'Cannot recognize token', GP.CurrentToken.DataVar, '', GP.CurrentLineNumber);
               txtParseTree.Text := 'Line ' + IntToStr(GP.CurrentLineNumber) + ': Lexical Error: Cannot recognize token: ' + GP.CurrentToken.DataVar;
               Done := True;
            end;
         gpMsgSyntaxError:
            begin  
               txt := '';
               for n := 0 to GP.TokenTable.Count - 1 do
                  txt := txt + ' ' + GP.TokenTable[n].Name;

               AddToReport('Syntax Error', 'Expecting the following tokens', TrimLeft(txt), '', GP.CurrentLineNumber);
               txtParseTree.Text := 'Line ' + IntToStr(GP.CurrentLineNumber) + ': Syntax Error: Expecting the following tokens: ' + Trim(txt);
               Done := True;
            end;
         gpMsgReduction:
            begin
               Inc(ReductionNumber);
               GP.CurrentReduction.Tag := ReductionNumber;   //Mark the reduction
               AddToReport('Reduce', GP.CurrentReduction.ParentRule.Text, IntToStr(ReductionNumber), IntToStr(GP.CurrentReduction.ParentRule.TableIndex), GP.CurrentLineNumber);
            end;
         gpMsgAccept:
            begin
               //=== Success!
               AddToReport('Accept', GP.CurrentReduction.ParentRule.Text, '', IntToStr(GP.CurrentReduction.ParentRule.TableIndex), GP.CurrentLineNumber);
               DrawReductionTree(GP.CurrentReduction);
               DrawTTree(GP.CurrentReduction);
               Done := True;
            end;
         gpMsgTokenRead:
            begin
               AddToReport('Token Read', GP.CurrentToken.Name, GP.CurrentToken.Text, IntToStr(GP.CurrentToken.TableIndex), GP.CurrentLineNumber);
            end;
         gpMsgInternalError:
            begin
               AddToReport('Internal Error', 'Something is horribly wrong', '', '', GP.CurrentLineNumber);
               Done := True;
            end;
         gpMsgNotLoadedError:
            begin
               //=== Due to the if-statement above, this case statement should never be true
               AddToReport('Not Loaded Error', 'Compiled Gramar Table not loaded', '', '', 0);
               Done := True;
            end;
         gpMsgCommentError:
            begin
               AddToReport('Comment Error', 'Unexpected end of file', '', '', GP.CurrentLineNumber);
               Done := True;
            end;
         end;
      end;
   end else
      ShowMessage('Input file could not be opened!');


   GP.Free;

   Memo1.Lines.Assign(SL);
end;



procedure TMain.DrawReductionTree(TheReduction: TReduction);
begin
    //This procedure starts the recursion that draws the parse tree.

    txtParseTree.Visible := False;   //Keep the system from updating it until we are done
    txtParseTree.Text := '';

    DrawReduction(TheReduction, 0);

    txtParseTree.Visible := True;
end;

procedure TMain.DrawReduction(TheReduction: TReduction; Indent: Integer);
Const
   kIndentText = '|  ';
var
   n: Integer;
   IndentText: string;
begin
   //This is a simple recursive procedure that draws an ASCII version of the parse
   //tree


   IndentText := '';
   for n := 1 to Indent do
       IndentText := IndentText + kIndentText;


   //==== Display Reduction
   PrintParseTree(IndentText + '+--' + TheReduction.ParentRule.Text);

   //=== Display the children of the reduction
   for n := 0 to TheReduction.TokenCount - 1 do
   begin
       case TheReduction.Tokens[n].Kind of
       SymbolTypeNonterminal:
          DrawReduction(TheReduction.Tokens[n].Reduction, (Indent + 1));
       else
          PrintParseTree(IndentText + kIndentText + '+--' + TheReduction.Tokens[n].DataVar);
       end;
   end;

end;

procedure TMain.PrintParseTree(Text: String);
begin
   //This sub just appends the Text to the end of the txtParseTree textbox.

   txtParseTree.Lines.Add(Text);

end;

procedure TMain.cmdCloseClick(Sender: TObject);
begin

   Application.Terminate;

end;

procedure TMain.cmdOpenFileClick(Sender: TObject);
begin

   if OpenDialog1.Execute then
      txtCGTFilePath.Text := OpenDialog1.FileName;
end;

procedure TMain.FormCreate(Sender: TObject);
begin

   txtCGTFilePath.Text := ExtractFileDir(Application.ExeName) + '\simple.cgt';

   //ShowMessage('Warning: This is the Alpha version of the GOLD Parser Engine Delphi version!'#13#10#13#10'Use it at youre own risk! I am not responsible for any damage wich might have been caused by this program!');
   SL := TStringList.Create;

end;

procedure TMain.AddToReport(Msg1, Msg2, Msg3, Msg4: string; LN: integer);
begin
  SL.Add(Format('"%s" , "%s" , "%s" , "%s" , "%d"', [Msg1,Msg2,Msg3,Msg4,LN]));
end;

procedure TMain.FormDestroy(Sender: TObject);
begin
  SL.Free;
end;

procedure TMain.DrawTTree(Reduction: TReduction);

  procedure DrawTTree_R(R : TReduction; ParentNode : TTreeNode);
  var i : integer;
  begin
    for i := 0 to R.TokenCount - 1 do
      case R.Tokens[i].Kind of
        SymbolTypeNonterminal : DrawTTree_R(R.Tokens[i].Reduction, TreeView1.Items.AddChild(ParentNode, R.Tokens[i].Reduction.ParentRule.Name));
        SymbolTypeTerminal    : TreeView1.Items.AddChild(ParentNode, R.Tokens[i].Name + ' : ' + R.Tokens[i].DataVar);
      end;
  end;

begin
  TreeView1.Items.BeginUpdate;
  try
    TreeView1.Items.Clear;
    DrawTTree_R(Reduction, TreeView1.Items.AddChild(nil,  Reduction.ParentRule.Name));
    TreeView1.FullExpand;
  finally
    TreeView1.Items.EndUpdate;
  end;
end;


end.
