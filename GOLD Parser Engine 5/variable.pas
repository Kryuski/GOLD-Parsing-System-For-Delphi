{
Copyright © 2015 Theodore Tsirpanis
This software is provided 'as-is', without any expressed or implied warranty. In no event will the author(s) be held liable for any damages arising from the use of this software.
Permission is granted to anyone to use this software for any purpose.
If you use this software in a product, an acknowledgment in the product documentation would be
deeply appreciated but is not required.

In the case of the GOLD Parser Engine source code, permission is granted to anyone to alter it and redistribute it freely, subject to the following restrictions:

The origin of this software must not be misrepresented; you must not claim that you wrote the original software.
Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
This notice may not be removed or altered from any source distribution
}
unit Variable;

interface

uses
  Classes, SysUtils;

type

  { TVariable }

  TVariable = record
  private
    FValue: string;
  public
    class function Create(const s: string): TVariable; static;
    property Value: string read FValue;
  end;

implementation

{ TVariable }

class function TVariable.Create(const s: string): TVariable;
begin
  Result.FValue := s;
end;

end.
