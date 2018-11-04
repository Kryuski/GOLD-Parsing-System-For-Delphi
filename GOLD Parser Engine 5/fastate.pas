{
Copyright © 2015 Theodore Tsirpanis
This software is provided 'as-is', without any expressed or implied warranty. In no event will the author(s) be held liable for any damages arising from the use of this software.
Permission is granted to anyone to use this software for any purpose. If you use this software in a product, an acknowledgment in the product documentation would be deeply appreciated but is not required.

In the case of the GOLD Parser Engine source code, permission is granted to anyone to alter it and redistribute it freely, subject to the following restrictions:

The origin of this software must not be misrepresented; you must not claim that you wrote the original software.
Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
This notice may not be removed or altered from any source distribution
}
unit FAState;

interface

uses
  Classes, SysUtils, CharacterSet, Symbol, Generics.Collections;

type

  { TFAEdge }

  TFAEdge = record
  private
    FChars: TCharacterSet;
    FTarget: integer;
  public
    class function Create(const cs: TCharacterSet; const tg: integer): TFAEdge; static;
    property Chars: TCharacterSet read FChars write FChars;
    property Target: integer read FTarget write FTarget;
  end;

  TEdgeList = TList<TFAEdge>;

  { TFAState }

  TFAState = class
  private
    FEdges: TEdgeList;
    FAccept: TSymbol;
  public
    constructor Create(const s: TSymbol);
    destructor Destroy; override;
    property Edges: TEdgeList read FEdges;
    property Accept: TSymbol read FAccept;
  end;

  TFAList = TObjectList<TFAState>;

  { TFAStateList }

  TFAStateList = class(TFAList)
  private
    FInitialState: integer;
    FErrorSymbol: TSymbol;
  public
    property InitialState: integer read FInitialState write FInitialState;
    property ErrorSymbol: TSymbol read FErrorSymbol write FErrorSymbol;
  end;

implementation

{ TFAState }

constructor TFAState.Create(const s: TSymbol);
begin
  FEdges := TEdgeList.Create;
  FAccept := s;
end;

destructor TFAState.Destroy;
begin
  FEdges.Free;
  inherited Destroy;
end;

{ TFAEdge }

class function TFAEdge.Create(const cs: TCharacterSet; const tg: integer): TFAEdge;
begin
  Result.FChars := cs;
  Result.FTarget := tg;
end;

end.
