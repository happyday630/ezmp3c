unit TFlatProgressBarUnit;

interface

{$I Version.inc}

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls, 
  Forms, Dialogs, ExtCtrls, Comctrls, FlatUtilitys;

type
  TFlatProgressBar = class(TGraphicControl)
  private
    FSmooth: Boolean;
    FUseAdvColors: Boolean;
    FAdvColorBorder: TAdvColors;
    FOrientation: TProgressBarOrientation;
    FElementWidth: Integer;
    FElementColor: TColor;
    FBorderColor: TColor;
    FPosition: Integer;
    FMin: Integer;
    FMax: Integer;
    FStep: Integer;
    procedure SetMin (Value: Integer);
    procedure SetMax (Value: Integer);
    procedure SetPosition (Value: Integer);
    procedure SetStep (Value: Integer);
    procedure SetColors (Index: Integer; Value: TColor);
    procedure SetAdvColors (Index: Integer; Value: TAdvColors);
    procedure SetUseAdvColors (Value: Boolean);
    procedure SetOrientation (Value: TProgressBarOrientation);
    procedure SetSmooth (Value: Boolean);
    procedure CheckBounds;
    procedure CMSysColorChange (var Message: TMessage); message CM_SYSCOLORCHANGE;
    procedure CMParentColorChanged (var Message: TWMNoParams); message CM_PARENTCOLORCHANGED;
  protected
    procedure CalcAdvColors;
    procedure Paint; override;
  public
    constructor Create (AOwner: TComponent); override;
    procedure StepIt;
    procedure StepBy (Delta: Integer);
  published
    property Align;
    property Cursor;
    property Color default $00E1EAEB;
    property ColorElement: TColor index 0 read FElementColor write SetColors default $00996633;
    property ColorBorder: TColor index 1 read FBorderColor write SetColors default $008396A0;
    property AdvColorBorder: TAdvColors index 0 read FAdvColorBorder write SetAdvColors default 50;
    property UseAdvColors: Boolean read FUseAdvColors write SetUseAdvColors default false;
    property Orientation: TProgressBarOrientation read FOrientation write SetOrientation default pbHorizontal;
    property Enabled;
    property ParentColor;
    property Visible;
    property Hint;
    property ShowHint;
    property PopupMenu;
    property ParentShowHint;
    property Min: Integer read FMin write SetMin;
    property Max: Integer read FMax write SetMax;
    property Position: Integer read FPosition write SetPosition default 0;
    property Step: Integer read FStep write SetStep default 10;
    property Smooth: Boolean read FSmooth write SetSmooth default false;

    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDrag;
   {$IFDEF D4CB4}
    property Anchors;
    property BiDiMode;
    property Constraints;
    property DragKind;
    property ParentBiDiMode;
    property OnEndDock;
    property OnStartDock;
   {$ENDIF}
  end;

implementation

