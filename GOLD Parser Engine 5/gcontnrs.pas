{
  Copyright (C) 2014 Yann Mérignac

  This library is free software; you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as
  published by the Free Software Foundation; either version 2.1 of the
  License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  As a special exception, the copyright holders of this library give
  you permission to link this library with independent modules to
  produce an executable, regardless of the license terms of these
  independent modules,and to copy and distribute the resulting
  executable under terms of your choice, provided that you also meet,
  for each linked independent module, the terms and conditions of the
  license of that module. An independent module is a module which is
  not derived from or based on this library. If you modify this
  library, you may extend this exception to your version of the
  library, but you are not obligated to do so. If you do not wish to
  do so, delete this exception statement from your version.

  You should have received a copy of the GNU Lesser General Public
  License along with this library. If not, see
  <http://www.gnu.org/licenses/>. 
} 
unit GContnrs;

interface

uses Classes, SysUtils;

const
  MIN_BUCKET_COUNT = 4;
  MAX_BUCKET_COUNT = 1 shl 30;
  DEFAULT_HASHMAP_LOAD_FACTOR = 1.0;

type
  EContainerError = class(Exception);

  { TContainer }
  TContainer = class
  protected
    procedure RaiseContainerEmpty;
    procedure RaiseCursorDenotesWrongContainer;
    procedure RaiseCursorIsNil;
    procedure RaiseError(const Msg: String);
    procedure RaiseIndexOutOfRange;
    procedure RaiseItemAlreadyInSet;
    procedure RaiseItemNotInSet;
    procedure RaiseKeyAlreadyInMap;
    procedure RaiseKeyNotInMap;
    procedure RaiseMethodNotRedefined;
    procedure Unused(P: Pointer); inline;
  end;

  { TGenEnumerator }

  TGenEnumerator<_TItem_, _TPosition_> = class
  public type
    TGetCurrent = function(const Pos: _TPosition_): _TItem_ of object;
    TMoveNext = function(var Pos:_TPosition_): Boolean of object;
  private
    fGetter: TGetCurrent;
    fMover: TMoveNext;
    fPos: _TPosition_;

    function GetCurrent: _TItem_;
  public
    constructor Create(const Pos: _TPosition_; Mover: TMoveNext;
      Getter: TGetCurrent);
    function MoveNext: Boolean;
    property Current: _TItem_ read GetCurrent;
  end;

  { TAbstractVector }

  TAbstractVector = class(TContainer)
  protected
    fCapacity: Integer;
    fSize: Integer;

    procedure CheckIndex(Index: Integer); inline;
    procedure CheckIndexForAdd(Index: Integer); inline;
    procedure InsertSpaceFast(Position, Count: Integer); virtual; abstract;
    function ItemToString(Index: Integer): String; virtual; abstract;
    procedure SetCapacity(ACapacity: Integer); virtual; abstract;
  public
    {** Removes all the items from the container. }
    procedure Clear;

    {** Deletes Count items begining at Position. }
    procedure Delete(Position: Integer; Count: Integer = 1);

    {** Deletes the first Count items. }
    procedure DeleteFirst(Count: Integer = 1);

    {** Deletes the last Count items. }
    procedure DeleteLast(Count: Integer = 1);

    {** Deletes all items in the range [PosFrom..PosTo]. }
    procedure DeleteRange(PosFrom, PosTo: Integer);

    {** Inserts Count undefined items at Position. }
    procedure InsertSpace(Position: Integer; Count: Integer = 1);

    {** Returns true if the container is empty. }
    function IsEmpty: Boolean; inline;

    {** Copies Count items from Src to Dst. }
    procedure Move(Src, Dst, Count: Integer); virtual; abstract;

    {** If necessary, increases the capacity of the container to ensure that it
      can hold at least MinCapacity items. }
    procedure Reserve(MinCapacity: Integer);

    {** Resizes the container to contain NewSize items. }
    procedure Resize(NewSize: Integer);

    {** Reorders the items in reverse order. }
    procedure Reverse;

    {** Reorders the items in the range [PosFrom..PosTo] in reverse order. }
    procedure ReverseRange(PosFrom, PosTo: Integer);

    {** Rearrange items randomly. }
    procedure Shuffle; overload;

    {** Rearrange items in the range [PosFrom..PosTo] randomly. }
    procedure Shuffle(PosFrom, PosTo: Integer); overload;

    {** Swaps the values of the items designated by I and J. }
    procedure Swap(I, J: Integer);

    {** Swaps the values of the items designated by I and J (no bounds check). }
    procedure SwapFast(I, J: Integer); virtual; abstract;

    {** Return a string representation for the container. }
    function ToString: string; override;

    {** Capacity of the container. }
    property Capacity: Integer read fCapacity;

    {** Number of items. }
    property Size: Integer read fSize;
  end;

  { TGenVector }

  TGenVector<_TItem_> = class(TAbstractVector)
  public type
    PItem = ^_TItem_;
    TCompareItems = function (const A, B: _TItem_): Integer of object;
    TItemToString = function (const Item: _TItem_): string of object;
    TProcessItem = procedure(var Item: _TItem_) of object;
    TEnumerator = TGenEnumerator<_TItem_, Integer>;

  strict private 
    fItems: array of _TItem_;
    fOnCompareItems: TCompareItems;
    fOnItemToString: TItemToString;

    function EnumeratorGet(const Pos: Integer): _TItem_;
    function EnumeratorNext(var Pos: Integer): Boolean;
    procedure Fill(Index, Count: Integer; const Value: _TItem_);
    function GetItemFast(Position: Integer): _TItem_; inline;
    function GetItemPtrFast(Position: Integer): PItem;
    procedure InsertionSort(PosFrom, PosTo: Integer; Comparator: TCompareItems);
    procedure Quicksort(Left, Right: Integer; Comparator: TCompareItems);
    class procedure RealMove(Src, Dst: TGenVector<_TItem_>;
      SrcFirst, DstFirst, Count: Integer);
    procedure SetOnCompareItems(AValue: TCompareItems);
    procedure SetOnItemToString(AValue: TItemToString);

  protected
    procedure InsertSpaceFast(Position, Count: Integer); override;
    function ItemToString(Index: Integer): String; override;
    procedure SetCapacity(ACapacity: Integer); override;
  public
    {** Inserts Count times Item at the end of the container. }
    procedure Append(const Item: _TItem_);

    {** Inserts all the items of Src at the end of the container. }
    procedure AppendAll(Src: TGenVector<_TItem_>);

    {** Inserts all the items of Src in the range [PosFrom..PosTo] at the end of
      the container. }
    procedure AppendRange(Src: TGenVector<_TItem_>; PosFrom, PosTo: Integer);

    {** Searches for Item using the binary search algorithm. Returns the index of
      Item if its found. Otherwise, returns ( - InsertionPoint - 1 ).
      InsertionPoint is the point at which the key would be inserted into the
      container. }
    function BinarySearch(const Item: _TItem_): Integer; overload;
    function BinarySearch(const Item: _TItem_;
      Comparator: TCompareItems): Integer; overload;

    {** Searches for Item in range [PosFrom..PosTo] using the binary search
      algorithm. Returns the index of Item if its found. Otherwise, returns
      ( - InsertionPoint - 1 ). InsertionPoint is the point at which the key
      would be inserted into the range. }
    function BinarySearch(const Item: _TItem_;
      PosFrom, PosTo: Integer): Integer; overload;
    function BinarySearch(const Item: _TItem_;
      PosFrom, PosTo: Integer; Comparator: TCompareItems): Integer; overload;

    {** Returns true if the container contains Item. }
    function Contains(const Item: _TItem_): Boolean; overload;
    function Contains(const Item: _TItem_;
      Comparator: TCompareItems): Boolean; overload;

    {** Creates an empty vector and sets his capacity to InitialCapacity. }
    constructor Create(InitialCapacity: Integer = 16);

    function DefaultCompareItems(const A, B: _TItem_): Integer; virtual;
    function DefaultItemToString(const Item: _TItem_): String; virtual;

    {** Destroys the container. }
    destructor Destroy; override;

    {** If Obj = Self then returns true, else if Obj is not a TGenVector returns
      false, else returns true if Self and Obj contain the sames items. }
    function Equals(Obj: TObject): Boolean; overload; override;
    function Equals(Obj: TObject; Comparator: TCompareItems): Boolean; overload;

    {** Returns the index of the first item equal to Item or -1. }
    function FindIndex(const Item: _TItem_): Integer; overload;
    function FindIndex(const Item: _TItem_;
      Comparator: TCompareItems): Integer; overload;

    {** Returns a cursor on the first item equal to Item or NilCursor. The search
      starts at the element From.  }
    function FindIndex(const Item: _TItem_; PosFrom: Integer): Integer; overload;
    function FindIndex(const Item: _TItem_; PosFrom: Integer;
      Comparator: TCompareItems): Integer; overload;

    {** Returns the first Item. }
    function FirstItem: _TItem_; inline;

    function GetEnumerator: TEnumerator;

    {** Returns item at position Position. }
    function GetItem(Position: Integer): _TItem_; inline;

    {** Returns a pointer designating item at position Position. }
    function GetItemPtr(Position: Integer): PItem;

    {** Inserts Count times Item before Before. }
    procedure Insert(Before: Integer; const Item: _TItem_;
      Count: Integer = 1);

    {** Inserts all the items of Src before Before. }
    procedure InsertAll(Before: Integer; Src: TGenVector<_TItem_>);

    {** Inserts before Before all the items of Src in the range
      [PosFrom..PosTo]. }
    procedure InsertRange(Before: Integer; Src: TGenVector<_TItem_>;
      PosFrom, PosTo: Integer);

    {** Returns true if the items are sorted. }
    function IsSorted: Boolean; overload;
    function IsSorted(Comparator: TCompareItems): Boolean; overload;

    {** Invokes Process on each items. }
    procedure Iterate(Process: TProcessItem); overload;

    {** Invokes Process on each items in range [PosFrom..PosTo]. }
    procedure Iterate(Process: TProcessItem; const PosFrom,
      PosTo: Integer); overload;

    {** Returns the last Item. }
    function LastItem: _TItem_; inline;

    {** Returns index of the greatest item. }
    function MaxPos: Integer; overload;
    function MaxPos(Comparator: TCompareItems): Integer; overload;

    {** Returns index of the greatest item in the range [PosFrom..PosTo]. }
    function MaxPos(PosFrom, PosTo: Integer): Integer; overload;
    function MaxPos(PosFrom, PosTo: Integer;
      Comparator: TCompareItems): Integer; overload;

    {** Removes items from Src and inserts them into Self. Afterwards, Self
      contains the union of the items that were initially in Src and Self. Src
      is left empty. If Self and Src are initially sorted, then Self is
      sorted. }
    procedure Merge(Src: TGenVector<_TItem_>); overload;
    procedure Merge(Src: TGenVector<_TItem_>;
      Comparator: TCompareItems); overload;

    {** Returns index of the lowest item. }
    function MinPos: Integer; overload;
    function MinPos(Comparator: TCompareItems): Integer; overload;

    {** Returns index of the lowest item in the range [PosFrom..PosTo]. }
    function MinPos(PosFrom, PosTo: Integer): Integer; overload;
    function MinPos(PosFrom, PosTo: Integer;
      Comparator: TCompareItems): Integer; overload;

    {** Copies Count items from Src to Dst. }
    procedure Move(Src, Dst, Count: Integer); override;

    {** Inserts Count times Item at the begining of the container. }
    procedure Prepend(const Item: _TItem_; Count: Integer = 1);

    {** Inserts all the items of Src at the begining of the container. }
    procedure PrependAll(Src: TGenVector<_TItem_>);

    {** Inserts all the items of Src in the range [PosFrom..PosTo] at the
      begining of the container. }
    procedure PrependRange(Src: TGenVector<_TItem_>; PosFrom, PosTo: Integer);

    procedure ReadFirstItem(out Value: _TItem_); inline;

    procedure ReadItem(Position: Integer; out Value: _TItem_);

    procedure ReadItemFast(Position: Integer; out Value: _TItem_); inline;

    procedure ReadLastItem(out Value: _TItem_); inline;

    {** Replaces items in range [Index..Index + Count - 1] by Value. }
    procedure Replace(Index, Count: Integer; const Value: _TItem_);

    {** Returns the index of the first item equal to Item or -1. }
    function ReverseFindIndex(const Item: _TItem_): Integer; overload;
    function ReverseFindIndex(const Item: _TItem_;
      Comparator: TCompareItems): Integer; overload;

    {** Returns a cursor on the first item equal to Item or NilCursor. The search
      starts at the element From.  }
    function ReverseFindIndex(const Item: _TItem_;
      PosFrom: Integer): Integer; overload;
    function ReverseFindIndex(const Item: _TItem_;
      PosFrom: Integer; Comparator: TCompareItems): Integer; overload;

    {** Assigns the value Value to the item at Position. }
    procedure SetItem(Position: Integer; const Value: _TItem_); inline;

    procedure SetItemFast(Position: Integer; const Value: _TItem_); inline;

    {** Sorts the items. }
    procedure Sort; overload;
    procedure Sort(Comparator: TCompareItems); overload;

    {** Sorts the items in the range [PosFrom..PosTo]. }
    procedure Sort(PosFrom, PosTo: Integer); overload;
    procedure Sort(PosFrom, PosTo: Integer; Comparator: TCompareItems); overload;

    {** Swaps the values of the items designated by I and J (no bounds check). }
    procedure SwapFast(I, J: Integer); override;

    {** Provides access to the items in the container. }
    property Items[Index: Integer]: _TItem_ read GetItemFast
      write SetItemFast; default;

    {** Provides access to pointers on the items in the container. }
    property ItemsPtr[Index: Integer]: PItem read GetItemPtrFast;

    property OnCompareItems: TCompareItems read fOnCompareItems
      write SetOnCompareItems;

    property OnItemToString: TItemToString read fOnItemToString
      write SetOnItemToString;
  end;  
  
  { TGenDeque }

  TGenDeque<_TItem_> = class(TAbstractVector)
  public type
    PItem = ^_TItem_;
    TCompareItems = function (const A, B: _TItem_): Integer of object;
    TItemToString = function (const Item: _TItem_): String of object;
    TProcessItem = procedure(var Item: _TItem_) of object;
    TEnumerator = TGenEnumerator<_TItem_, Integer>;

  strict private
    fItems: array of _TItem_;
    fOnCompareItems: TCompareItems;
    fOnItemToString: TItemToString;
    fStart: Integer;

    procedure DecRank(var Rank: Integer); inline;
    function Equals(Deque: TGenDeque<_TItem_>;
      Comparator: TCompareItems): Boolean; overload;
    function EnumeratorGet(const Pos: Integer): _TItem_;
    function EnumeratorNext(var Pos: Integer): Boolean;
    procedure Fill(Index, Count: Integer; const Value: _TItem_);
    function GetItemPtrFast(Position: Integer): PItem;
    procedure IncRank(var Rank: Integer); inline;
    procedure IncreaseCapacity(ACapacity: Integer);
    function IndexToRank(Index: Integer): Integer; inline;
    procedure InsertionSort(PosFrom, PosTo: Integer; Comparator: TCompareItems);
    procedure Quicksort(Left, Right: Integer; Comparator: TCompareItems);
    class procedure RealMoveIndex(Src, Dst: TGenDeque<_TItem_>;
      SrcFirst, DstFirst, Count: Integer);
    procedure RealMoveRank(Src, Dst, Count: Integer);
    procedure ReduceCapacity(ACapacity: Integer);
    procedure SetOnCompareItems(AValue: TCompareItems);
    procedure SetOnItemToString(AValue: TItemToString);

  protected
    procedure InsertSpaceFast(Position, Count: Integer); override;
    function ItemToString(Index: Integer): String; override;
    procedure SetCapacity(ACapacity: Integer); override;
  public
    {** Inserts Count times Item at the end of the container. }
    procedure Append(const Item: _TItem_; Count: Integer = 1);

    {** Inserts all the items of Src at the end of the container. }
    procedure AppendAll(Src: TGenDeque<_TItem_>);

    {** Inserts all the items of Src in the range [PosFrom..PosTo] at the end of
      the container. }
    procedure AppendRange(Src: TGenDeque<_TItem_>; PosFrom, PosTo: Integer);

    {** Searches for Item using the binary search algorithm. Returns the index of
      Item if its found. Otherwise, returns ( - InsertionPoint - 1 ).
      InsertionPoint is the point at which the key would be inserted into the
      container. }
    function BinarySearch(const Item: _TItem_): Integer; overload;
    function BinarySearch(const Item: _TItem_;
      Comparator: TCompareItems): Integer; overload;

    {** Searches for Item in range [PosFrom..PosTo] using the binary search
      algorithm. Returns the index of Item if its found. Otherwise, returns
      ( - InsertionPoint - 1 ). InsertionPoint is the point at which the key
      would be inserted into the range. }
    function BinarySearch(const Item: _TItem_; PosFrom,
      PosTo: Integer): Integer; overload;
    function BinarySearch(const Item: _TItem_;
      PosFrom, PosTo: Integer; Comparator: TCompareItems): Integer; overload;

    {** Returns true if the container contains Item. }
    function Contains(const Item: _TItem_): Boolean; overload;
    function Contains(const Item: _TItem_;
      Comparator: TCompareItems): Boolean; overload;

    {** Creates an empty deque and sets his capacity to InitialCapacity. }
    constructor Create(InitialCapacity: Integer = 16);

    function DefaultCompareItems(const A, B: _TItem_): Integer; virtual;
    function DefaultItemToString(const Item: _TItem_): String; virtual;

    {** Destroys the container. }
    destructor Destroy; override;

    {** If Obj = Self then returns @true, else if Obj is not a TGenDeque returns
      false, else returns @true if Self and Obj contain the sames items. }
    function Equals(Obj: TObject): Boolean; overload; override;
    function Equals(Obj: TObject; Comparator: TCompareItems): Boolean; overload;

    {** Returns the index of the first item equal to Item or -1. }
    function FindIndex(const Item: _TItem_): Integer; overload;
    function FindIndex(const Item: _TItem_;
      Comparator: TCompareItems): Integer; overload;

    {** Returns a cursor on the first item equal to Item or NilCursor. The search
      starts at the element From.  }
    function FindIndex(const Item: _TItem_; PosFrom: Integer): Integer; overload;
    function FindIndex(const Item: _TItem_; PosFrom: Integer;
      Comparator: TCompareItems): Integer; overload;

    {** Returns the first Item. }
    function FirstItem: _TItem_; inline;

    function GetEnumerator: TEnumerator;

    function GetItemFast(Position: Integer): _TItem_; inline;

    {** Returns item at position Position. }
    function GetItem(Position: Integer): _TItem_; inline;

    {** Returns a pointer designating item at position Position. }
    function GetItemPtr(Position: Integer): PItem;

    {** Inserts Count times Item before Before. }
    procedure Insert(Before: Integer; const Item: _TItem_;
      Count: Integer = 1);

    {** Inserts all the items of Src before Before. }
    procedure InsertAll(Before: Integer; Src: TGenDeque<_TItem_>);

    {** Inserts before Before all the items of Src in the range
      [PosFrom..PosTo]. }
    procedure InsertRange(Before: Integer; Src: TGenDeque<_TItem_>;
      PosFrom, PosTo: Integer);

    {** Returns true if the items are sorted. }
    function IsSorted: Boolean; overload;
    function IsSorted(Comparator: TCompareItems): Boolean; overload;

    {** Invokes Process on each items. }
    procedure Iterate(Process: TProcessItem); overload;

    {** Invokes Process on each items in range [PosFrom..PosTo]. }
    procedure Iterate(Process: TProcessItem; const PosFrom,
      PosTo: Integer); overload;

    {** Returns the last Item. }
    function LastItem: _TItem_; inline;

    {** Returns index of the greatest item. }
    function MaxPos: Integer; overload;
    function MaxPos(Comparator: TCompareItems): Integer; overload;

    {** Returns index of the greatest item in the range [PosFrom..PosTo]. }
    function MaxPos(PosFrom, PosTo: Integer): Integer; overload;
    function MaxPos(PosFrom, PosTo: Integer;
      Comparator: TCompareItems): Integer; overload;

    {** Removes items from Src and inserts them into Self. Afterwards, Self
      contains the union of the items that were initially in Src and Self. Src
      is left empty. If Self and Src are initially sorted, then Self is
      sorted. }
    procedure Merge(Src: TGenDeque<_TItem_>); overload;
    procedure Merge(Src: TGenDeque<_TItem_>; Comparator: TCompareItems); overload;

    {** Returns index of the lowest item. }
    function MinPos: Integer; overload;
    function MinPos(Comparator: TCompareItems): Integer; overload;

    {** Returns index of the lowest item in the range [PosFrom..PosTo]. }
    function MinPos(PosFrom, PosTo: Integer): Integer; overload;
    function MinPos(PosFrom, PosTo: Integer;
      Comparator: TCompareItems): Integer; overload;

    {** Copies Count items from Src to Dst. }
    procedure Move(Src, Dst, Count: Integer); override;

    {** Inserts Count times Item at the begining of the container. }
    procedure Prepend(const Item: _TItem_; Count: Integer = 1);

    {** Inserts all the items of Src at the begining of the container. }
    procedure PrependAll(Src: TGenDeque<_TItem_>);

    {** Inserts all the items of Src in the range [PosFrom..PosTo] at the
      begining of the container. }
    procedure PrependRange(Src: TGenDeque<_TItem_>; PosFrom, PosTo: Integer);

    procedure ReadFirstItem(out Value: _TItem_); inline;

    procedure ReadItem(Position: Integer; out Value: _TItem_);

    procedure ReadItemFast(Position: Integer; out Value: _TItem_); inline;

    procedure ReadLastItem(out Value: _TItem_); inline;

    {** Replaces items in range [Index..Index + Count - 1] by Value. }
    procedure Replace(Index, Count: Integer; const Value: _TItem_);

    {** Returns the index of the first item equal to Item or -1. }
    function ReverseFindIndex(const Item: _TItem_): Integer; overload;
    function ReverseFindIndex(const Item: _TItem_;
      Comparator: TCompareItems): Integer; overload;

    {** Returns a cursor on the first item equal to Item or NilCursor. The search
      starts at the element From.  }
    function ReverseFindIndex(const Item: _TItem_;
      PosFrom: Integer): Integer; overload;
    function ReverseFindIndex(const Item: _TItem_; PosFrom: Integer;
      Comparator: TCompareItems): Integer; overload;

    {** Assigns the value Value to the item at Position. }
    procedure SetItem(Position: Integer; const Value: _TItem_); inline;

    procedure SetItemFast(Position: Integer; const Value: _TItem_); inline;

    {** Sorts the items. }
    procedure Sort; overload;
    procedure Sort(Comparator: TCompareItems); overload;

    {** Sorts the items in the range [PosFrom..PosTo]. }
    procedure Sort(PosFrom, PosTo: Integer); overload;
    procedure Sort(PosFrom, PosTo: Integer; Comparator: TCompareItems); overload;

    procedure SwapFast(I, J: Integer); override;

    {** Provides access to the items in the container. }
    property Items[Index: Integer]: _TItem_ read GetItemFast
      write SetItemFast; default;

    {** Provides access to pointers on the items in the container. }
    property ItemsPtr[Index: Integer]: PItem read GetItemPtrFast;

    property OnCompareItems: TCompareItems read fOnCompareItems
      write SetOnCompareItems;

    property OnItemToString: TItemToString read fOnItemToString
      write SetOnItemToString;
  end;  

  TAbstractList = class;

  { TListCursor }

  TListCursor = record
  strict private
    fList: TAbstractList;
    fNode: Pointer;

  public
    {** Check if the cursors designate the same item. }
    function Equals(const Cursor: TListCursor): Boolean; inline;

    {** Check if the cursors designate an item. }
    function HasItem: Boolean; inline;

    constructor Init(AList: TAbstractList; ANode: Pointer);

    {** Returns true if the cursor designates the first element. }
    function IsFirst: Boolean; inline;

    {** Returns true if the cursor designates the last element. }
    function IsLast: Boolean; inline;

    {** Equivalent to not HasItem. }
    function IsNil: Boolean; inline;

    {** If cursor is nil then do nothing, else if cursor is last then cursor
      becomes nil cursor, otherwise move cursor to the next item.  }
    procedure MoveNext; inline;

    {** If cursor is nil then do nothing, else if cursor is first then cursor
      becomes nil cursor, otherwise move cursor to the previous item.  }
    procedure MovePrevious; inline;

    {** The designated List. }
    property List: TAbstractList read fList;

    {** The designated node. }
    property Node: Pointer read fNode write fNode;
  end;

  { TAbstractList }

  TAbstractList = class(TContainer)
  protected
    procedure CheckValid(const Cursor: TListCursor);
    procedure CheckNotNil(const Cursor: TListCursor);
    function CursorIsFirst(const Cursor: TListCursor): Boolean; virtual; abstract;
    function CursorIsLast(const Cursor: TListCursor): Boolean; virtual; abstract;
    procedure CursorMoveNext(var Cursor: TListCursor); virtual; abstract;
    procedure CursorMovePrev(var Cursor: TListCursor); virtual; abstract;
  end;

  { TGenList }

  TGenList<_TItem_> = class(TAbstractList)
  public type
    PItem = ^_TItem_;
    TCompareItems = function (const A, B: _TItem_): Integer of object;
    TItemToString = function (const Item: _TItem_): String of object;
    TProcessItem = procedure(var Item: _TItem_) of object;
    TEnumerator = TGenEnumerator<_TItem_, TListCursor>;

  strict private type
    PNode = ^TNode;
    TNode = record
      Item: _TItem_;
      Next, Previous: PNode;
    end;

  strict private
    fHead: PNode;
    fOnCompareItems: TCompareItems;
    fOnItemToString: TItemToString;
    fTail: PNode;
    fSize: Integer;
    fNilCursor: TListCursor;

    procedure DeleteNodesBackward(From: PNode; Count: Integer);
    procedure DeleteNodesBetween(NodeFrom, NodeTo: PNode);
    procedure DeleteNodesForward(From: PNode; Count: Integer);
    function EnumeratorGet(const Pos: TListCursor): _TItem_;
    function EnumeratorNext(var Pos: TListCursor): Boolean;
    function Equals(List: TGenList<_TItem_>;
      Comparator: TCompareItems): Boolean; overload;
    function GetItemFast(const Position: TListCursor): _TItem_; inline;
    function GetItemPtrFast(const Position: TListCursor): PItem; inline;
    procedure InsertItem(const Item: _TItem_; Pos: PNode; Count: Integer);
    procedure Partition(Pivot, Back: PNode; Comparator: TCompareItems);
    procedure RealSort(Front, Back: PNode; Comparator: TCompareItems);
    procedure SetOnCompareItems(AValue: TCompareItems);
    procedure SetOnItemToString(AValue: TItemToString);
    procedure SpliceNodes(Before, PosFrom, PosTo: PNode);

  protected
    function CursorIsFirst(const Cursor: TListCursor): Boolean; override;
    function CursorIsLast(const Cursor: TListCursor): Boolean; override;
    procedure CursorMoveNext(var Cursor: TListCursor); override;
    procedure CursorMovePrev(var Cursor: TListCursor); override;

  public
    {** Inserts Count times Item at the end of the container. }
    procedure Append(const Item: _TItem_; Count: Integer = 1);

    {** Inserts all the items of Src at the end of the container. }
    procedure AppendAll(Src: TGenList<_TItem_>);

    {** Inserts all the items of Src in the range [PosFrom..PosTo] at the end of
      the container. }
    procedure AppendRange(Src: TGenList<_TItem_>; const PosFrom, PosTo: TListCursor);

    {** Removes all the items from the container. }
    procedure Clear;

    {** Returns true if the container contains Item. }
    function Contains(const Item: _TItem_): Boolean; overload;
    function Contains(const Item: _TItem_;
      Comparator: TCompareItems): Boolean; overload;

    {** Creates an empty list. }
    constructor Create;

    function DefaultCompareItems(const A, B: _TItem_): Integer; virtual;
    function DefaultItemToString(const Item: _TItem_): String; virtual;

    {** Deletes Count items begining at Position and then sets Position to
      NilCursor. }
    procedure Delete(var Position: TListCursor; Count: Integer = 1);

    {** Deletes the first Count items. }
    procedure DeleteFirst(Count: Integer = 1);

    {** Deletes the last Count items. }
    procedure DeleteLast(Count: Integer = 1);

    {** Deletes all items in the range [PosFrom..PosTo]. }
    procedure DeleteRange(const PosFrom, PosTo: TListCursor);

    {** Destroys the container. }
    destructor Destroy; override;

    {** If Obj = Self then returns true, else if Obj is not a TGenList returns false,
      else returns true if Self and Obj contain the sames items. }
    function Equals(Obj: TObject): Boolean; overload; override;
    function Equals(Obj: TObject; Comparator: TCompareItems): Boolean; overload;

    {** Returns a cursor on the first item equal to Item or NilCursor. }
    function Find(const Item: _TItem_): TListCursor; overload;
    function Find(const Item: _TItem_;
      Comparator: TCompareItems): TListCursor; overload;

    {** Returns a cursor on the first item equal to Item or NilCursor.The search
      starts at the first element if Position is NilCursor, and at the element
      designated by Position otherwise.  }
    function Find(const Item: _TItem_;
      const Position: TListCursor): TListCursor; overload;
    function Find(const Item: _TItem_; const Position: TListCursor;
      Comparator: TCompareItems): TListCursor; overload;

    {** Returns a cursor that designates the first element of the container or
      NilCursor if the container is empty. }
    function First: TListCursor;

    {** Returns the first Item. }
    function FirstItem: _TItem_; inline;

    {** If Index is not in the range [0..Size - 1], then returns NilCursor.
      Otherwise, returns a cursor designating the item at position Index. }
    function GetCursor(Index: Integer): TListCursor;

    function GetEnumerator: TEnumerator;

    {** Returns the item designated by Position. }
    function GetItem(const Position: TListCursor): _TItem_; inline;

    {** Returns a pointer designating the item designated by Position. }
    function GetItemPtr(const Position: TListCursor): PItem; inline;

    {** Inserts Count times Item before Before. }
    procedure Insert(const Before: TListCursor; const Item: _TItem_;
      Count: Integer = 1); overload;

    {** Inserts Count times Item before Before. Position designates the first
      newly-inserted element. }
    procedure Insert(const Before: TListCursor; const Item: _TItem_;
      out Position: TListCursor; Count: Integer); overload;

    {** Inserts all the items of Src before Before. }
    procedure InsertAll(const Before: TListCursor; Src: TGenList<_TItem_>);

    {** Inserts before Before all the items of Src in the range
      [PosFrom..PosTo]. }
    procedure InsertRange(const Before: TListCursor; Src: TGenList<_TItem_>;
      const PosFrom, PosTo: TListCursor);

    {** Returns true if the list is empty. }
    function IsEmpty: Boolean; inline;

    {** Returns @true if the items are sorted. }
    function IsSorted: Boolean; overload;
    function IsSorted(Comparator: TCompareItems): Boolean; overload;

    procedure Iterate(Process: TProcessItem); overload;
    procedure Iterate(Process: TProcessItem; const PosFrom,
      PosTo: TListCursor); overload;

    {** Returns a cursor that designates the last element of the container or
      NilCursor if the container is empty. }
    function Last: TListCursor;

    {** Returns the last Item. }
    function LastItem: _TItem_; inline;

    {** Removes items from Src and inserts them into Self. Afterwards, Self
      contains the union of the items that were initially in Src and Self. Src
      is left empty. If Self and Src are initially sorted, then Self is
      sorted. }
    procedure Merge(Src: TGenList<_TItem_>); overload;
    procedure Merge(Src: TGenList<_TItem_>; Comparator: TCompareItems); overload;

    {** Inserts Count times Item at the begining of the container. }
    procedure Prepend(const Item: _TItem_; Count: Integer = 1);

    {** Inserts all the items of Src at the begining of the container. }
    procedure PrependAll(Src: TGenList<_TItem_>);

    {** Inserts all the items of Src in the range [PosFrom..PosTo] at the
      begining of the container. }
    procedure PrependRange(Src: TGenList<_TItem_>; const PosFrom, PosTo: TListCursor);

    procedure ReadFirstItem(out Value: _TItem_); inline;

    procedure ReadItem(const Position: TListCursor; out Value: _TItem_);

    procedure ReadItemFast(const Position: TListCursor; out Value: _TItem_); inline;

    procedure ReadLastItem(out Value: _TItem_); inline;

    {** Replaces items in range [Position..Position + Count - 1] by Value. }
    procedure Replace(const Position: TListCursor; Count: Integer;
      const Value: _TItem_);

    {** Reorders the items in reverse order. }
    procedure Reverse;

    {** Returns a cursor on the first item equal to Item or NilCursor. }
    function ReverseFind(const Item: _TItem_): TListCursor; overload;
    function ReverseFind(const Item: _TItem_;
      Comparator: TCompareItems): TListCursor; overload;

    {** Returns a cursor on the first item equal to Item or NilCursor.The search
      starts at the last element if Position is NilCursor, and at the element
      designated by Position otherwise.  }
    function ReverseFind(const Item: _TItem_;
      const Position: TListCursor): TListCursor; overload;
    function ReverseFind(const Item: _TItem_; const Position: TListCursor;
      Comparator: TCompareItems): TListCursor; overload;

    {** Reorders the items in the range [PosFrom..PosTo] in reverse order. }
    procedure ReverseRange(const PosFrom, PosTo: TListCursor);

    {** Assigns the value Value to the item designated by Position. }
    procedure SetItem(const Position: TListCursor; const Value: _TItem_);

    procedure SetItemFast(const Position: TListCursor; const Value: _TItem_); inline;

    {** Sorts the items. }
    procedure Sort; overload;
    procedure Sort(Comparator: TCompareItems); overload;

    {** Sorts the items in the range [PosFrom..PosTo]. }
    procedure Sort(const PosFrom, PosTo: TListCursor); overload;
    procedure Sort(const PosFrom, PosTo: TListCursor;
      Comparator: TCompareItems); overload;

    {** Removes all items of Src and moves them to Self before Before. }
    procedure Splice(const Before: TListCursor; Src: TGenList<_TItem_>); overload;

    {** Removes from Src the item designated by Position and moves it to Self
      before Before. }
    procedure Splice(const Before: TListCursor; Src: TGenList<_TItem_>;
      const Position: TListCursor); overload;

    {** Removes all items of Src in the range [SrcFrom..SrcTo] and moves them to
      Self before Before. }
    procedure Splice(const Before: TListCursor; Src: TGenList<_TItem_>;
      const SrcFrom, SrcTo: TListCursor); overload;

    {** Swaps the values of the items designated by I and J. }
    procedure Swap(const I, J: TListCursor);

    {** Swaps the nodes designated by I and J. }
    procedure SwapLinks(const I, J: TListCursor);

    {** Return a string representation for the container. }
    function ToString: String; override;

    {** Provides access to the items in the container. }
    property Items[const Index: TListCursor]: _TItem_
      read GetItemFast write SetItemFast; default;

    {** Provides access to pointers on the items in the container. }
    property ItemsPtr[const Index: TListCursor]: PItem read GetItemPtrFast;

    {** A nil cursor. }
    property NilCursor: TListCursor read fNilCursor;

    property OnCompareItems: TCompareItems read fOnCompareItems
      write SetOnCompareItems;

    property OnItemToString: TItemToString read fOnItemToString
      write SetOnItemToString;

    {** Number of elements in the list. }
    property Size: Integer read fSize;
  end;

