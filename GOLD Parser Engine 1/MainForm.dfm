object Main: TMain
  Left = 298
  Top = 121
  BorderStyle = bsSingle
  Caption = 'Test The Grammar - Delphi Version'
  ClientHeight = 494
  ClientWidth = 619
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnShow = FormShow
  DesignSize = (
    619
    494)
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 8
    Top = 184
    Width = 603
    Height = 274
    ActivePage = TabSheet1
    Anchors = [akLeft, akTop, akRight, akBottom]
    Style = tsFlatButtons
    TabOrder = 4
    object TabSheet1: TTabSheet
      Caption = 'Ansi Reduction Tree'
      DesignSize = (
        595
        243)
      object GroupBox2: TGroupBox
        Left = 8
        Top = 0
        Width = 584
        Height = 239
        Anchors = [akLeft, akTop, akRight, akBottom]
        Caption = ' Parse Tree '
        TabOrder = 0
        object txtParseTree: TMemo
          Left = 2
          Top = 15
          Width = 580
          Height = 222
          Align = alClient
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Courier New'
          Font.Style = []
          Lines.Strings = (
            '                 The GOLD Parser Freeware License Agreement'
            '                 =========================================='
            ''
            
              'This software is provided '#39'as-is'#39', without any expressed or impl' +
              'ied warranty.'
            
              'In no event will the authors be held liable for any damages aris' +
              'ing from the '
            'use of this software.'
            ''
            
              'Permission is granted to anyone to use this software for any pur' +
              'pose. If you '
            
              'use this software in a product, an acknowledgment in the product' +
              ' documentation '
            'would be deeply appreciated but is not required.'
            ''
            
              'In the case of the GOLD Parser Engine source code, permission is' +
              ' granted to '
            
              'anyone to alter it and redistribute it freely, subject to the fo' +
              'llowing '
            'restrictions:'
            ''
            
              '   1. The origin of this software must not be misrepresented; yo' +
              'u must not '
            '      claim that you wrote the original software.'
            ''
            
              '   2. Altered source versions must be plainly marked as such, an' +
              'd must not '
            '      be misrepresented as being the original software.'
            ''
            
              '   3. This notice may not be removed or altered from any source ' +
              'distribution')
          ParentFont = False
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Messages'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Memo1: TMemo
        Left = 0
        Top = 0
        Width = 595
        Height = 243
        Align = alClient
        ScrollBars = ssBoth
        TabOrder = 0
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'TreeView Reduction'
      ImageIndex = 2
      object TreeView1: TTreeView
        Left = 0
        Top = 0
        Width = 595
        Height = 243
        Align = alClient
        Ctl3D = False
        HideSelection = False
        Indent = 19
        ParentCtl3D = False
        ReadOnly = True
        RowSelect = True
        TabOrder = 0
      end
    end
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 8
    Width = 594
    Height = 145
    Caption = ' GOLD Parser Input '
    TabOrder = 1
    object Label1: TLabel
      Left = 16
      Top = 24
      Width = 41
      Height = 13
      Caption = 'CGT File'
    end
    object Label2: TLabel
      Left = 16
      Top = 56
      Width = 48
      Height = 13
      Caption = 'Test Input'
    end
    object txtTestInput: TMemo
      Left = 104
      Top = 56
      Width = 475
      Height = 73
      Lines.Strings = (
        'b+c/(d*e)-c')
      ScrollBars = ssBoth
      TabOrder = 0
    end
    object txtCGTFilePath: TEdit
      Left = 104
      Top = 24
      Width = 450
      Height = 21
      TabOrder = 1
    end
    object cmdOpenFile: TButton
      Left = 560
      Top = 23
      Width = 19
      Height = 17
      Caption = '...'
      TabOrder = 2
      OnClick = cmdOpenFileClick
    end
  end
  object chkTrimReductions: TCheckBox
    Left = 8
    Top = 160
    Width = 105
    Height = 17
    Caption = 'Trim Reductions'
    Checked = True
    State = cbChecked
    TabOrder = 2
  end
  object cmdClose: TButton
    Left = 540
    Top = 464
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Close'
    TabOrder = 3
    OnClick = cmdCloseClick
  end
  object cmdParse: TButton
    Left = 527
    Top = 159
    Width = 75
    Height = 25
    Caption = 'Parse'
    TabOrder = 0
    OnClick = cmdParseClick
  end
  object OpenDialog1: TOpenDialog
    Filter = 'Compiled Grammar Table|*.cgt'
    Left = 480
    Top = 160
  end
end