constructor TFlatProgressBar.Create (AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  Height := 16;
  Width := 147;
  FElementWidth := 8;
  FElementColor := $00996633;
  FBorderColor := $008396A0;
  ParentColor := True;
  Orientation := pbHorizontal;
  FStep := 10;
  FMin := 0;
  FMax := 100;
  FUseAdvColors := false;
  FAdvColorBorder := 50;
end;

procedure TFlatProgressBar.SetOrientation (Value: TProgressBarOrientation);
begin
  if FOrientation <> Value then
  begin
    FOrientation := Value;
    if (csLoading in ComponentState) then
    begin
      Repaint;
      Exit;
    end;
    SetBounds(Left, Top, Height, Width);
    Repaint;
  end;
end;

procedure TFlatProgressBar.SetMin (Value: Integer);
begin
  if FMin <> Value then
  begin
    FMin := Value;
    Repaint;
  end;
end;

procedure TFlatProgressBar.SetMax (Value: Integer);
begin
  if FMax <> Value then
  begin
    FMax := Value;
    Repaint;
  end;
end;

procedure TFlatProgressBar.SetPosition (Value: Integer);
begin
  if FPosition <> Value then
  begin
    FPosition := Value;
    Repaint;
  end;
end;

procedure TFlatProgressBar.SetStep (Value: Integer);
begin
  if FStep <> Value then
  begin
    FStep := Value;
    Repaint;
  end;
end;

procedure TFlatProgressBar.StepIt;
begin
  if (FPosition + FStep) > FMax then
    FPosition := FMax
  else
    FPosition := FPosition + FStep;
  Repaint;
end;

procedure TFlatProgressBar.StepBy (Delta: Integer);
begin
  if (FPosition + Delta) > FMax then
    FPosition := FMax
  else
    FPosition := FPosition + Delta;
  Repaint;
end;

procedure TFlatProgressBar.SetColors (Index: Integer; Value: TColor);
begin
  case Index of
    0: FElementColor := Value;
    1: FBorderColor := Value;
  end;
  Invalidate;
end;

procedure TFlatProgressBar.CalcAdvColors;
begin
  if FUseAdvColors then
  begin
    FBorderColor := CalcAdvancedColor(Color, FBorderColor, FAdvColorBorder, darken);
  end;
end;

procedure TFlatProgressBar.SetAdvColors (Index: Integer; Value: TAdvColors);
begin
  case Index of
    0: FAdvColorBorder := Value;
  end;
  CalcAdvColors;
  Invalidate;
end;

procedure TFlatProgressBar.SetUseAdvColors (Value: Boolean);
begin
  if Value <> FUseAdvColors then
  begin
    FUseAdvColors := Value;
    ParentColor := Value;
    CalcAdvColors;
    Invalidate;
  end;
end;

procedure TFlatProgressBar.CMSysColorChange (var Message: TMessage);
begin
  if FUseAdvColors then
  begin
    ParentColor := True;
    CalcAdvColors;
  end;
  Invalidate;
end;

procedure TFlatProgressBar.CMParentColorChanged (var Message: TWMNoParams);
begin
  inherited;
  if FUseAdvColors then
  begin
    ParentColor := True;
    CalcAdvColors;
  end;
  Invalidate;
end;

procedure TFlatProgressBar.CheckBounds;
var
  maxboxes: Word;
begin
  if FOrientation = pbHorizontal then
  begin
    maxboxes := (Width - 3) div (FElementWidth + 1);
    if Width < 12 then
      Width := 12
    else
      Width := maxboxes * (FElementWidth + 1) + 3;
  end
  else
  begin
    maxboxes := (Height - 3) div (FElementWidth + 1);
    if Height < 12 then
      Height := 12
    else
      Height := maxboxes * (FElementWidth + 1) + 3;
  end;
end;

procedure TFlatProgressBar.Paint;
var
  NumElements: LongInt;
  PercentPerElement: Double;
  NumToPaint: LongInt;
  Painted: Integer;
  PaintRect, ElementRect: TRect;
begin
  if not Smooth then
    CheckBounds;
  PaintRect := ClientRect;

  // Background
  Canvas.Brush.Color := Self.Color;
  Canvas.Brush.Style := bsSolid;
  Canvas.FillRect(PaintRect);

  // Border
  Canvas.Brush.Color := FBorderColor;
  Canvas.FrameRect(PaintRect);

  // Elements
  if not Smooth then
  begin
    if FOrientation = pbHorizontal then
    begin
      NumElements := Trunc((Width - 3) div (FElementWidth + 1));
      PercentPerElement := 100 div NumElements;
      NumToPaint := Round(FPosition / PercentPerElement);
      if NumToPaint > NumElements then
        NumToPaint := NumElements;
      ElementRect := Rect(PaintRect.Left + 2, PaintRect.Top + 2, PaintRect.Left + 2 + FElementWidth, PaintRect.Bottom - 2);

      if NumToPaint > 0 then
      begin
        Canvas.Brush.Color := FElementColor;
        Canvas.Brush.Style := bsSolid;
        for Painted := 1 to NumToPaint do
        begin
          Canvas.FillRect(ElementRect);
          ElementRect.Left := ElementRect.Left + FElementWidth + 1;
          ElementRect.Right := ElementRect.Right + FElementWidth + 1;
        end;
      end;
    end
    else
    begin
      NumElements := Trunc((Height - 3) div (FElementWidth + 1));
      PercentPerElement := 100 div NumElements;
      NumToPaint := Round(FPosition / PercentPerElement);
      if NumToPaint > NumElements then
        NumToPaint := NumElements;
      ElementRect := Rect(PaintRect.Left + 2, PaintRect.Bottom - FElementWidth - 2, PaintRect.Right - 2, PaintRect.Bottom - 2);

      if NumToPaint > 0 then
      begin
        Canvas.Brush.Color := FElementColor;
        Canvas.Brush.Style := bsSolid;
        for Painted := 1 to NumToPaint do
        begin
          Canvas.FillRect(ElementRect);
          ElementRect.Top := ElementRect.Top - (FElementWidth + 1);
          ElementRect.Bottom := ElementRect.Bottom - (FElementWidth + 1);
        end;
      end;
    end;
  end
  else
  begin
    if FOrientation = pbHorizontal then
    begin
      Canvas.Brush.Color := FElementColor;
      Canvas.FillRect(Rect(2, 2, ClientRect.Left + ((FPosition * (ClientWidth - 2)) div 100), ClientRect.Bottom - 2));
    end
    else
    begin
      Canvas.Brush.Color := FElementColor;
      Canvas.FillRect(Rect(2, ClientRect.Bottom - 2 - ((FPosition * (ClientHeight - 4)) div 100), ClientRect.Right - 2, ClientRect.Bottom - 2));
    end;
  end;
end;

procedure TFlatProgressBar.SetSmooth(Value: Boolean);
begin
  if Value <> FSmooth then
  begin
    FSmooth := Value;
    Invalidate;
  end;
end;

end.