function HashData(Data: PByte; DataSize: Integer): Integer;
function HashString(const Str: String): Integer;

implementation

uses Math;

const
  S_BitSetsAreIncompatible = 'bit sets are incompatible';
  S_ContainerEmpty = 'container is empty';
  S_CursorIsNil = 'cursor is nil';
  S_CursorDenotesWrongContainer = 'cursor denotes wrong container';
  S_IndexOutOfRange = 'index out of range';
  S_InvalidBitSetSize = 'invalid bit set size';
  S_InvalidBinaryValue = 'invalid binary value';
  S_ItemNotInSet = 'item not in set';
  S_ItemAlreadyInSet = 'item already in set';
  S_KeyNotInMap = 'key not in map';
  S_KeyAlreadyInMap = 'key already in map';
  S_MethodNotRedefined = 'method not redefined';

  SBox: array [Byte] of LongWord = ( $F53E1837, $5F14C86B, $9EE3964C,
    $FA796D53, $32223FC3, $4D82BC98, $A0C7FA62, $63E2C982, $24994A5B, $1ECE7BEE,
    $292B38EF, $D5CD4E56, $514F4303, $7BE12B83, $7192F195, $82DC7300, $084380B4,
    $480B55D3, $5F430471, $13F75991, $3F9CF22C, $2FE0907A, $FD8E1E69, $7B1D5DE8,
    $D575A85C, $AD01C50A, $7EE00737, $3CE981E8, $0E447EFA, $23089DD6, $B59F149F,
    $13600EC7, $E802C8E6, $670921E4, $7207EFF0, $E74761B0, $69035234, $BFA40F19,
    $F63651A0, $29E64C26, $1F98CCA7, $D957007E, $E71DDC75, $3E729595, $7580B7CC,
    $D7FAF60B, $92484323, $A44113EB, $E4CBDE08, $346827C9, $3CF32AFA, $0B29BCF1,
    $6E29F7DF, $B01E71CB, $3BFBC0D1, $62EDC5B8, $B7DE789A, $A4748EC9, $E17A4C4F,
    $67E5BD03, $F3B33D1A, $97D8D3E9, $09121BC0, $347B2D2C, $79A1913C, $504172DE,
    $7F1F8483, $13AC3CF6, $7A2094DB, $C778FA12, $ADF7469F, $21786B7B, $71A445D0,
    $A8896C1B, $656F62FB, $83A059B3, $972DFE6E, $4122000C, $97D9DA19, $17D5947B,
    $B1AFFD0C, $6EF83B97, $AF7F780B, $4613138A, $7C3E73A6, $CF15E03D, $41576322,
    $672DF292, $B658588D, $33EBEFA9, $938CBF06, $06B67381, $07F192C6, $2BDA5855,
    $348EE0E8, $19DBB6E3, $3222184B, $B69D5DBA, $7E760B88, $AF4D8154, $007A51AD,
    $35112500, $C9CD2D7D, $4F4FB761, $694772E3, $694C8351, $4A7E3AF5, $67D65CE1,
    $9287DE92, $2518DB3C, $8CB4EC06, $D154D38F, $E19A26BB, $295EE439, $C50A1104,
    $2153C6A7, $82366656, $0713BC2F, $6462215A, $21D9BFCE, $BA8EACE6, $AE2DF4C1,
    $2A8D5E80, $3F7E52D1, $29359399, $FEA1D19C, $18879313, $455AFA81, $FADFE838,
    $62609838, $D1028839, $0736E92F, $3BCA22A3, $1485B08A, $2DA7900B, $852C156D,
    $E8F24803, $00078472, $13F0D332, $2ACFD0CF, $5F747F5C, $87BB1E2F, $A7EFCB63,
    $23F432F0, $E6CE7C5C, $1F954EF6, $B609C91B, $3B4571BF, $EED17DC0, $E556CDA0,
    $A7846A8D, $FF105F94, $52B7CCDE, $0E33E801, $664455EA, $F2C70414, $73E7B486,
    $8F830661, $8B59E826, $BB8AEDCA, $F3D70AB9, $D739F2B9, $4A04C34A, $88D0F089,
    $E02191A2, $D89D9C78, $192C2749, $FC43A78F, $0AAC88CB, $9438D42D, $9E280F7A,
    $36063802, $38E8D018, $1C42A9CB, $92AAFF6C, $A24820C5, $007F077F, $CE5BC543,
    $69668D58, $10D6FF74, $BE00F621, $21300BBE, $2E9E8F46, $5ACEA629, $FA1F86C7,
    $52F206B8, $3EDF1A75, $6DA8D843, $CF719928, $73E3891F, $B4B95DD6, $B2A42D27,
    $EDA20BBF, $1A58DBDF, $A449AD03, $6DDEF22B, $900531E6, $3D3BFF35, $5B24ABA2,
    $472B3E4C, $387F2D75, $4D8DBA36, $71CB5641, $E3473F3F, $F6CD4B7F, $BF7D1428,
    $344B64D0, $C5CDFCB6, $FE2E0182, $2C37A673, $DE4EB7A3, $63FDC933, $01DC4063,
    $611F3571, $D167BFAF, $4496596F, $3DEE0689, $D8704910, $7052A114, $068C9EC5,
    $75D0E766, $4D54CC20, $B44ECDE2, $4ABC653E, $2C550A21, $1A52C0DB, $CFED03D0,
    $119BAFE2, $876A6133, $BC232088, $435BA1B2, $AE99BBFA, $BB4F08E4, $A62B5F49,
    $1DA4B695, $336B84DE, $DC813D31, $00C134FB, $397A98E6, $151F0E64, $D9EB3E69,
    $D3C7DF60, $D2F2C336, $2DDD067B, $BD122835, $B0B3BD3A, $B0D54E46, $8641F1E4,
    $A0B38F96, $51D39199, $37A6AD75, $DF84EE41, $3C034CBA, $ACDA62FC, $11923B8B,
    $45EF170A);

  Card: array [Byte] of Byte = (0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 1, 2, 2, 3, 2, 3, 3, 4, 2,
    3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 1, 2,
    2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4,
    5, 4, 5, 5, 6, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5,
    4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3,
    4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 2, 3, 3, 4, 3, 4,
    4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6,
    7, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6,
    4, 5, 5, 6, 5, 6, 6, 7, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 4,
    5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8);

