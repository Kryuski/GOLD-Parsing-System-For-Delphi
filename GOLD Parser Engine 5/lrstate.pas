{
Copyright © 2015 Theodore Tsirpanis
This software is provided 'as-is', without any expressed or implied warranty. In no event will the author(s) be held liable for any damages arising from the use of this software.
Permission is granted to anyone to use this software for any purpose. If you use this software in a product, an acknowledgment in the product documentation would be deeply appreciated but is not required.

In the case of the GOLD Parser Engine source code, permission is granted to anyone to alter it and redistribute it freely, subject to the following restrictions:

The origin of this software must not be misrepresented; you must not claim that you wrote the original software.
Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
This notice may not be removed or altered from any source distribution
}
unit LRState;

interface

uses
  Classes, SysUtils, Generics.Collections, Symbol, gold_types;

type

  { TLRAction }

  TLRAction = record
  private
    fsym: TSymbol;
    ftype: TLRActionType;
    fvalue: integer;
  public
    class function Create(const sym: TSymbol; const tp: TLRActionType;
        const vl: integer): TLRAction; static;
    class function Undefined: TLRAction; static;
    class function Equals(const l1, l2: TLRAction): boolean; overload; static;
    function Equals(const l: TLRAction): boolean; overload;
    property TheSymbol: TSymbol read fsym;
    property LRType: TLRActionType read ftype;
    property Value: integer read fvalue;
  end;

  TLRList = TList<TLRAction>;

  { TLRState }

  TLRState = class(TLRList)
    function Find(const s: TSymbol): TLRAction;
  end;

  TStateList = TObjectList<TLRState>;

  TLRStateList = class(TStateList)
  private
    FInitialState: integer;
  public
    property InitialState: integer read FInitialState write FInitialState;
  end;

implementation

var
  undefsym: TSymbol;

{ TLRState }

function TLRState.Find(const s: TSymbol): TLRAction;
var
  sm: TLRAction;
begin
  Result := TLRAction.Create(nil, laUndefined, -1);
  if Assigned(s) then
    for sm in Self do
      if sm.TheSymbol.TableIndex = s.TableIndex then
        Exit(sm);
end;

{ TLRAction }

class function TLRAction.Create(const sym: TSymbol; const tp: TLRActionType;
  const vl: integer): TLRAction;
begin
  Result.fsym := sym;
  Result.ftype := tp;
  Result.fvalue := vl;
end;

class function TLRAction.Undefined: TLRAction;
begin
  Result := Create(undefsym, laUndefined, -1);
end;

class function TLRAction.Equals(const l1, l2: TLRAction): boolean;
begin
  Result := (l1.LRType = l2.LRType) and (l1.TheSymbol.Equals(l2.TheSymbol)) and
    (l1.Value = l2.Value);
end;

function TLRAction.Equals(const l: TLRAction): boolean;
begin
  Result := Equals(Self, l);
end;

initialization
  undefsym := TSymbol.Create();

finalization
  undefsym.Free;

end.
