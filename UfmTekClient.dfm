object fmTekClient: TfmTekClient
  Left = 554
  Top = 152
  Width = 665
  Height = 375
  Caption = 'Client forTDS scope'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 122
    Top = 1
    Width = 22
    Height = 13
    Caption = 'Port:'
  end
  object bnConnect: TButton
    Left = 392
    Top = 0
    Width = 75
    Height = 25
    Caption = #1057#1086#1077#1076#1080#1085#1080#1090#1100
    TabOrder = 0
    OnClick = bnConnectClick
  end
  object bnSend: TButton
    Left = 360
    Top = 280
    Width = 75
    Height = 25
    Caption = 'Write'
    TabOrder = 1
    OnClick = bnSendClick
  end
  object bnClose: TBitBtn
    Left = 560
    Top = 48
    Width = 75
    Height = 25
    TabOrder = 2
    Kind = bkClose
  end
  object edPort: TEdit
    Left = 152
    Top = 0
    Width = 73
    Height = 21
    TabOrder = 3
    Text = '10'
  end
  object edServer: TEdit
    Left = 240
    Top = 0
    Width = 121
    Height = 21
    TabOrder = 4
    Text = '192.168.3.11'
  end
  object bnRead: TButton
    Left = 360
    Top = 312
    Width = 75
    Height = 25
    Caption = 'Read'
    TabOrder = 5
    OnClick = bnReadClick
  end
  object memLog: TMemo
    Left = 160
    Top = 32
    Width = 385
    Height = 233
    TabOrder = 6
  end
  object bnClear: TBitBtn
    Left = 560
    Top = 16
    Width = 75
    Height = 25
    Caption = 'Clear'
    TabOrder = 7
    OnClick = bnClearClick
  end
  object ecbCommand: TComboBox
    Left = 112
    Top = 304
    Width = 193
    Height = 21
    ItemHeight = 13
    TabOrder = 8
    Text = '*CLS'
    Items.Strings = (
      '*CLS'
      ':CHDR OFF'
      ':ACQUIRE:STOPAFTER SEQUENCE'
      ':STATE RUN'
      '*IDN?'
      '*ESR?'
      'CHDR?')
  end
  object bnGetPort: TButton
    Left = 568
    Top = 104
    Width = 75
    Height = 25
    Caption = 'GetPort'
    TabOrder = 9
    OnClick = bnGetPortClick
  end
  object ApplicationEvents1: TApplicationEvents
    OnException = ApplicationEvents1Exception
    Left = 552
    Top = 312
  end
end