{--- HashData ---}
{$rangechecks off}
{$overflowchecks off}
function HashData(Data: PByte; DataSize: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to DataSize do
  begin
    Result := Result xor Integer(SBox[Data^]);
    Result := Result * 3;
    Inc(Data);
  end;
end;
{$IFDEF DEBUG}
{$rangechecks on}
{$overflowchecks on}
{$ENDIF}

{--- HashString ---}
function HashString(const Str: String): Integer;
begin
  if Str = '' then
    Result := 0
  else
    Result := HashData(@Str[1], Length(Str));
end;

const
  HexTbl: array[0..15] of AnsiChar = '0123456789ABCDEF';

function HexStr(val: pointer): ShortString;
var
  i: Integer;
  v: NativeUInt;
begin
  v := NativeUInt(val);
  hexstr[0] := chr(sizeof(pointer)*2);
  for i:=sizeof(pointer)*2 downto 1 do
   begin
     hexstr[i]:=hextbl[v and $f];
     v:=v shr 4;
   end;
end;

function binstr(val: int64; cnt: byte): ShortString;
var
  i: Integer;
begin
  binstr[0] := AnsiChar(cnt);
  for i := cnt downto 1 do
   begin
     binstr[i] := AnsiChar(48+val and 1);
     val := val shr 1;
   end;
end;

{$IFDEF DEBUG}
{$rangechecks on}
{$overflowchecks on}
{$ENDIF}

{======================}
{=== TGenEnumerator ===}
{======================}

{--- TGenEnumerator<_TItem_, _TPosition_>.GetCurrent ---}
function TGenEnumerator<_TItem_, _TPosition_>.GetCurrent: _TItem_;
begin
  Result := fGetter(fPos);
end;

{--- TGenEnumerator<_TItem_, _TPosition_>.Create ---}
constructor TGenEnumerator<_TItem_, _TPosition_>.Create(const Pos: _TPosition_; Mover: TMoveNext;
  Getter: TGetCurrent);
begin
  fPos := Pos;
  fMover := Mover;
  fGetter := Getter;
end;

{--- TGenEnumerator<_TItem_, _TPosition_>.MoveNext ---}
function TGenEnumerator<_TItem_, _TPosition_>.MoveNext: Boolean;
begin
  Result := fMover(fPos);
end;

{==================}
{=== TContainer ===}
{==================}

{--- TContainer.RaiseContainerEmpty ---}
procedure TContainer.RaiseContainerEmpty;
begin
  raise EContainerError.Create(S_ContainerEmpty);
end;

{--- TContainer.RaiseCursorDenotesWrongContainer ---}
procedure TContainer.RaiseCursorDenotesWrongContainer;
begin
  raise EContainerError.Create(S_CursorDenotesWrongContainer);
end;

{--- TContainer.RaiseCursorIsNil ---}
procedure TContainer.RaiseCursorIsNil;
begin
  raise EContainerError.Create(S_CursorIsNil);
end;

{--- TContainer.RaiseError ---}
procedure TContainer.RaiseError(const Msg: String);
begin
  raise EContainerError.Create(Msg);
end;

{--- TContainer.RaiseIndexOutOfRange ---}
procedure TContainer.RaiseIndexOutOfRange;
begin
  raise EContainerError.Create(S_IndexOutOfRange);
end;

{--- TContainer.RaiseItemAlreadyInSet ---}
procedure TContainer.RaiseItemAlreadyInSet;
begin
  raise EContainerError.Create(S_ItemAlreadyInSet);
end;

{--- TContainer.RaiseItemNotInSet ---}
procedure TContainer.RaiseItemNotInSet;
begin
  raise EContainerError.Create(S_ItemNotInSet);
end;

{--- TContainer.RaiseKeyAlreadyInMap ---}
procedure TContainer.RaiseKeyAlreadyInMap;
begin
  raise EContainerError.Create(S_KeyAlreadyInMap);
end;

{--- TContainer.RaiseKeyNotInMap ---}
procedure TContainer.RaiseKeyNotInMap;
begin
  raise EContainerError.Create(S_KeyNotInMap);
end;

{--- TContainer.RaiseMethodNotRedefined ---}
procedure TContainer.RaiseMethodNotRedefined;
begin
  raise EContainerError.Create(S_MethodNotRedefined);
end;

{--- TContainer.Unused ---}
{$HINTS OFF}
procedure TContainer.Unused(P: Pointer);
begin
end;
{$IFDEF DEBUG}{$HINTS ON}{$ENDIF}

{=======================}
{=== TAbstractVector ===}
{=======================}

{--- TAbstractVector.CheckIndex ---}
procedure TAbstractVector.CheckIndex(Index: Integer);
begin
  if (Index < 0) or (Index >= fSize) then
    RaiseIndexOutOfRange;
end;

{--- TAbstractVector.CheckIndexForAdd ---}
procedure TAbstractVector.CheckIndexForAdd(Index: Integer);
begin
  if (Index < 0) or (Index > fSize) then
    RaiseIndexOutOfRange;
end;

{--- TAbstractVector.Clear ---}
procedure TAbstractVector.Clear;
begin
  Resize(0);
end;

{--- TAbstractVector.Delete ---}
procedure TAbstractVector.Delete(Position: Integer; Count: Integer);
var
  CountAtEnd: Integer;
begin
  CheckIndex(Position);

  if Position + Count > fSize then
    Count := fSize - Position;

  if Count > 0 then
  begin
    CountAtEnd := fSize - (Position + Count);
    if CountAtEnd > 0 then
      Move(Position + Count, Position, CountAtEnd);

    fSize := fSize - Count;
  end;
end;

{--- TAbstractVector.DeleteFirst ---}
procedure TAbstractVector.DeleteFirst(Count: Integer);
begin
  if Count > 0 then
    Delete(0, Count);
end;

{--- TAbstractVector.DeleteLast ---}
procedure TAbstractVector.DeleteLast(Count: Integer);
begin
  if Count > 0 then
    Resize(fSize - Count);
end;

{--- TAbstractVector.DeleteRange ---}
procedure TAbstractVector.DeleteRange(PosFrom, PosTo: Integer);
begin
  CheckIndex(PosFrom);
  CheckIndex(PosTo);

  if PosTo >= PosFrom then
    Delete(PosFrom, PosTo - PosFrom + 1);
end;

{--- TAbstractVector.InsertSpace ---}
procedure TAbstractVector.InsertSpace(Position: Integer; Count: Integer);
begin
  CheckIndexForAdd(Position);
  InsertSpaceFast(Position, Count);
end;

{--- TAbstractVector.IsEmpty ---}
function TAbstractVector.IsEmpty: Boolean;
begin
  Result := (fSize = 0);
end;

{--- TAbstractVector.Reserve ---}
procedure TAbstractVector.Reserve(MinCapacity: Integer);
var
  NewCapacity: Integer;
begin
  if MinCapacity > Capacity then
  begin
    NewCapacity := (Capacity * 3) div 2;
    if NewCapacity < MinCapacity then
      NewCapacity := MinCapacity;
    SetCapacity(NewCapacity);
  end;
end;

{--- TAbstractVector.Resize ---}
procedure TAbstractVector.Resize(NewSize: Integer);
begin
  if NewSize > fSize then
    Reserve(NewSize);

  if NewSize < 0 then
    NewSize := 0;

  fSize := NewSize;
end;

{--- TAbstractVector.Reverse ---}
procedure TAbstractVector.Reverse;
begin
  if fSize > 1 then
    ReverseRange(0, fSize - 1);
end;

{--- TAbstractVector.ReverseRange ---}
procedure TAbstractVector.ReverseRange(PosFrom, PosTo: Integer);
var
  TmpIndex: Integer;
begin
  CheckIndex(PosFrom);
  CheckIndex(PosTo);

  if PosTo < PosFrom then
  begin
    TmpIndex := PosFrom;
    PosFrom := PosTo;
    PosTo := TmpIndex;
  end;

  while PosFrom < PosTo do
  begin
    SwapFast(PosFrom, PosTo);
    Inc(PosFrom);
    Dec(PosTo);
  end;
end;

{--- TAbstractVector.Shuffle ---}
procedure TAbstractVector.Shuffle;
begin
   if fSize > 1 then
    Shuffle(0, fSize - 1);
end;

{--- TAbstractVector.Shuffle ---}
procedure TAbstractVector.Shuffle(PosFrom, PosTo: Integer);
var
  I, J: Integer;
begin
  CheckIndex(PosFrom);
  CheckIndex(PosTo);

  I := PosTo;
  while I > PosFrom  do
  begin
    J := Random(I - PosFrom) + PosFrom;
    if J <> I then
      SwapFast(J, I);
    Dec(I);
  end;
end;

{--- TAbstractVector.Swap ---}
procedure TAbstractVector.Swap(I, J: Integer);
begin
  CheckIndex(I);
  CheckIndex(J);
  SwapFast(I, J);
end;

{--- TAbstractVector.ToString ---}
function TAbstractVector.ToString: String;
var
  I: Integer;
begin
  Result := '[';

  if fSize > 0 then
  begin
    for I := 0 to fSize - 2 do
      Result := Result + ItemToString(I) + ', ';
    Result := Result + ItemToString(fSize - 1);
  end;

  Result := Result + ']';
end;

{==================}
{=== TGenVector ===}
{==================}

{--- TGenVector<_TItem_>.Append ---}
procedure TGenVector<_TItem_>.Append(const Item: _TItem_);
begin
  Insert(fSize, Item);
end;

{--- TGenVector<_TItem_>.AppendAll ---}
procedure TGenVector<_TItem_>.AppendAll(Src: TGenVector<_TItem_>);
begin
  InsertAll(fSize, Src);
end;

{--- TGenVector<_TItem_>.AppendRange ---}
procedure TGenVector<_TItem_>.AppendRange(Src: TGenVector<_TItem_>; PosFrom, PosTo: Integer);
begin
  InsertRange(fSize, Src, PosFrom, PosTo);
end;

{--- TGenVector<_TItem_>.BinarySearch ---}
function TGenVector<_TItem_>.BinarySearch(const Item: _TItem_): Integer;
begin
  Result := BinarySearch(Item, fOnCompareItems);
end;

{--- TGenVector<_TItem_>.BinarySearch ---}
function TGenVector<_TItem_>.BinarySearch(const Item: _TItem_; Comparator: TCompareItems): Integer;
begin
  if fSize > 0 then
    Result := BinarySearch(Item, 0, fSize - 1, Comparator)
  else
    Result := -1;
end;

{--- TGenVector<_TItem_>.BinarySearch ---}
function TGenVector<_TItem_>.BinarySearch(const Item: _TItem_;
  PosFrom, PosTo: Integer): Integer;
begin
  Result := BinarySearch(Item, PosFrom, PosTo, fOnCompareItems);
end;

{--- TGenVector<_TItem_>.BinarySearch ---}
function TGenVector<_TItem_>.BinarySearch(const Item: _TItem_;
  PosFrom, PosTo: Integer; Comparator: TCompareItems): Integer;
var
  Low, Mid, High, Cmp: Integer;
begin
  CheckIndex(PosFrom);
  CheckIndex(PosTo);

  Low := PosFrom;
  Mid := -1;
  High := PosTo;

  while Low <= High do
  begin
    Mid := (Low + High) div 2;
    Cmp := Comparator(fItems[Mid], Item);

    if Cmp = 0 then
    begin
      Result := Mid;
      Exit;
    end;

    if Cmp < 0 then
      Low := Mid + 1
    else
      High := Mid - 1;
  end;

  if Mid < 0 then
    Result := -1
  else if Comparator(fItems[Mid], Item) > 0 then
    Result := - Mid - 1
  else
    Result := - Mid - 2;
end;

{--- TGenVector<_TItem_>.DefaultCompareItems ---}
function TGenVector<_TItem_>.DefaultCompareItems(const A, B: _TItem_): Integer;
begin
  Unused(@A);
  Unused(@B);
  RaiseMethodNotRedefined;
  Result := 0;
end;

{--- TGenVector<_TItem_>.Contains ---}
function TGenVector<_TItem_>.Contains(const Item: _TItem_): Boolean;
begin
  Result := Contains(Item, fOnCompareItems);
end;

{--- TGenVector<_TItem_>.Contains ---}
function TGenVector<_TItem_>.Contains(const Item: _TItem_; Comparator: TCompareItems): Boolean;
begin
  if fSize = 0 then
    Result := false
  else
    Result := (FindIndex(Item, 0, Comparator) >= 0);
end;

{--- TGenVector<_TItem_>.Create ---}
constructor TGenVector<_TItem_>.Create(InitialCapacity: Integer);
begin
  if InitialCapacity < 0 then
    InitialCapacity := 16;

  fSize := 0;

  SetCapacity(InitialCapacity);

  SetOnCompareItems(nil);
  SetOnItemToString(nil);
end;

{--- TGenVector<_TItem_>.Destroy ---}
destructor TGenVector<_TItem_>.Destroy;
begin
  SetCapacity(0);
  inherited Destroy;
end;

{--- TGenVector<_TItem_>.Equals ---}
function TGenVector<_TItem_>.Equals(Obj: TObject): Boolean;
begin
  Result := Equals(Obj, fOnCompareItems);
end;

{--- TGenVector<_TItem_>.Equals ---}
function TGenVector<_TItem_>.Equals(Obj: TObject; Comparator: TCompareItems): Boolean;
var
  Vector: TGenVector<_TItem_>;
  I: Integer;
begin
  if Obj = Self  then
    Result := true
  else if Obj is TGenVector<_TItem_> then
  begin
    Vector := Obj as TGenVector<_TItem_>;

    if fSize <> Vector.fSize then
      Result := false
    else
    begin
      Result := true;
      for I := 0 to fSize - 1 do
        if Comparator(fItems[I], Vector.fItems[I]) <> 0 then
        begin
          Result := false;
          Break;
        end;
    end;
  end
  else
    Result := false;
end;

{--- TGenVector<_TItem_>.EnumeratorGet ---}
function TGenVector<_TItem_>.EnumeratorGet(const Pos: Integer): _TItem_;
begin
  Result := fItems[Pos];
end;

{--- TGenVector<_TItem_>.EnumeratorNext ---}
function TGenVector<_TItem_>.EnumeratorNext(var Pos: Integer): Boolean;
begin
  Inc(Pos);
  Result := Pos < fSize;
end;

{--- TGenVector<_TItem_>.Fill ---}
procedure TGenVector<_TItem_>.Fill(Index, Count: Integer; const Value: _TItem_);
var
  I: Integer;
begin
  if Count > 0 then
    for I := Index to Index + (Count - 1) do
      fItems[I] := Value;
end;

{--- TGenVector<_TItem_>.FindIndex ---}
function TGenVector<_TItem_>.FindIndex(const Item: _TItem_): Integer;
begin
  Result := FindIndex(Item, fOnCompareItems);
end;

{--- TGenVector<_TItem_>.FindIndex ---}
function TGenVector<_TItem_>.FindIndex(const Item: _TItem_; Comparator: TCompareItems): Integer;
begin
  if fSize = 0 then
    Result := -1
  else
    Result := FindIndex(Item, 0, Comparator);
end;

{--- TGenVector<_TItem_>.FindIndex ---}
function TGenVector<_TItem_>.FindIndex(const Item: _TItem_; PosFrom: Integer): Integer;
begin
  Result := FindIndex(Item, PosFrom, fOnCompareItems);
end;

{--- TGenVector<_TItem_>.FindIndex ---}
function TGenVector<_TItem_>.FindIndex(const Item: _TItem_; PosFrom: Integer; Comparator: TCompareItems): Integer;
var
  I: Integer;
begin
  CheckIndex(PosFrom);

  Result := -1;

  for I := PosFrom to fSize - 1 do
    if Comparator(fItems[I], Item) = 0 then
    begin
      Result := I;
      Break;
    end;
end;

{--- TGenVector<_TItem_>.FirstItem ---}
function TGenVector<_TItem_>.FirstItem: _TItem_;
begin
  if fSize = 0 then
    RaiseContainerEmpty;

  Result := fItems[0];
end;

{--- TGenVector<_TItem_>.GetEnumerator ---}
function TGenVector<_TItem_>.GetEnumerator: TEnumerator;
begin
  Result := TEnumerator.Create(-1, EnumeratorNext, EnumeratorGet);
end;

{--- TGenVector<_TItem_>.GetItem ---}
function TGenVector<_TItem_>.GetItem(Position: Integer): _TItem_;
begin
  CheckIndex(Position);
  Result := fItems[Position];
end;

{--- TGenVector<_TItem_>.GetItemFast ---}
function TGenVector<_TItem_>.GetItemFast(Position: Integer): _TItem_;
begin
  Result := fItems[Position];
end;

{--- TGenVector<_TItem_>.GetItemPtr ---}
function TGenVector<_TItem_>.GetItemPtr(Position: Integer): PItem;
begin
  CheckIndex(Position);
  Result := @fItems[Position];
end;

{--- TGenVector<_TItem_>.GetItemPtrFast ---}
function TGenVector<_TItem_>.GetItemPtrFast(Position: Integer): PItem;
begin
  Result := @fItems[Position];
end;

{--- TGenVector<_TItem_>.Insert ---}
procedure TGenVector<_TItem_>.Insert(Before: Integer; const Item: _TItem_; Count: Integer);
begin
  CheckIndexForAdd(Before);

  if Count > 0 then
  begin
    InsertSpaceFast(Before, Count);
    Fill(Before, Count, Item);
  end;
end;

{--- TGenVector<_TItem_>.InsertAll ---}
procedure TGenVector<_TItem_>.InsertAll(Before: Integer; Src: TGenVector<_TItem_>);
begin
  if Src.fSize > 0 then
    InsertRange(Before, Src, 0, Src.fSize - 1);
end;

{--- TGenVector<_TItem_>.InsertionSort ---}
procedure TGenVector<_TItem_>.InsertionSort(PosFrom, PosTo: Integer; Comparator: TCompareItems);
var
  I, J: Integer;
  Tmp, Item: _TItem_;
begin
  if PosFrom >= PosTo then
     Exit;

  for I := PosFrom + 1 to PosTo do
  begin
    Tmp := fItems[I];

    J := I - 1;
    while (J >= PosFrom) do
    begin
      Item := fItems[J];
      if Comparator(Item, Tmp) <= 0 then
        Break;
      fItems[J + 1] :=  fItems[J];
      Dec(J);
    end;

    fItems[J + 1] := Tmp;
  end;
end;

{--- TGenVector<_TItem_>.Quicksort ---}
procedure TGenVector<_TItem_>.Quicksort(Left, Right: Integer; Comparator: TCompareItems);
var
  I, J: Integer;
  Pivot: _TItem_;
Begin
  if Right - Left <= 15 then
  begin
    InsertionSort(Left, Right, Comparator);
    Exit;
  end;

  I := Left;
  J := Right;
  Pivot := fItems[(Left + Right) div 2];
  repeat
    while Comparator(Pivot, fItems[I]) > 0 do
      Inc(I);

    while Comparator(Pivot, fItems[J]) < 0 do
      Dec(J);

    if I <= J then
    begin
      SwapFast(I, J);
      Dec(J);
      Inc(I);
    end;
  until I > J;

  if Left < J then
    QuickSort(Left, J, Comparator);

  if I < Right then
    QuickSort(I, Right, Comparator);
end;

{--- TGenVector<_TItem_>.InsertRange ---}
procedure TGenVector<_TItem_>.InsertRange(Before: Integer; Src: TGenVector<_TItem_>;
  PosFrom, PosTo: Integer);
var
  Count: Integer;
begin
  CheckIndexForAdd(Before);
  Src.CheckIndex(PosFrom);
  Src.CheckIndex(PosTo);

  Count := PosTo - PosFrom + 1;
  if Count > 0 then
  begin
    InsertSpaceFast(Before, Count);
    RealMove(Src, Self, PosFrom, Before, Count);
  end;
end;

{--- TGenVector<_TItem_>.InsertSpaceFast ---}
procedure TGenVector<_TItem_>.InsertSpaceFast(Position, Count: Integer);
var
  ItemsAfterPos: Integer;
begin
  if Count > 0 then
  begin
    ItemsAfterPos := fSize - Position;
    Resize(fSize + Count);
    if ItemsAfterPos > 0 then
      Move(Position, Position + Count, ItemsAfterPos);
  end;
end;

{--- TGenVector<_TItem_>.ItemToString ---}
function TGenVector<_TItem_>.ItemToString(Index: Integer): String;
begin
  Result := fOnItemToString(fItems[Index]);
end;

{--- TGenVector<_TItem_>.IsSorted ---}
function TGenVector<_TItem_>.IsSorted: Boolean;
begin
  Result := IsSorted(fOnCompareItems);
end;

{--- TGenVector<_TItem_>.IsSorted ---}
function TGenVector<_TItem_>.IsSorted(Comparator: TCompareItems): Boolean;
var
  I: Integer;
begin
  Result := true;

  if fSize > 1 then
    for I := 1 to fSize - 1 do
      if Comparator(fItems[I], fItems[I - 1]) < 0 then
      begin
        Result := false;
        Break;
      end;
end;

{--- TGenVector<_TItem_>.DefaultItemToString ---}
function TGenVector<_TItem_>.DefaultItemToString(const Item: _TItem_): String;
begin
  Unused(@Item);
  RaiseMethodNotRedefined;
  Result := '';
end;

{--- TGenVector<_TItem_>.Iterate ---}
procedure TGenVector<_TItem_>.Iterate(Process: TProcessItem);
begin
  Iterate(Process, 0, fSize - 1);
end;

{--- TGenVector<_TItem_>.Iterate ---}
procedure TGenVector<_TItem_>.Iterate(Process: TProcessItem; const PosFrom, PosTo: Integer);
var
  I: Integer;
  P: PItem;
begin
  CheckIndex(PosFrom);
  CheckIndex(PosTo);

  P := @fItems[PosFrom];
  for I := PosFrom to PosTo do begin
    Process(P^);
    Inc(P);
  end;
end;

{--- TGenVector<_TItem_>.LastItem ---}
function TGenVector<_TItem_>.LastItem: _TItem_;
begin
  if fSize = 0 then
    RaiseContainerEmpty;

  Result := fItems[fSize - 1];
end;

{--- TGenVector<_TItem_>.MaxPos ---}
function TGenVector<_TItem_>.MaxPos(PosFrom, PosTo: Integer): Integer;
begin
  Result := MaxPos(PosFrom, PosTo, fOnCompareItems);
end;

{--- TGenVector<_TItem_>.MaxPos ---}
function TGenVector<_TItem_>.MaxPos(PosFrom, PosTo: Integer; Comparator: TCompareItems): Integer;
var
  I: Integer;
  Max: _TItem_;
begin
  CheckIndex(PosFrom);
  CheckIndex(PosTo);

  if PosTo < PosFrom then
  begin
    I := PosFrom;
    PosFrom := PosTo;
    PosTo := I;
  end;

  Max := fItems[PosFrom];
  Result := PosFrom;
  for I := PosFrom + 1 to PosTo do
    if Comparator(fItems[I], Max) > 0 then
    begin
      Result := I;
      Max := fItems[I];
    end;
end;

{--- TGenVector<_TItem_>.MaxPos ---}
function TGenVector<_TItem_>.MaxPos: Integer;
begin
  Result := MaxPos(fOnCompareItems);
end;

{--- TGenVector<_TItem_>.MaxPos ---}
function TGenVector<_TItem_>.MaxPos(Comparator: TCompareItems): Integer;
begin
  if fSize = 0 then
    RaiseContainerEmpty;

  Result := MaxPos(0, fSize - 1, Comparator);
end;

{--- TGenVector<_TItem_>.Merge ---}
procedure TGenVector<_TItem_>.Merge(Src: TGenVector<_TItem_>);
begin
  Merge(Src, fOnCompareItems);
end;

{--- TGenVector<_TItem_>.Merge ---}
procedure TGenVector<_TItem_>.Merge(Src: TGenVector<_TItem_>; Comparator: TCompareItems);
var
  A, B, C: Integer;
begin
  if Src.fSize = 0 then
    Exit;

  if fSize = 0 then
    AppendAll(Src)
  else if Comparator(Src.FirstItem, LastItem) >= 0 then
    AppendAll(Src)
  else if Comparator(FirstItem, Src.LastItem) >= 0 then
    PrependAll(Src)
  else
  begin
    A := fSize - 1;
    B := Src.fSize - 1;

    InsertSpace(fSize, Src.fSize);
    C := fSize - 1;

    while C > 0 do
    begin
      if Comparator(fItems[A], Src.fItems[B]) > 0 then
      begin
        fItems[C] := fItems[A];
        Dec(A);
        if A < 0 then
          Break;
      end
      else
      begin
        fItems[C] := Src.fItems[B];
        Dec(B);
        if B < 0 then
          Break;
      end;
      Dec(C);
    end;

    if (C >= 0) and (B >= 0) then
      while B >= 0 do
      begin
        fItems[B] := Src.fItems[B];
        Dec(B);
      end;

  end;
  Src.Clear;
end;

{--- TGenVector<_TItem_>.MinPos ---}
function TGenVector<_TItem_>.MinPos(PosFrom, PosTo: Integer): Integer;
begin
  Result := MinPos(PosFrom, PosTo, fOnCompareItems);
end;

{--- TGenVector<_TItem_>.MinPos ---}
function TGenVector<_TItem_>.MinPos(PosFrom, PosTo: Integer; Comparator: TCompareItems): Integer;
var
  I: Integer;
  Min: _TItem_;
begin
  CheckIndex(PosFrom);
  CheckIndex(PosTo);

  if PosTo < PosFrom then
  begin
    I := PosFrom;
    PosFrom := PosTo;
    PosTo := I;
  end;

  Result := -1;
  Min := fItems[PosFrom];
  Result := PosFrom;
  for I := PosFrom + 1 to PosTo do
    if Comparator(fItems[I], Min) < 0 then
    begin
      Result := I;
      Min := fItems[I];
    end;
end;

{--- TGenVector<_TItem_>.MinPos ---}
function TGenVector<_TItem_>.MinPos: Integer;
begin
  Result := MinPos(fOnCompareItems);
end;

{--- TGenVector<_TItem_>.MinPos ---}
function TGenVector<_TItem_>.MinPos(Comparator: TCompareItems): Integer;
begin
  if fSize = 0 then
    RaiseContainerEmpty;

  Result := MinPos(0, fSize - 1, Comparator);
end;

{--- TGenVector<_TItem_>.Move ---}
procedure TGenVector<_TItem_>.Move(Src, Dst, Count: Integer);
begin
  CheckIndex(Src);
  CheckIndex(Dst);

  if Count > 0 then
  begin
    if Src + Count > fSize then
      Count := fSize - Src;

    if Dst + Count > fSize then
      Count := fSize - Dst;

    if Count > 0 then
      RealMove(Self, Self, Src, Dst, Count);
  end;
end;

{--- TGenVector<_TItem_>.Prepend ---}
procedure TGenVector<_TItem_>.Prepend(const Item: _TItem_; Count: Integer);
begin
  Insert(0, Item, Count);
end;

{--- TGenVector<_TItem_>.PrependAll ---}
procedure TGenVector<_TItem_>.PrependAll(Src: TGenVector<_TItem_>);
begin
  InsertAll(0, Src);
end;

{--- TGenVector<_TItem_>.PrependRange ---}
procedure TGenVector<_TItem_>.PrependRange(Src: TGenVector<_TItem_>; PosFrom, PosTo: Integer);
begin
  InsertRange(0, Src, PosFrom, PosTo);
end;

{--- TGenVector<_TItem_>.ReadFirstItem ---}
procedure TGenVector<_TItem_>.ReadFirstItem(out Value: _TItem_);
begin
  if fSize = 0 then
    RaiseContainerEmpty;

  Value := fItems[0];
end;

{--- TGenVector<_TItem_>.ReadItem ---}
procedure TGenVector<_TItem_>.ReadItem(Position: Integer; out Value: _TItem_);
begin
  CheckIndex(Position);
  Value := fItems[Position];
end;

{--- TGenVector<_TItem_>.ReadItemFast ---}
procedure TGenVector<_TItem_>.ReadItemFast(Position: Integer; out Value: _TItem_);
begin
  Value := fItems[Position];
end;

{--- TGenVector<_TItem_>.ReadLastItem ---}
procedure TGenVector<_TItem_>.ReadLastItem(out Value: _TItem_);
begin
  if fSize = 0 then
    RaiseContainerEmpty;

  Value := fItems[fSize - 1];
end;

{--- TGenVector<_TItem_>.Sort ---}
procedure TGenVector<_TItem_>.Sort(PosFrom, PosTo: Integer);
begin
  Sort(PosFrom, PosTo, fOnCompareItems);
end;

{--- TGenVector<_TItem_>.Sort ---}
procedure TGenVector<_TItem_>.Sort(PosFrom, PosTo: Integer; Comparator: TCompareItems);
begin
  CheckIndex(PosFrom);
  CheckIndex(PosTo);

  if PosFrom >= PosTo then
    Exit;

  Quicksort(PosFrom, PosTo, Comparator);
end;

{--- TGenVector<_TItem_>.Sort ---}
procedure TGenVector<_TItem_>.Sort;
begin
  Sort(fOnCompareItems);
end;

{--- TGenVector<_TItem_>.Sort ---}
procedure TGenVector<_TItem_>.Sort(Comparator: TCompareItems);
begin
  if fSize > 1 then
    Sort(0, fSize - 1, Comparator);
end;

{--- TGenVector<_TItem_>.RealMove ---}
class procedure TGenVector<_TItem_>.RealMove(Src, Dst: TGenVector<_TItem_>;
  SrcFirst, DstFirst, Count: Integer);
var
  SrcLast, I, DstCurrent: Integer;
begin
  SrcLast := SrcFirst + Count - 1;
  if (Src = Dst) and ( (DstFirst >= SrcFirst) and (DstFirst <= SrcLast) ) then
  begin
    DstCurrent := DstFirst + Count - 1;
    for I := SrcLast downto SrcFirst do
    begin
      Dst.fItems[DstCurrent] := Src.fItems[I];
      Dec(DstCurrent);
    end
  end
  else
  begin
    DstCurrent := DstFirst;
    for I := SrcFirst to SrcLast do
    begin
      Dst.fItems[DstCurrent] := Src.fItems[I];
      Inc(DstCurrent);
    end;
  end;
end;

{--- TGenVector<_TItem_>.Replace ---}
procedure TGenVector<_TItem_>.Replace(Index, Count: Integer; const Value: _TItem_);
begin
  CheckIndex(Index);

  if Count > 0 then
  begin
    if Index + Count >= fSize then
      Count := fSize - Index;

    if Count > 0 then
      Fill(Index, Count, Value);
  end;
end;

{--- TGenVector<_TItem_>.ReverseFindIndex ---}
function TGenVector<_TItem_>.ReverseFindIndex(const Item: _TItem_): Integer;
begin
  Result := ReverseFindIndex(Item, fOnCompareItems);
end;

{--- TGenVector<_TItem_>.ReverseFindIndex ---}
function TGenVector<_TItem_>.ReverseFindIndex(const Item: _TItem_; Comparator: TCompareItems): Integer;
begin
  if fSize = 0 then
    Result := -1
  else
    Result := ReverseFindIndex(Item, fSize - 1, Comparator);
end;

{--- TGenVector<_TItem_>.ReverseFindIndex ---}
function TGenVector<_TItem_>.ReverseFindIndex(const Item: _TItem_;
  PosFrom: Integer): Integer;
begin
  Result := ReverseFindIndex(Item, PosFrom, fOnCompareItems);
end;

{--- TGenVector<_TItem_>.ReverseFindIndex ---}
function TGenVector<_TItem_>.ReverseFindIndex(const Item: _TItem_;
  PosFrom: Integer; Comparator: TCompareItems): Integer;
var
  I: Integer;
begin
  CheckIndex(PosFrom);

  Result := -1;
  for I := PosFrom downto 0 do
    if Comparator(fItems[I], Item) = 0 then
    begin
      Result := I;
      Break;
    end;
end;

{--- TGenVector<_TItem_>.SetCapacity ---}
procedure TGenVector<_TItem_>.SetCapacity(ACapacity: Integer);
begin
  SetLength(fItems, ACapacity);
  fCapacity := ACapacity;
end;

{--- TGenVector<_TItem_>.SetOnCompareItems ---}
procedure TGenVector<_TItem_>.SetOnCompareItems(AValue: TCompareItems);
begin
  if Assigned(AValue) then
    fOnCompareItems := AValue
  else
    fOnCompareItems := DefaultCompareItems
end;

{--- TGenVector<_TItem_>.SetOnItemToString ---}
procedure TGenVector<_TItem_>.SetOnItemToString(AValue: TItemToString);
begin
  if Assigned(AValue) then
    fOnItemToString := AValue
  else
    fOnItemToString := DefaultItemToString
end;

{--- TGenVector<_TItem_>.SetItem ---}
procedure TGenVector<_TItem_>.SetItem(Position: Integer; const Value: _TItem_);
begin
  CheckIndex(Position);
  fItems[Position] := Value;
end;

{--- TGenVector<_TItem_>.SetItemFast ---}
procedure TGenVector<_TItem_>.SetItemFast(Position: Integer; const Value: _TItem_);
begin
  fItems[Position] := Value;
end;

{--- TGenVector<_TItem_>.SwapFast ---}
procedure TGenVector<_TItem_>.SwapFast(I, J: Integer);
var
  Temp: _TItem_;
begin
  Temp := fItems[I];
  fItems[I] := fItems[J];
  fItems[J] := Temp;
end;

{=================}
{=== TGenDeque ===}
{=================}

{--- TGenDeque<_TItem_>.Append ---}
procedure TGenDeque<_TItem_>.Append(const Item: _TItem_; Count: Integer);
begin
  Insert(fSize, Item, Count);
end;

{--- TGenDeque<_TItem_>.AppendAll ---}
procedure TGenDeque<_TItem_>.AppendAll(Src: TGenDeque<_TItem_>);
begin
  InsertAll(fSize, Src);
end;

{--- TGenDeque<_TItem_>.AppendRange ---}
procedure TGenDeque<_TItem_>.AppendRange(Src: TGenDeque<_TItem_>; PosFrom, PosTo: Integer);
begin
  InsertRange(fSize, Src, PosFrom, PosTo);
end;

{--- TGenDeque<_TItem_>.BinarySearch ---}
function TGenDeque<_TItem_>.BinarySearch(const Item: _TItem_): Integer;
begin
  Result := BinarySearch(Item, fOnCompareItems);
end;

{--- TGenDeque<_TItem_>.BinarySearch ---}
function TGenDeque<_TItem_>.BinarySearch(const Item: _TItem_; Comparator: TCompareItems): Integer;
begin
  if fSize > 0 then
    Result := BinarySearch(Item, 0, fSize - 1, Comparator)
  else
    Result := -1;
end;

{--- TGenDeque<_TItem_>.BinarySearch ---}
function TGenDeque<_TItem_>.BinarySearch(const Item: _TItem_; PosFrom, PosTo: Integer): Integer;
begin
  Result := BinarySearch(Item, PosFrom, PosTo, fOnCompareItems);
end;

{--- TGenDeque<_TItem_>.BinarySearch ---}
function TGenDeque<_TItem_>.BinarySearch(const Item: _TItem_;
  PosFrom, PosTo: Integer; Comparator: TCompareItems): Integer;
var
  Low, Mid, High, Cmp: Integer;
begin
  CheckIndex(PosFrom);
  CheckIndex(PosTo);

  Low := PosFrom;
  Mid := -1;
  High := PosTo;

  while Low <= High do
  begin
    Mid := (Low + High) div 2;
    Cmp := Comparator(fItems[ IndexToRank(Mid) ], Item);

    if Cmp = 0 then
    begin
      Result := Mid;
      Exit;
    end;

    if Cmp < 0 then
      Low := Mid + 1
    else
      High := Mid - 1;
  end;

  if Mid < 0 then
    Result := -1
  else if Comparator(fItems[ IndexToRank(Mid) ], Item) > 0 then
    Result := - Mid - 1
  else
    Result := - Mid - 2;
end;

{--- TGenDeque<_TItem_>.DefaultCompareItems ---}
function TGenDeque<_TItem_>.DefaultCompareItems(const A, B: _TItem_): Integer;
begin
  Unused(@A);
  Unused(@B);
  RaiseMethodNotRedefined;
  Result := 0;
end;

{--- TGenDeque<_TItem_>.Contains ---}
function TGenDeque<_TItem_>.Contains(const Item: _TItem_): Boolean;
begin
  Result := Contains(Item, fOnCompareItems);
end;

{--- TGenDeque<_TItem_>.Contains ---}
function TGenDeque<_TItem_>.Contains(const Item: _TItem_; Comparator: TCompareItems): Boolean;
begin
  Result := (FindIndex(Item, Comparator) >= 0);
end;

{--- TGenDeque<_TItem_>.Create ---}
constructor TGenDeque<_TItem_>.Create(InitialCapacity: Integer);
begin
  fSize := 0;

  if InitialCapacity < 0 then
    InitialCapacity := 16;

  fCapacity := InitialCapacity;
  SetLength(fItems, fCapacity);

  fStart := 0;

  SetOnCompareItems(nil);
  SetOnItemToString(nil);
end;

{--- TGenDeque<_TItem_>.Destroy ---}
destructor TGenDeque<_TItem_>.Destroy;
begin
  SetLength(fItems, 0);
  inherited Destroy;
end;

{--- TGenDeque<_TItem_>.DecRank ---}
procedure TGenDeque<_TItem_>.DecRank(var Rank: Integer);
begin
  if Rank = 0 then
    Rank := fCapacity - 1
  else
    Dec(Rank);
end;

{--- TGenDeque<_TItem_>.Equals ---}
function TGenDeque<_TItem_>.Equals(Deque: TGenDeque<_TItem_>; Comparator: TCompareItems): Boolean;
var
  I, IRank, JRank: Integer;
begin
  if fSize <> Deque.fSize then
    Result := false
  else
  begin
    Result := true;
    IRank := fStart;
    JRank := Deque.fStart;
    for I := 0 to fSize - 1 do
    begin
      if Comparator(fItems[IRank], Deque.fItems[JRank]) <> 0 then
      begin
        Result := false;
        Break;
      end;
      IncRank(IRank);
      Deque.IncRank(JRank);
    end;
  end;
end;

{--- TGenDeque<_TItem_>.EnumeratorGet ---}
function TGenDeque<_TItem_>.EnumeratorGet(const Pos: Integer): _TItem_;
begin
  Result := fItems[ IndexToRank(Pos) ];
end;

{--- TGenDeque<_TItem_>.EnumeratorNext ---}
function TGenDeque<_TItem_>.EnumeratorNext(var Pos: Integer): Boolean;
begin
  Inc(Pos);
  Result := Pos < fSize;
end;

{--- TGenDeque<_TItem_>.Equals ---}
function TGenDeque<_TItem_>.Equals(Obj: TObject): Boolean;
begin
  Result := Equals(Obj, fOnCompareItems);
end;

{--- TGenDeque<_TItem_>.Equals ---}
function TGenDeque<_TItem_>.Equals(Obj: TObject; Comparator: TCompareItems): Boolean;
begin
  if Obj = Self  then
    Result := true
  else if Obj is TGenDeque<_TItem_> then
    Result := Equals(Obj as TGenDeque<_TItem_>, Comparator)
  else
    Result := false;
end;

{--- TGenDeque<_TItem_>.FindIndex ---}
function TGenDeque<_TItem_>.FindIndex(const Item: _TItem_): Integer;
begin
  Result := FindIndex(Item, fOnCompareItems);
end;

{--- TGenDeque<_TItem_>.FindIndex ---}
function TGenDeque<_TItem_>.FindIndex(const Item: _TItem_; Comparator: TCompareItems): Integer;
begin
  if fSize = 0 then
    Result := -1
  else
    Result := FindIndex(Item, 0, Comparator);
end;

{--- TGenDeque<_TItem_>.Fill ---}
procedure TGenDeque<_TItem_>.Fill(Index, Count: Integer; const Value: _TItem_);
begin
  Index := IndexToRank(Index);
  while Count > 0 do
  begin
    fItems[Index] := Value;
    IncRank(Index);
    Dec(Count);
  end;
end;

{--- TGenDeque<_TItem_>.FindIndex ---}
function TGenDeque<_TItem_>.FindIndex(const Item: _TItem_; PosFrom: Integer): Integer;
begin
  Result := FindIndex(Item, PosFrom, fOnCompareItems);
end;

{--- TGenDeque<_TItem_>.FindIndex ---}
function TGenDeque<_TItem_>.FindIndex(const Item: _TItem_; PosFrom: Integer; Comparator: TCompareItems): Integer;
var
  I, Pos: Integer;
begin
  CheckIndex(PosFrom);

  Result := -1;
  Pos := IndexToRank(PosFrom);
  for I := PosFrom to fSize - 1 do
  begin
    if Comparator(fItems[Pos], Item) = 0 then
    begin
      Result := I;
      Break;
    end;
    IncRank(Pos);
  end;
end;

{--- TGenDeque<_TItem_>.FirstItem ---}
function TGenDeque<_TItem_>.FirstItem: _TItem_;
begin
  if fSize = 0 then
    RaiseContainerEmpty;

  Result := fItems[fStart];
end;

{--- TGenDeque<_TItem_>.GetEnumerator ---}
function TGenDeque<_TItem_>.GetEnumerator: TEnumerator;
begin
  Result := TEnumerator.Create(-1, EnumeratorNext, EnumeratorGet);
end;

{--- TGenDeque<_TItem_>.GetItem ---}
function TGenDeque<_TItem_>.GetItem(Position: Integer): _TItem_;
begin
  CheckIndex(Position);
  Result := fItems[ IndexToRank(Position)];
end;

{--- TGenDeque<_TItem_>.GetItemPtr ---}
function TGenDeque<_TItem_>.GetItemPtr(Position: Integer): PItem;
begin
  CheckIndex(Position);
  Result := @fItems[ IndexToRank(Position)];
end;

{--- TGenDeque<_TItem_>.GetItemFast ---}
function TGenDeque<_TItem_>.GetItemFast(Position: Integer): _TItem_;
begin
  Result := fItems[ IndexToRank(Position) ];
end;

{--- TGenDeque<_TItem_>.GetItemPtrFast ---}
function TGenDeque<_TItem_>.GetItemPtrFast(Position: Integer): PItem;
begin
  Result := @fItems[ IndexToRank(Position) ];
end;

{--- TGenDeque<_TItem_>.IncRank ---}
procedure TGenDeque<_TItem_>.IncRank(var Rank: Integer);
begin
  if Rank = fCapacity - 1 then
    Rank := 0
  else
    Inc(Rank);
end;

{--- TGenDeque<_TItem_>.IncreaseCapacity ---}
procedure TGenDeque<_TItem_>.IncreaseCapacity(ACapacity: Integer);
var
  Dst: Integer;
  ItemsAtBegining, ItemsAtEnd: Integer;
begin
  SetLength(fItems, ACapacity);

  if fStart + fSize >= fCapacity then { Are items in 2 parts ? }
  begin
    ItemsAtEnd := fCapacity - fStart;
    ItemsAtBegining := fSize - ItemsAtEnd;

    if ItemsAtEnd < ItemsAtBegining then
    begin
      Dst := ACapacity - ItemsAtEnd;
      RealMoveRank(fStart, Dst, ItemsAtEnd);
      fStart := Dst;
    end
    else
    begin
      Dst := fStart + ItemsAtEnd;
      RealMoveRank(0, Dst, ItemsAtBegining);
    end;
  end;

  fCapacity := ACapacity;
end;

{--- TGenDeque<_TItem_>.IndexToRank ---}
function TGenDeque<_TItem_>.IndexToRank(Index: Integer): Integer;
var
  AtEnd: Integer;
begin
  AtEnd := fCapacity - fStart;
  if Index < AtEnd then
    Result := fStart + Index
  else
    Result := Index - AtEnd;
end;

{--- TGenDeque<_TItem_>.Insert ---}
procedure TGenDeque<_TItem_>.Insert(Before: Integer; const Item: _TItem_; Count: Integer);
begin
  CheckIndexForAdd(Before);

  if Count <= 0 then
    Exit;

  InsertSpaceFast(Before, Count);
  Fill(Before, Count, Item);
end;

{--- TGenDeque<_TItem_>.InsertAll ---}
procedure TGenDeque<_TItem_>.InsertAll(Before: Integer; Src: TGenDeque<_TItem_>);
begin
  if Src.fSize > 0 then
    InsertRange(Before, Src, 0, Src.fSize - 1);
end;

{--- TGenDeque<_TItem_>.InsertionSort ---}
procedure TGenDeque<_TItem_>.InsertionSort(PosFrom, PosTo: Integer; Comparator: TCompareItems);
var
  I, J: Integer;
  IRank, JRank, NextJRank: Integer;
  Tmp, Item: _TItem_;
begin
  if PosFrom >= PosTo then
     Exit;

  IRank := IndexToRank(PosFrom + 1);
  for I := PosFrom + 1 to PosTo do
  begin
    Tmp := fItems[IRank];

    J := I - 1;
    JRank := IRank;
    DecRank(JRank);
    while (J >= PosFrom) do
    begin
      Item := fItems[JRank];
      if Comparator(Item, Tmp) <= 0 then
        Break;
      NextJRank := JRank;
      IncRank(NextJRank);
      fItems[NextJRank] :=  fItems[JRank];
      Dec(J);
      DecRank(JRank);
    end;

    fItems[IndexToRank(J + 1)] := Tmp;
    IncRank(IRank);
  end;
end;

{--- TGenDeque<_TItem_>.Quicksort ---}
procedure TGenDeque<_TItem_>.Quicksort(Left, Right: Integer; Comparator: TCompareItems);
var
  I, J: Integer;
  Pivot: _TItem_;
Begin
  if Right - Left <= 15 then
  begin
    InsertionSort(Left, Right, Comparator);
    Exit;
  end;

  I := Left;
  J := Right;
  Pivot := fItems[ IndexToRank((Left + Right) div 2) ];
  repeat
    while Comparator(Pivot, fItems[IndexToRank(I)]) > 0 do
      Inc(I);

    while Comparator(Pivot, fItems[IndexToRank(J)]) < 0 do
      Dec(J);

    if I <= J then
    begin
      SwapFast(I, J);
      Dec(J);
      Inc(I);
    end;
  until I > J;

  if Left < J then
    QuickSort(Left, J, Comparator);

  if I < Right then
    QuickSort(I, Right, Comparator);
end;

{--- TGenDeque<_TItem_>.InsertRange ---}
procedure TGenDeque<_TItem_>.InsertRange(Before: Integer; Src: TGenDeque<_TItem_>;
  PosFrom, PosTo: Integer);
var
  Count: Integer;
begin
  CheckIndexForAdd(Before);
  Src.CheckIndex(PosFrom);
  Src.CheckIndex(PosTo);

  Count := PosTo - PosFrom + 1;
  if Count > 0 then
  begin
    InsertSpaceFast(Before, Count);
    RealMoveIndex(Src, Self, PosFrom, Before, Count);
  end;
end;

{--- TGenDeque<_TItem_>.InsertSpaceFast ---}
procedure TGenDeque<_TItem_>.InsertSpaceFast(Position, Count: Integer);
var
  Rank: Integer;
  NewStart: Integer;
  ItemsToMove: Integer;
begin
  if Count <= 0 then
    Exit;

  if Position = 0 then
  begin
    Resize(fSize + Count);

    NewStart := fStart - Count;
    if NewStart < 0 then
      fStart := fCapacity + NewStart
    else
      fStart := NewStart;
  end
  else if Position = fSize then
  begin
    Resize(fSize + Count);
  end
  else
  begin
    Resize(fSize + Count);
    Rank := IndexToRank(Position);

    if (Rank >= fStart) and (fStart + fSize > fCapacity) then
    begin
      ItemsToMove := Rank - fStart;
      if ItemsToMove > 0 then
        RealMoveRank(fStart, fStart - Count , ItemsToMove);
      fStart := fStart - Count;
    end
    else
    begin
      ItemsToMove :=  fSize - Position - Count;

      if ItemsToMove > 0 then
        RealMoveRank(Rank, Rank + Count, ItemsToMove)
    end;
  end;
end;

{--- TGenDeque<_TItem_>.ItemToString ---}
function TGenDeque<_TItem_>.ItemToString(Index: Integer): String;
begin
  Result := fOnItemToString(fItems[IndexToRank(Index)]);
end;

{--- TGenDeque<_TItem_>.IsSorted ---}
function TGenDeque<_TItem_>.IsSorted: Boolean;
begin
  Result := IsSorted(fOnCompareItems);
end;

{--- TGenDeque<_TItem_>.IsSorted ---}
function TGenDeque<_TItem_>.IsSorted(Comparator: TCompareItems): Boolean;
var
  I, Rank, PrevRank: Integer;
begin
  Result := true;

  if fSize > 1 then
  begin
    PrevRank := fStart;
    Rank := IndexToRank(1);
    for I := 1 to fSize - 1 do
    begin
      if Comparator(fItems[Rank], fItems[PrevRank]) < 0 then
      begin
        Result := false;
        Break;
      end;
      PrevRank := Rank;
      IncRank(Rank);
    end;
  end;
end;

{--- TGenDeque<_TItem_>.DefaultItemToString ---}
function TGenDeque<_TItem_>.DefaultItemToString(const Item: _TItem_): String;
begin
  Unused(@Item);
  RaiseMethodNotRedefined;
  Result := '';
end;

{--- TGenDeque<_TItem_>.Iterate ---}
procedure TGenDeque<_TItem_>.Iterate(Process: TProcessItem);
begin
  Iterate(Process, 0, fSize - 1);
end;

{--- TGenDeque<_TItem_>.Iterate ---}
procedure TGenDeque<_TItem_>.Iterate(Process: TProcessItem; const PosFrom, PosTo: Integer);
var
  I, Rank: Integer;
begin
  CheckIndex(PosFrom);
  CheckIndex(PosTo);

  Rank := IndexToRank(PosFrom);
  for I := PosFrom to PosTo do
  begin
    Process(fItems[Rank]);
    IncRank(Rank);
  end;
end;

{--- TGenDeque<_TItem_>.LastItem ---}
function TGenDeque<_TItem_>.LastItem: _TItem_;
begin
  if fSize = 0 then
    RaiseContainerEmpty;

  Result := fItems[ IndexToRank(fSize - 1) ];
end;

{--- TGenDeque<_TItem_>.MaxPos ---}
function TGenDeque<_TItem_>.MaxPos(PosFrom, PosTo: Integer): Integer;
begin
  Result := MaxPos(PosFrom, PosTo, fOnCompareItems);
end;

{--- TGenDeque<_TItem_>.MaxPos ---}
function TGenDeque<_TItem_>.MaxPos(PosFrom, PosTo: Integer; Comparator: TCompareItems): Integer;
var
  I, IRank: Integer;
  Max: _TItem_;
begin
  CheckIndex(PosFrom);
  CheckIndex(PosTo);

  if PosTo < PosFrom then
  begin
    I := PosFrom;
    PosFrom := PosTo;
    PosTo := I;
  end;

  Max := fItems[ IndexToRank(PosFrom) ];
  Result := PosFrom;
  IRank := IndexToRank(PosFrom + 1);
  for I := PosFrom + 1 to PosTo do
  begin
    if Comparator(fItems[IRank], Max) > 0 then
    begin
      Result := I;
      Max := fItems[IRank];
    end;
    IncRank(IRank);
  end;
end;

{--- TGenDeque<_TItem_>.MaxPos ---}
function TGenDeque<_TItem_>.MaxPos: Integer;
begin
  Result := MaxPos(fOnCompareItems);
end;

{--- TGenDeque<_TItem_>.MaxPos ---}
function TGenDeque<_TItem_>.MaxPos(Comparator: TCompareItems): Integer;
begin
  if fSize = 0 then
    RaiseContainerEmpty;

  Result := MaxPos(0, fSize - 1, Comparator);
end;

{--- TGenDeque<_TItem_>.Merge ---}
procedure TGenDeque<_TItem_>.Merge(Src: TGenDeque<_TItem_>);
begin
  Merge(Src, fOnCompareItems);
end;

{--- TGenDeque<_TItem_>.Merge ---}
procedure TGenDeque<_TItem_>.Merge(Src: TGenDeque<_TItem_>; Comparator: TCompareItems);
var
  A, B, C: Integer;
  ARank, BRank, CRank: Integer;
begin
  if Src.fSize = 0 then
    Exit;

  if fSize = 0 then
    AppendAll(Src)
  else if Comparator(Src.FirstItem, LastItem) >= 0 then
    AppendAll(Src)
  else if Comparator(FirstItem, Src.LastItem) >= 0 then
    PrependAll(Src)
  else
  begin
    A := fSize - 1;
    B := Src.fSize - 1;

    InsertSpace(fSize, Src.fSize);
    C := fSize - 1;

    ARank := IndexToRank(A);
    BRank := Src.IndexToRank(B);
    CRank := IndexToRank(C);

    while C > 0 do
    begin
      if Comparator(fItems[ARank], Src.fItems[BRank]) > 0 then
      begin
        fItems[CRank] := fItems[ARank];
        Dec(A);
        if A < 0 then
          Break;
        DecRank(ARank);
      end
      else
      begin
        fItems[CRank] := Src.fItems[BRank];
        Dec(B);
        if B < 0 then
          Break;
        Src.DecRank(BRank);
      end;
      Dec(C);
      DecRank(CRank);
    end;

    if (C >= 0) and (B >= 0) then
    begin
      BRank := Src.IndexToRank(B);
      ARank := IndexToRank(B);
      while B >= 0 do
      begin
        fItems[ARank] := Src.fItems[BRank];
        Dec(B);
        DecRank(BRank);
        DecRank(ARank);
      end;
    end;

  end;
  Src.Clear;
end;

{--- TGenDeque<_TItem_>.MinPos ---}
function TGenDeque<_TItem_>.MinPos(PosFrom, PosTo: Integer): Integer;
begin
  Result := MinPos(PosFrom, PosTo, fOnCompareItems);
end;

{--- TGenDeque<_TItem_>.MinPos ---}
function TGenDeque<_TItem_>.MinPos(PosFrom, PosTo: Integer; Comparator: TCompareItems): Integer;
var
  I, IRank: Integer;
  Min: _TItem_;
begin
  CheckIndex(PosFrom);
  CheckIndex(PosTo);

  if PosTo < PosFrom then
  begin
    I := PosFrom;
    PosFrom := PosTo;
    PosTo := I;
  end;

  Result := -1;
  Min := fItems[ IndexToRank(PosFrom) ];
  Result := PosFrom;
  IRank := IndexToRank(PosFrom + 1);
  for I := PosFrom + 1 to PosTo do
  begin
    if Comparator(fItems[IRank], Min) < 0 then
    begin
      Result := I;
      Min := fItems[IRank];
    end;
    IncRank(IRank);
  end;
end;

{--- TGenDeque<_TItem_>.MinPos ---}
function TGenDeque<_TItem_>.MinPos: Integer;
begin
  Result := MinPos(fOnCompareItems);
end;

{--- TGenDeque<_TItem_>.MinPos ---}
function TGenDeque<_TItem_>.MinPos(Comparator: TCompareItems): Integer;
begin
  if fSize = 0 then
    RaiseContainerEmpty;

  Result := MinPos(0, fSize - 1, Comparator);
end;

{--- TGenDeque<_TItem_>.Move ---}
procedure TGenDeque<_TItem_>.Move(Src, Dst, Count: Integer);
var
  I: Integer;
begin
  CheckIndex(Src);
  CheckIndex(Dst);

  if Src + Count > fSize then
    Count := fSize - Src;

  if Dst + Count > fSize then
    Count := fSize - Dst;

  if Count > 0 then
  begin
    if (Dst >= Src) and (Dst <= Src + Count - 1) then
    begin
      Dst := Dst + Count - 1;
      Src := Src + Count - 1;

      Dst := IndexToRank(Dst);
      Src := IndexToRank(Src);

      for I := 1 to Count do
      begin
        fItems[Dst] := fItems[Src];
        DecRank(Src);
        DecRank(Dst);
      end;
    end
    else
    begin
      Dst := IndexToRank(Dst);
      Src := IndexToRank(Src);

      for I := 1 to Count do
      begin
        fItems[Dst] := fItems[Src];
        IncRank(Src);
        IncRank(Dst);
      end;
    end;
  end;
end;

{--- TGenDeque<_TItem_>.Prepend ---}
procedure TGenDeque<_TItem_>.Prepend(const Item: _TItem_; Count: Integer);
begin
  Insert(0, Item, Count);
end;

{--- TGenDeque<_TItem_>.PrependAll ---}
procedure TGenDeque<_TItem_>.PrependAll(Src: TGenDeque<_TItem_>);
begin
  InsertAll(0, Src);
end;

{--- TGenDeque<_TItem_>.PrependRange ---}
procedure TGenDeque<_TItem_>.PrependRange(Src: TGenDeque<_TItem_>; PosFrom, PosTo: Integer);
begin
  InsertRange(0, Src, PosFrom, PosTo);
end;

{--- TGenDeque<_TItem_>.ReadFirstItem ---}
procedure TGenDeque<_TItem_>.ReadFirstItem(out Value: _TItem_);
begin
  if fSize = 0 then
    RaiseContainerEmpty;

  Value := fItems[fStart];
end;

{--- TGenDeque<_TItem_>.ReadItem ---}
procedure TGenDeque<_TItem_>.ReadItem(Position: Integer; out Value: _TItem_);
begin
  CheckIndex(Position);
  Value := fItems[ IndexToRank(Position)];
end;

{--- TGenDeque<_TItem_>.ReadItemFast ---}
procedure TGenDeque<_TItem_>.ReadItemFast(Position: Integer; out Value: _TItem_);
begin
  Value := fItems[ IndexToRank(Position)];
end;

{--- TGenDeque<_TItem_>.ReadLastItem ---}
procedure TGenDeque<_TItem_>.ReadLastItem(out Value: _TItem_);
begin
  if fSize = 0 then
    RaiseContainerEmpty;

  Value := fItems[ IndexToRank(fSize - 1) ];
end;

{--- TGenDeque<_TItem_>.Sort ---}
procedure TGenDeque<_TItem_>.Sort(PosFrom, PosTo: Integer);
begin
  Sort(PosFrom, PosTo, fOnCompareItems);
end;

{--- TGenDeque<_TItem_>.Sort ---}
procedure TGenDeque<_TItem_>.Sort(PosFrom, PosTo: Integer; Comparator: TCompareItems);
begin
  CheckIndex(PosFrom);
  CheckIndex(PosTo);

  if PosFrom >= PosTo then
    Exit;

  Quicksort(PosFrom, PosTo, Comparator);
end;

{--- TGenDeque<_TItem_>.Sort ---}
procedure TGenDeque<_TItem_>.Sort;
begin
  Sort(fOnCompareItems);
end;

{--- TGenDeque<_TItem_>.Sort ---}
procedure TGenDeque<_TItem_>.Sort(Comparator: TCompareItems);
begin
  if fSize > 1 then
    Sort(0, fSize - 1, Comparator);
end;

{--- TGenDeque<_TItem_>.RealMoveRank ---}
procedure TGenDeque<_TItem_>.RealMoveRank(Src, Dst, Count: Integer);
var
  SrcLast, I, DstCurrent: Integer;
begin
  if Count <= 0 then
    Exit;

  SrcLast := Src + Count - 1;
  if (Dst >= Src) and (Dst <= SrcLast) then
  begin
    DstCurrent := Dst + Count - 1;
    for I := SrcLast downto Src do
    begin
      fItems[DstCurrent] := fItems[I];
      Dec(DstCurrent);
    end
  end
  else
  begin
    DstCurrent := Dst;
    for I := Src to SrcLast do
    begin
      fItems[DstCurrent] := fItems[I];
      Inc(DstCurrent);
    end;
  end;
end;

{--- TGenDeque<_TItem_>.RealMoveIndex ---}
class procedure TGenDeque<_TItem_>.RealMoveIndex(Src, Dst: TGenDeque<_TItem_>;
  SrcFirst, DstFirst, Count: Integer);
var
  SrcLast, I, DstCurrent: Integer;
begin
  SrcLast := SrcFirst + Count - 1;
  if (Src = Dst) and ( (DstFirst >= SrcFirst) and (DstFirst <= SrcLast) ) then
  begin
    DstCurrent := DstFirst + Count - 1;
    for I := SrcLast downto SrcFirst do
    begin
      Dst[DstCurrent] := Src[I];
      Dec(DstCurrent);
    end
  end
  else
  begin
    DstCurrent := DstFirst;
    for I := SrcFirst to SrcLast do
    begin
      Dst[DstCurrent] := Src[I];
      Inc(DstCurrent);
    end;
  end;
end;

{--- TGenDeque<_TItem_>.ReduceCapacity ---}
procedure TGenDeque<_TItem_>.ReduceCapacity(ACapacity: Integer);
var
  NewStart, ItemsAtEnd: Integer;
begin
  if fStart + fSize >= fCapacity then
  begin
    ItemsAtEnd := fCapacity - fStart;
    NewStart := ACapacity - ItemsAtEnd;
    RealMoveRank(fStart, NewStart, ItemsAtEnd);
    fStart := NewStart;
  end;

  SetLength(fItems, ACapacity);
  fCapacity := ACapacity;
end;

{--- TGenDeque<_TItem_>.Replace ---}
procedure TGenDeque<_TItem_>.Replace(Index, Count: Integer; const Value: _TItem_);
begin
  CheckIndex(Index);

  if Count > 0 then
  begin
    if Index + Count >= fSize then
      Count := fSize - Index;
    Fill(Index, Count, Value);
  end;
end;

{--- TGenDeque<_TItem_>.ReverseFindIndex ---}
function TGenDeque<_TItem_>.ReverseFindIndex(const Item: _TItem_): Integer;
begin
  Result := ReverseFindIndex(Item, fOnCompareItems);
end;

{--- TGenDeque<_TItem_>.ReverseFindIndex ---}
function TGenDeque<_TItem_>.ReverseFindIndex(const Item: _TItem_; Comparator: TCompareItems): Integer;
begin
  if fSize = 0 then
    Result := -1
  else
    Result := ReverseFindIndex(Item, fSize - 1, Comparator);
end;

{--- TGenDeque<_TItem_>.ReverseFindIndex ---}
function TGenDeque<_TItem_>.ReverseFindIndex(const Item: _TItem_; PosFrom: Integer): Integer;
begin
  Result := ReverseFindIndex(Item, PosFrom, fOnCompareItems);
end;

{--- TGenDeque<_TItem_>.ReverseFindIndex ---}
function TGenDeque<_TItem_>.ReverseFindIndex(const Item: _TItem_;
  PosFrom: Integer; Comparator: TCompareItems): Integer;
var
  I, Pos: Integer;
begin
  CheckIndex(PosFrom);

  Result := -1;
  Pos := IndexToRank(PosFrom);
  for I := PosFrom downto 0 do
  begin
    if Comparator(fItems[Pos], Item) = 0 then
    begin
      Result := I;
      Break;
    end;
    DecRank(Pos);
  end;
end;

{--- TGenDeque<_TItem_>.SetCapacity ---}
procedure TGenDeque<_TItem_>.SetCapacity(ACapacity: Integer);
begin
  if ACapacity <= fCapacity then
    ReduceCapacity(ACapacity)
  else if ACapacity > fCapacity then
    IncreaseCapacity(ACapacity);
end;

{--- TGenDeque<_TItem_>.SetOnCompareItems ---}
procedure TGenDeque<_TItem_>.SetOnCompareItems(AValue: TCompareItems);
begin
  if Assigned(AValue) then
    fOnCompareItems := AValue
  else
    fOnCompareItems := DefaultCompareItems
end;

{--- TGenDeque<_TItem_>.SetOnItemToString ---}
procedure TGenDeque<_TItem_>.SetOnItemToString(AValue: TItemToString);
begin
  if Assigned(AValue) then
    fOnItemToString := AValue
  else
    fOnItemToString := DefaultItemToString
end;

{--- TGenDeque<_TItem_>.SetItem ---}
procedure TGenDeque<_TItem_>.SetItem(Position: Integer; const Value: _TItem_);
begin
  CheckIndex(Position);
  fItems[ IndexToRank(Position) ] := Value;
end;

{--- TGenDeque<_TItem_>.SetItemFast ---}
procedure TGenDeque<_TItem_>.SetItemFast(Position: Integer; const Value: _TItem_);
begin
  fItems[ IndexToRank(Position) ] := Value;
end;

{--- TGenDeque<_TItem_>.SwapFast ---}
procedure TGenDeque<_TItem_>.SwapFast(I, J: Integer);
var
  Temp: _TItem_;
begin
  I := IndexToRank(I);
  J := IndexToRank(J);

  Temp := fItems[I];
  fItems[I] := fItems[J];
  fItems[J] := Temp;
end;

{===================}
{=== TListCursor ===}
{===================}

{--- TListCursor.Equals ---}
function TListCursor.Equals(const Cursor: TListCursor): Boolean;
begin
  Result := (fList = Cursor.fList) and (fNode = Cursor.fNode);
end;

{--- TListCursor.HasItem ---}
function TListCursor.HasItem: Boolean;
begin
  Result := (fNode <> nil);
end;

{--- TListCursor.Init ---}
constructor TListCursor.Init(AList: TAbstractList; ANode: Pointer);
begin
  fList := AList;
  fNode := ANode;
end;

{--- TListCursor.IsFirst ---}
function TListCursor.IsFirst: Boolean;
begin
  Result := fList.CursorIsFirst(Self);
end;

{--- TListCursor.IsLast ---}
function TListCursor.IsLast: Boolean;
begin
  Result := fList.CursorIsLast(Self);
end;

{--- TListCursor.IsNil ---}
function TListCursor.IsNil: Boolean;
begin
  Result := (fNode = nil);
end;

{--- TListCursor.MoveNext ---}
procedure TListCursor.MoveNext;
begin
  fList.CursorMoveNext(Self);
end;

{--- TListCursor.MovePrevious ---}
procedure TListCursor.MovePrevious;
begin
  fList.CursorMovePrev(Self);
end;

{=====================}
{=== TAbstractList ===}
{=====================}

{--- TAbstractList.CheckValid ---}
procedure TAbstractList.CheckValid(const Cursor: TListCursor);
begin
  if Cursor.List <> Self then
    RaiseCursorDenotesWrongContainer;
end;

{--- TAbstractList.CheckNotNil ---}
procedure TAbstractList.CheckNotNil(const Cursor: TListCursor);
begin
  CheckValid(Cursor);
  if Cursor.IsNil then
    RaiseCursorIsNil;
end;

{================}
{=== TGenList ===}
{================}

{--- TGenList<_TItem_>.Append ---}
procedure TGenList<_TItem_>.Append(const Item: _TItem_; Count: Integer);
begin
  Insert(fNilCursor, Item, Count);
end;

{--- TGenList<_TItem_>.AppendAll ---}
procedure TGenList<_TItem_>.AppendAll(Src: TGenList<_TItem_>);
begin
  InsertAll(fNilCursor, Src);
end;

{--- TGenList<_TItem_>.AppendRange ---}
procedure TGenList<_TItem_>.AppendRange(Src: TGenList<_TItem_>; const PosFrom, PosTo: TListCursor);
begin
  InsertRange(fNilCursor, Src, PosFrom, PosTo);
end;

{--- TGenList<_TItem_>.Clear ---}
procedure TGenList<_TItem_>.Clear;
begin
  DeleteFirst(fSize);
end;

{--- TGenList<_TItem_>.DefaultCompareItems ---}
function TGenList<_TItem_>.DefaultCompareItems(const A, B: _TItem_): Integer;
begin
  Unused(@A);
  Unused(@B);
  RaiseMethodNotRedefined;
  Result := 0;
end;

{--- TGenList<_TItem_>.Contains ---}
function TGenList<_TItem_>.Contains(const Item: _TItem_): Boolean;
begin
  Result := Contains(Item, fOnCompareItems);
end;

{--- TGenList<_TItem_>.Contains ---}
function TGenList<_TItem_>.Contains(const Item: _TItem_; Comparator: TCompareItems): Boolean;
begin
  Result := not Find(Item, Comparator).IsNil;
end;

{--- TGenList<_TItem_>.Create ---}
constructor TGenList<_TItem_>.Create;
begin
  inherited Create;

  New(fHead);
  New(fTail);
  fHead^.Next := fTail;
  fTail^.Previous := fHead;

  fNilCursor.Init(Self, nil);

  SetOnCompareItems(nil);
  SetOnItemToString(nil);
end;

{--- TGenList<_TItem_>.Delete ---}
procedure TGenList<_TItem_>.Delete(var Position: TListCursor; Count: Integer);
begin
  CheckNotNil(Position);
  DeleteNodesForward(PNode(Position.Node), Count);
  Position := fNilCursor;
end;

{--- TGenList<_TItem_>.DeleteFirst ---}
procedure TGenList<_TItem_>.DeleteFirst(Count: Integer);
begin
  if (fSize > 0) and (Count > 0) then
    DeleteNodesForward(fHead^.Next, Count);
end;

{--- TGenList<_TItem_>.DeleteLast ---}
procedure TGenList<_TItem_>.DeleteLast(Count: Integer);
begin
  if (fSize > 0) and (Count > 0) then
    DeleteNodesBackward(fTail^.Previous, Count);
end;

{--- TGenList<_TItem_>.DeleteNodesBackward ---}
procedure TGenList<_TItem_>.DeleteNodesBackward(From: PNode; Count: Integer);
var
  Current, AfterFrom: PNode;
begin
  AfterFrom := From^.Next;

  Current := From;
  while (Count > 0) and (Current <> fHead) do
  begin
    Current^.Previous^.Next := AfterFrom;
    AfterFrom^.Previous := Current^.Previous;

    Dispose(Current);
    Dec(fSize);
    Dec(Count);
    Current := AfterFrom^.Previous;
  end;
end;

{--- TGenList<_TItem_>.DeleteNodesBetween ---}
procedure TGenList<_TItem_>.DeleteNodesBetween(NodeFrom, NodeTo: PNode);
var
  Current, Previous, Limit: PNode;
begin
  Current := NodeFrom;
  Previous := Current^.Previous;
  Limit := NodeTo^.Next;

  while Current <> Limit do
  begin
    Previous^.Next := Current^.Next;
    Current^.Next^.Previous := Previous;

    Dispose(Current);
    Dec(fSize);
    Current := Previous^.Next;
  end;
end;

{--- TGenList<_TItem_>.DeleteNodesForward ---}
procedure TGenList<_TItem_>.DeleteNodesForward(From: PNode; Count: Integer);
var
  Current, BeforeFrom: PNode;
begin
  BeforeFrom := From^.Previous;
  Current := From;
  while (Count > 0) and (Current <> fTail) do
  begin
    BeforeFrom^.Next := Current^.Next;
    Current^.Next^.Previous := BeforeFrom;

    Dispose(Current);
    Dec(fSize);
    Dec(Count);
    Current := BeforeFrom^.Next;
  end;
end;

{--- TGenList<_TItem_>.EnumeratorGet ---}
function TGenList<_TItem_>.EnumeratorGet(const Pos: TListCursor): _TItem_;
begin
  ReadItemFast(Pos, Result);
end;

{--- TGenList<_TItem_>.EnumeratorNext ---}
function TGenList<_TItem_>.EnumeratorNext(var Pos: TListCursor): Boolean;
begin
  if Pos.IsNil then
    Pos := First
  else
    Pos.MoveNext;
  Result := Pos.HasItem;
end;

{--- TGenList<_TItem_>.DeleteRange ---}
procedure TGenList<_TItem_>.DeleteRange(const PosFrom, PosTo: TListCursor);
begin
  CheckNotNil(PosFrom);
  CheckNotNil(PosTo);
  DeleteNodesBetween(PosFrom.Node, PosTo.Node);
end;

{--- TGenList<_TItem_>.Destroy ---}
destructor TGenList<_TItem_>.Destroy;
begin
  Clear;
  Dispose(fHead);
  Dispose(fTail);
  inherited Destroy;
end;

{--- TGenList<_TItem_>.Equals ---}
function TGenList<_TItem_>.Equals(List: TGenList<_TItem_>; Comparator: TCompareItems): Boolean;
var
  N1, N2: PNode;
begin
  if fSize <> List.fSize then
  begin
    Result := false;
    Exit;
  end;

  Result := true;
  N1 := fHead^.Next;
  N2 := List.fHead^.Next;

  while N1 <> fTail do
  begin
    if Comparator(N1^.Item, N2^.Item) <> 0 then
    begin
      Result := false;
      Break;
    end;
    N1 := N1^.Next;
    N2 := N2^.Next;
  end;
end;

{--- TGenList<_TItem_>.Equals ---}
function TGenList<_TItem_>.Equals(Obj: TObject): Boolean;
begin
  Result := Equals(Obj, fOnCompareItems);
end;

{--- TGenList<_TItem_>.Equals ---}
function TGenList<_TItem_>.Equals(Obj: TObject; Comparator: TCompareItems): Boolean;
begin
  if Obj = Self  then
    Result := true
  else if Obj is TGenList<_TItem_> then
    Result := Equals(Obj as TGenList<_TItem_>, Comparator)
  else
    Result := false;
end;

{--- TGenList<_TItem_>.Find ---}
function TGenList<_TItem_>.Find(const Item: _TItem_): TListCursor;
begin
  Result := Find(Item, fOnCompareItems);
end;

{--- TGenList<_TItem_>.Find ---}
function TGenList<_TItem_>.Find(const Item: _TItem_; Comparator: TCompareItems): TListCursor;
begin
  if fSize = 0 then
    Result := fNilCursor
  else
    Result := Find(Item, First, Comparator);
end;

{--- TGenList<_TItem_>.Find ---}
function TGenList<_TItem_>.Find(const Item: _TItem_; const Position: TListCursor): TListCursor;
begin
  Result := Find(Item, Position, fOnCompareItems);
end;

{--- TGenList<_TItem_>.Find ---}
function TGenList<_TItem_>.Find(const Item: _TItem_; const Position: TListCursor; Comparator: TCompareItems): TListCursor;
var
  Node: PNode;
  I: _TItem_;
begin
  CheckValid(Position);

  if Position.IsNil then
    Node := fHead^.Next
  else
    Node := Position.Node;

  while Node <> fTail do
  begin
    I := Node^.Item;
    if Comparator(Item, I) = 0 then
      Break;
    Node := Node^.Next;
  end;

  if (Node = fTail) or (Node = fHead) then
    Node := nil;

  Result.Init(Self, Node);
end;

{--- TGenList<_TItem_>.First ---}
function TGenList<_TItem_>.First: TListCursor;
begin
  if fSize > 0 then
    Result.Init(Self, fHead^.Next)
  else
    Result := fNilCursor;
end;

{--- TGenList<_TItem_>.FirstItem ---}
function TGenList<_TItem_>.FirstItem: _TItem_;
begin
  if fSize = 0 then
    RaiseContainerEmpty;

  Result := fHead^.Next^.Item;
end;

{--- TGenList<_TItem_>.GetCursor ---}
function TGenList<_TItem_>.GetCursor(Index: Integer): TListCursor;
var
  DistanceFromHead, DistanceFromTail: LongInt;
  Node: PNode;
begin
  if (Index < -1) or (Index > fSize) then
    Result := fNilCursor
  else
  begin
    DistanceFromHead := Index + 1;
    DistanceFromTail := fSize - Index;

    if DistanceFromHead < DistanceFromTail then
    begin
      Node := fHead;
      while DistanceFromHead > 0 do
      begin
        Node := Node^.Next;
        Dec(DistanceFromHead);
      end;
    end
    else
    begin
      Node := fTail;
      while DistanceFromTail > 0 do
      begin
        Node := Node^.Previous;
        Dec(DistanceFromTail);
      end;
    end;

    Result.Init(Self, Node);
  end;
end;

{--- TGenList<_TItem_>.GetEnumerator ---}
function TGenList<_TItem_>.GetEnumerator: TEnumerator;
begin
  Result := TEnumerator.Create(fNilCursor, EnumeratorNext, EnumeratorGet);
end;

{--- TGenList<_TItem_>.GetItem ---}
function TGenList<_TItem_>.GetItem(const Position: TListCursor): _TItem_;
begin
  CheckNotNil(Position);
  Result := PNode(Position.Node)^.Item;
end;

{--- TGenList<_TItem_>.GetItemFast ---}
function TGenList<_TItem_>.GetItemFast(const Position: TListCursor): _TItem_;
begin
  Result := PNode(Position.Node)^.Item;
end;

{--- TGenList<_TItem_>.GetItemFast ---}
function TGenList<_TItem_>.GetItemPtr(const Position: TListCursor): PItem;
begin
  CheckNotNil(Position);
  Result := @PNode(Position.Node)^.Item;
end;

{--- TGenList<_TItem_>.GetItemFast ---}
function TGenList<_TItem_>.GetItemPtrFast(const Position: TListCursor): PItem;
begin
  Result := @PNode(Position.Node)^.Item;
end;

{--- TGenList<_TItem_>.Insert ---}
procedure TGenList<_TItem_>.Insert(const Before: TListCursor; const Item: _TItem_;
  Count: Integer);
var
  BeforeNode: PNode;
begin
  CheckValid(Before);

  if Before.HasItem then
    BeforeNode := PNode(Before.Node)
  else
    BeforeNode := fTail;

  InsertItem(Item, BeforeNode, Count);
end;

{--- TGenList<_TItem_>.Insert ---}
procedure TGenList<_TItem_>.Insert(const Before: TListCursor; const Item: _TItem_;
  out Position: TListCursor; Count: Integer);
var
  Prev, BeforeNode: PNode;
begin
  CheckValid(Before);

  if Before.HasItem then
    BeforeNode := PNode(Before.Node)
  else
    BeforeNode := fTail;

  Prev := BeforeNode^.Previous;

  InsertItem(Item, BeforeNode, Count);

  Position.Init(Self, Prev^.Next);
end;

{--- TGenList<_TItem_>.InsertAll ---}
procedure TGenList<_TItem_>.InsertAll(const Before: TListCursor; Src: TGenList<_TItem_>);
begin
  if Src.fSize > 0 then
    InsertRange(Before, Src, Src.First, Src.Last);
end;

{--- TGenList<_TItem_>.InsertItem ---}
procedure TGenList<_TItem_>.InsertItem(const Item: _TItem_; Pos: PNode; Count: Integer);
var
  Node: PNode;
begin
  while Count > 0 do
  begin
    New(Node);
    Node^.Item := Item;

    Pos^.Previous^.Next := Node;

    Node^.Previous := Pos^.Previous;
    Node^.Next := Pos;

    Pos^.Previous := Node;

    Inc(fSize);
    Dec(Count);
  end;
end;

{--- TGenList<_TItem_>.InsertRange ---}
procedure TGenList<_TItem_>.InsertRange(const Before: TListCursor; Src: TGenList<_TItem_>;
  const PosFrom, PosTo: TListCursor);
var
  Copy: TGenList<_TItem_>;
  Node, LastNode: PNode;
begin
  CheckValid(Before);
  Src.CheckNotNil(PosFrom);
  Src.CheckNotNil(PosTo);

  Copy := TGenList<_TItem_>.Create;
  try    
    Node := PNode(PosFrom.Node);
    LastNode := PNode(PosTo.Node)^.Next;

    while Node <> LastNode do
    begin
      Copy.Append(Node^.Item);
      Node := Node^.Next;
    end;

    Splice(Before, Copy);
  finally
    Copy.Free;
  end;
end;

{--- TGenList<_TItem_>.IsEmpty ---}
function TGenList<_TItem_>.IsEmpty: Boolean;
begin
  Result := (fSize = 0);
end;

{--- TGenList<_TItem_>.IsSorted ---}
function TGenList<_TItem_>.IsSorted: Boolean;
begin
  Result := IsSorted(fOnCompareItems);
end;

{--- TGenList<_TItem_>.IsSorted ---}
function TGenList<_TItem_>.IsSorted(Comparator: TCompareItems): Boolean;
var
  N: PNode;
  I: Integer;
begin
  Result := true;

  N := fHead^.Next;
  for I := 2 to fSize do
  begin
    if Comparator(N^.Item, N^.Next^.Item) > 0 then
    begin
      Result := false;
      Break;
    end;
    N := N^.Next;
  end;
end;

{--- TGenList<_TItem_>.DefaultItemToString ---}
function TGenList<_TItem_>.DefaultItemToString(const Item: _TItem_): String;
begin
  Unused(@Item);
  RaiseMethodNotRedefined;
  Result := '';
end;

{--- TGenList<_TItem_>.Iterate ---}
procedure TGenList<_TItem_>.Iterate(Process: TProcessItem);
begin
  if fSize > 0 then
    Iterate(Process, First, Last);
end;

{--- TGenList<_TItem_>.Iterate ---}
procedure TGenList<_TItem_>.Iterate(Process: TProcessItem; const PosFrom, PosTo: TListCursor);
var
  Node, Limit: PNode;
begin
  CheckNotNil(PosFrom);
  CheckNotNil(PosTo);

  Node := PNode(PosFrom.Node);
  Limit := PNode(PosTo.Node)^.Next ;

  while Node <> Limit do
  begin
    Process(Node^.Item);
    Node := Node^.Next;
  end;
end;

{--- TGenList<_TItem_>.Last ---}
function TGenList<_TItem_>.Last: TListCursor;
begin
  if fSize > 0 then
    Result.Init(Self, fTail^.Previous)
  else
    Result.Init(Self, nil);
end;

{--- TGenList<_TItem_>.LastItem ---}
function TGenList<_TItem_>.LastItem: _TItem_;
begin
  if fSize = 0 then
    RaiseContainerEmpty;

  Result := fTail^.Previous^.Item;
end;

{--- TGenList<_TItem_>.Merge ---}
procedure TGenList<_TItem_>.Merge(Src: TGenList<_TItem_>);
begin
  Merge(Src, fOnCompareItems);
end;

{--- TGenList<_TItem_>.Merge ---}
procedure TGenList<_TItem_>.Merge(Src: TGenList<_TItem_>; Comparator: TCompareItems);
var
  Node, SrcNode, N: PNode;
begin
  if Src = Self then
    Exit;

  Node := fHead^.Next;
  SrcNode := Src.fHead^.Next;

  while SrcNode <> Src.fTail do
  begin
    if Node = fTail then
    begin
      SpliceNodes(fTail, SrcNode, SrcNode);
      fSize := fSize + Src.fSize;
      Src.fSize := 0;
      Break;
    end;

    if Comparator(SrcNode^.Item, Node^.Item) < 0 then
    begin
      N := SrcNode^.Next;
      SpliceNodes(Node, SrcNode, SrcNode);
      Dec(Src.fSize);
      Inc(fSize);
      SrcNode := N;
    end
    else
      Node := Node^.Next;
  end;
end;

{--- TGenList<_TItem_>.Partition ---}
procedure TGenList<_TItem_>.Partition(Pivot, Back: PNode; Comparator: TCompareItems);
var
  Node, Next: PNode;
begin
  Node := Pivot^.Next;
  while Node <> Back do
    if Comparator(Node^.Item, Pivot^.Item) < 0 then
    begin
      Next := Node^.Next;
      SpliceNodes(Pivot, Node, Node);
      Node := Next;
    end
    else
      Node := Node^.Next;
end;

{--- TGenList<_TItem_>.Prepend ---}
procedure TGenList<_TItem_>.Prepend(const Item: _TItem_; Count: Integer);
begin
  Insert(First, Item, Count);
end;

{--- TGenList<_TItem_>.PrependAll ---}
procedure TGenList<_TItem_>.PrependAll(Src: TGenList<_TItem_>);
begin
  InsertAll(First, Src);
end;

{--- TGenList<_TItem_>.PrependRange ---}
procedure TGenList<_TItem_>.PrependRange(Src: TGenList<_TItem_>; const PosFrom, PosTo: TListCursor);
begin
  InsertRange(First, Src, PosFrom, PosTo);
end;

{--- TGenList<_TItem_>.ReadFirstItem ---}
procedure TGenList<_TItem_>.ReadFirstItem(out Value: _TItem_);
begin
  if fSize = 0 then
    RaiseContainerEmpty;

  Value := fHead^.Next^.Item;
end;

{--- TGenList<_TItem_>.ReadItem ---}
procedure TGenList<_TItem_>.ReadItem(const Position: TListCursor; out Value: _TItem_);
begin
  CheckNotNil(Position);
  Value := PNode(Position.Node)^.Item;
end;

{--- TGenList<_TItem_>.ReadItemFast ---}
procedure TGenList<_TItem_>.ReadItemFast(const Position: TListCursor; out Value: _TItem_);
begin
  Value := PNode(Position.Node)^.Item;
end;

{--- TGenList<_TItem_>.ReadLastItem ---}
procedure TGenList<_TItem_>.ReadLastItem(out Value: _TItem_);
begin
  if fSize = 0 then
    RaiseContainerEmpty;

  Value := fTail^.Previous^.Item;
end;

{--- TGenList<_TItem_>.RealSort ---}
procedure TGenList<_TItem_>.RealSort(Front, Back: PNode; Comparator: TCompareItems);
var
  Pivot: PNode;
begin
  Pivot := Front^.Next;
  if Pivot <> Back then
  begin
     Partition(Pivot, Back, Comparator);
     RealSort(Front, Pivot, Comparator);
     RealSort(Pivot, Back, Comparator)
  end;
end;

{--- TGenList<_TItem_>.SetOnCompareItems ---}
procedure TGenList<_TItem_>.SetOnCompareItems(AValue: TCompareItems);
begin
  if Assigned(AValue) then
    fOnCompareItems := AValue
  else
    fOnCompareItems := DefaultCompareItems
end;

{--- TGenList<_TItem_>.SetOnItemToString ---}
procedure TGenList<_TItem_>.SetOnItemToString(AValue: TItemToString);
begin
  if Assigned(AValue) then
    fOnItemToString := AValue
  else
    fOnItemToString := DefaultItemToString
end;

{--- TGenList<_TItem_>.Replace ---}
procedure TGenList<_TItem_>.Replace(const Position: TListCursor; Count: Integer;
  const Value: _TItem_);
var
  Node: PNode;
begin
  CheckNotNil(Position);

  Node := PNode(Position.Node);
  while (Count > 0) and (Node <> fTail) do
  begin
    Node^.Item := Value;
    Dec(Count);
    Node := Node^.Next;
  end;
end;

{--- TGenList<_TItem_>.Reverse ---}
procedure TGenList<_TItem_>.Reverse;
begin
  if fSize > 1 then
    ReverseRange(First, Last);
end;

{--- TGenList<_TItem_>.ReverseFind ---}
function TGenList<_TItem_>.ReverseFind(const Item: _TItem_): TListCursor;
begin
  Result := ReverseFind(Item, fOnCompareItems);
end;

{--- TGenList<_TItem_>.ReverseFind ---}
function TGenList<_TItem_>.ReverseFind(const Item: _TItem_; Comparator: TCompareItems): TListCursor;
begin
  if fSize = 0 then
    Result := fNilCursor
  else
    Result := ReverseFind(Item, Last, Comparator);
end;

{--- TGenList<_TItem_>.ReverseFind ---}
function TGenList<_TItem_>.ReverseFind(const Item: _TItem_; const Position: TListCursor): TListCursor;
begin
  Result := ReverseFind(Item, Position, fOnCompareItems);
end;

{--- TGenList<_TItem_>.ReverseFind ---}
function TGenList<_TItem_>.ReverseFind(const Item: _TItem_;
  const Position: TListCursor; Comparator: TCompareItems): TListCursor;
var
  Node: PNode;
  I: _TItem_;
begin
  CheckValid(Position);

  if Position.IsNil then
    Node := fTail^.Previous
  else
    Node := PNode(Position.Node);

  if Node = fTail then
    Node := Node^.Previous;

  while Node <> fHead do
  begin
    I := Node^.Item;
    if Comparator(Item, I) = 0 then
      Break;
    Node := Node^.Previous;
  end;

  if (Node = fTail) or (Node = fHead) then
    Node := nil;

  Result.Init(Self, Node);
end;

{--- TGenList<_TItem_>.ReverseRange ---}
procedure TGenList<_TItem_>.ReverseRange(const PosFrom, PosTo: TListCursor);
var
  Left, Right: PNode;
  Tmp: _TItem_;
begin
  CheckNotNil(PosFrom);
  CheckNotNil(PosTo);

  if not PosFrom.Equals(PosTo) then
  begin
    Left := PNode(PosFrom.Node);
    Right := PNode(PosTo.Node);
    while true do
    begin
      Tmp := Left^.Item;
      Left^.Item := Right^.Item;
      Right^.Item := Tmp;

      Left := Left^.Next;
      if Left = Right then
        Break;

      Right := Right^.Previous;
      if Left = Right then
        Break;
    end;
  end;
end;

{--- TGenList<_TItem_>.SetItem ---}
procedure TGenList<_TItem_>.SetItem(const Position: TListCursor; const Value: _TItem_);
begin
  CheckNotNil(Position);
  PNode(Position.Node)^.Item := Value;
end;

{--- TGenList<_TItem_>.SetItemFast ---}
procedure TGenList<_TItem_>.SetItemFast(const Position: TListCursor; const Value: _TItem_);
begin
  PNode(Position.Node)^.Item := Value;
end;

{--- TGenList<_TItem_>.Sort ---}
procedure TGenList<_TItem_>.Sort(const PosFrom, PosTo: TListCursor);
begin
  Sort(PosFrom, PosTo, fOnCompareItems);
end;

{--- TGenList<_TItem_>.Sort ---}
procedure TGenList<_TItem_>.Sort(const PosFrom, PosTo: TListCursor; Comparator: TCompareItems);
begin
  CheckNotNil(PosFrom);
  CheckNotNil(PosTo);
  RealSort(PNode(PosFrom.Node)^.Previous, PNode(PosTo.Node)^.Next, Comparator);
end;

{--- TGenList<_TItem_>.Sort ---}
procedure TGenList<_TItem_>.Sort;
begin
  Sort(fOnCompareItems);
end;

{--- TGenList<_TItem_>.Sort ---}
procedure TGenList<_TItem_>.Sort(Comparator: TCompareItems);
begin
  if fSize > 1 then
    Sort(First, Last, Comparator);
end;

{--- TGenList<_TItem_>.Splice ---}
procedure TGenList<_TItem_>.Splice(const Before: TListCursor; Src: TGenList<_TItem_>);
var
  Where: PNode;
begin
  CheckValid(Before);

  if (Self <> Src) and (Src.fSize > 0) then
  begin
    if Before.IsNil then
      Where := fTail
    else
      Where := PNode(Before.Node);

    SpliceNodes(Where, Src.fHead^.Next, Src.fTail^.Previous);
    Inc(fSize, Src.fSize);
    Src.fSize:=0;
  end;
end;

{--- TGenList<_TItem_>.Splice ---}
procedure TGenList<_TItem_>.Splice(const Before: TListCursor; Src: TGenList<_TItem_>;
  const SrcFrom, SrcTo: TListCursor);
var
  Node, Where: PNode;
  Count: Integer;
begin
  Count := 0;
  CheckValid(Before);
  Src.CheckNotNil(SrcFrom);
  Src.CheckNotNil(SrcTo);

  if (Src = Self) and Before.HasItem then
  begin
    if Before.Equals(SrcFrom) or Before.Equals(SrcTo) then
      RaiseError('cursor `Before'' is in range [SrcFrom..SrcTo]');

    Node := PNode(SrcFrom.Node)^.Next;
    while Node <> PNode(SrcTo.Node) do
    begin
      if Node = PNode(Before.Node) then
        RaiseError('cursor `Before'' is in range [SrcFrom..SrcTo]');
      Node := Node^.Next;
    end;
  end
  else if Src <> Self then
  begin
    Node := PNode(SrcFrom.Node);
    while Node <> PNode(SrcTo.Node) do
    begin
      Node := Node^.Next;
      Inc(Count);
    end;
    Inc(Count);
  end;

  if Before.HasItem then
    Where := PNode(Before.Node)
  else
    Where := fTail;

  SpliceNodes(Where, PNode(SrcFrom.Node), PNode(SrcTo.Node));
  Inc(fSize, Count);
  Dec(Src.fSize, Count);
end;

{--- TGenList<_TItem_>.Splice ---}
procedure TGenList<_TItem_>.Splice(const Before: TListCursor; Src: TGenList<_TItem_>;
  const Position: TListCursor);
var
  Where: PNode;
begin
  CheckValid(Before);
  Src.CheckNotNil(Position);

  if not Position.Equals(Before) then
  begin
    if Before.HasItem then
      Where := PNode(Before.Node)
    else
      Where := fTail;

    SpliceNodes(Where, PNode(Position.Node), PNode(Position.Node));
    Inc(fSize);
    Dec(Src.fSize);
  end;
end;

{--- TGenList<_TItem_>.SpliceNodes ---}
procedure TGenList<_TItem_>.SpliceNodes(Before, PosFrom, PosTo: PNode);
begin
  PosFrom^.Previous^.Next := PosTo^.Next;
  PosTo^.Next^.Previous := PosFrom^.Previous;

  Before^.Previous^.Next := PosFrom;
  PosFrom^.Previous := Before^.Previous;

  PosTo^.Next := Before;
  Before^.Previous := PosTo;
end;

{--- TGenList<_TItem_>.CursorIsFirst ---}
function TGenList<_TItem_>.CursorIsFirst(const Cursor: TListCursor): Boolean;
begin
  Result := (PNode(Cursor.Node) = (Cursor.List as TGenList<_TItem_>).fHead^.Next) and
            (PNode(Cursor.Node) <> (Cursor.List as TGenList<_TItem_>).fTail);
end;

{--- TGenList<_TItem_>.CursorIsLast ---}
function TGenList<_TItem_>.CursorIsLast(const Cursor: TListCursor): Boolean;
begin
  Result := (PNode(Cursor.Node) = (Cursor.List as TGenList<_TItem_>).fTail^.Previous) and
            (PNode(Cursor.Node) <> (Cursor.List as TGenList<_TItem_>).fHead);
end;

{--- TGenList<_TItem_>.CursorMoveNext ---}
procedure TGenList<_TItem_>.CursorMoveNext(var Cursor: TListCursor);
begin
  if Cursor.Node <> nil then
  begin
    Cursor.Node := PNode(Cursor.Node)^.Next;
    if PNode(Cursor.Node) = (Cursor.List as TGenList<_TItem_>).fTail then
      Cursor.Node := nil;
  end;
end;

{--- TGenList<_TItem_>.CursorMovePrev ---}
procedure TGenList<_TItem_>.CursorMovePrev(var Cursor: TListCursor);
begin
  if Cursor.Node <> nil then
  begin
    Cursor.Node := PNode(Cursor.Node)^.Previous;
    if PNode(Cursor.Node) = (Cursor.List as TGenList<_TItem_>).fHead then
      Cursor.Node := nil;
  end;
end;

{--- TGenList<_TItem_>.Swap ---}
procedure TGenList<_TItem_>.Swap(const I, J: TListCursor);
var
  Tmp: _TItem_;
begin
  CheckNotNil(I);
  CheckNotNil(J);

  if I.Node <> J.Node then
  begin
    Tmp := PNode(I.Node)^.Item;
    PNode(I.Node)^.Item := PNode(J.Node)^.Item;
    PNode(J.Node)^.Item := Tmp;
  end;
end;

{--- TGenList<_TItem_>.SwapLinks ---}
procedure TGenList<_TItem_>.SwapLinks(const I, J: TListCursor);
var
  NextI: PNode;
begin
  CheckNotNil(I);
  CheckNotNil(J);

  if I.Node <> J.Node then
  begin
    NextI := PNode(I.Node)^.Next;

    if NextI = PNode(J.Node) then
      SpliceNodes(PNode(I.Node), PNode(J.Node), PNode(J.Node))
    else
    begin
      SpliceNodes(PNode(J.Node), PNode(I.Node), PNode(I.Node));
      SpliceNodes(NextI, PNode(J.Node), PNode(J.Node) );
    end;
  end;
end;

{--- TGenList<_TItem_>.ToString ---}
function TGenList<_TItem_>.ToString: String;
var
  Node: PNode;
begin
  Result := '(';

  if fSize > 0 then
  begin
    Node := fHead^.Next;
    while Node <> fTail do
    begin
      Result := Result + fOnItemToString(Node^.Item) + ', ';
      Node := Node^.Next;
    end;
    SetLength(Result, Length(Result) - 2);
  end;

  Result := Result + ')';
end;

end.
