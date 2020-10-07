unit Generics.ArrayUtils;

interface

uses System.Generics.Defaults;

type

  TArrayUtils<T> = class
  public
    class function Contains(const AValue: T; const aArray: array of T): boolean;
    class procedure AppendArrays(var A: TArray<T>; const B: TArray<T>);
    class procedure DeleteItem(var A: TArray<T>; const Index: Cardinal);
  end;

implementation

{ TArrayUtils<T> }

class procedure TArrayUtils<T>.AppendArrays(var A: TArray<T>;
  const B: TArray<T>);
var
  i, L: Integer;
begin
  L := Length(A);
  SetLength(A, L + Length(B));
  for i := 0 to High(B) do
    A[L + i] := B[i];
end;

class function TArrayUtils<T>.Contains(const AValue: T;
  const aArray: array of T): boolean;
var LArrayItem: T;
    LComparer: IEqualityComparer<T>;
begin
  LComparer := TEqualityComparer<T>.Default;
  for LArrayItem in aArray do
  begin
    if LComparer.Equals(AValue, LArrayItem) then
      Exit(True);
  end;
  Exit(False);
end;

class procedure TArrayUtils<T>.DeleteItem(var A: TArray<T>;
  const Index: Cardinal);
var
  ALength: Cardinal;
  TailElements: Cardinal;
begin
  ALength := Length(A);
  Assert(ALength > 0);
  Assert(Index < ALength);
  Finalize(A[Index]);
  TailElements := ALength - Index;
  if TailElements > 0 then
    Move(A[Index + 1], A[Index], SizeOf(T) * TailElements);
  Initialize(A[ALength - 1]);
  SetLength(A, ALength - 1);
end;

end.
