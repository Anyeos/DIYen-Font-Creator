unit creator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, TALegendPanel, Forms, Controls, Graphics,
  Dialogs, ColorBox, ExtCtrls, StdCtrls, ValEdit, Grids, MaskEdit, Spin,
  BGRABitmap, BGRABitmapTypes, BGRATextFX, BGRAGradients, BGRAGraphicControl,
  BGRAVirtualScreen,
  BGRAGradientScanner, LCLProc, ExtDlgs,
  ComCtrls, LazUtf8;

type

  { TFCreator }

  TFCreator = class(TForm)
    BGenerar: TButton;
    GlyphGen: TBGRAVirtualScreen;
    CBRellenoC2: TColorButton;
    CBShader: TCheckBox;
    CBFondo: TColorButton;
    CBRellenoC1: TColorButton;
    CBRellenoGamma: TCheckBox;
    CBRellenoSinus: TCheckBox;
    EdRellenoP1X: TFloatSpinEdit;
    EdRellenoP2X: TFloatSpinEdit;
    EdRellenoP1Y: TFloatSpinEdit;
    EdRellenoP2Y: TFloatSpinEdit;
    EdShaderX: TSpinEdit;
    EdTexto: TEdit;
    EdY: TSpinEdit;
    EdX: TSpinEdit;
    EdShaderY: TSpinEdit;
    EdContornoG: TFloatSpinEdit;
    CBContorno: TCheckBox;
    CBSombra: TCheckBox;
    CBContornoC: TColorButton;
    CBSombraC: TColorButton;
    CBRellenoTipo: TComboBox;
    EdContornoA: TSpinEdit;
    EdSombraA: TSpinEdit;
    EdSombraX: TSpinEdit;
    EdAlto: TSpinEdit;
    EdContornoX: TSpinEdit;
    EdContornoY: TSpinEdit;
    EdSombraR: TSpinEdit;
    EdSombraY: TSpinEdit;
    FontPreview: TImage;
    ImageList1: TImageList;
    Label1: TLabel;
    Label10: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    GBFuente: TGroupBox;
    BGuardar: TButton;
    EdGlyphs: TEdit;
    FontDialog: TFontDialog;
    Glyphs: TGroupBox;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    RadioGroup1: TRadioGroup;
    RadioGroup2: TRadioGroup;
    RadioGroup3: TRadioGroup;
    RadioGroup4: TRadioGroup;
    RadioGroup5: TRadioGroup;
    SaveDialog1: TSaveDialog;
    SavePictureDialog: TSavePictureDialog;
    ScrollBox: TScrollBox;
    EdAncho: TSpinEdit;
    ToolBar1: TToolBar;
    TBAbrir: TToolButton;
    TBSalvar: TToolButton;
    procedure BGuardarClick(Sender: TObject);
    procedure FontPreviewRedraw(Sender: TObject; Bitmap: TBGRABitmap);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure GlyphGenRedraw(Sender: TObject; Bitmap: TBGRABitmap);
    procedure PrevisualizarFuente(Sender: TObject);
    procedure BGenerarClick(Sender: TObject);
    procedure FontPreviewClick(Sender: TObject);
    procedure RenderText( previsualizar: boolean; texto: string );
    procedure TBAbrirClick(Sender: TObject);
    procedure TBSalvarClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  FCreator: TFCreator;
  BmpOut : TBGRABitmap;
  BmpGlyphs : TBGRABitmap;

  {$IFDEF LCLgtk2}
  CSSTransparent : TBGRAPixel = (red: 255; green: 255; blue: 255; alpha: 0);
  {$ELSE}
  CSSTransparent : TBGRAPixel = (blue: 255; green: 255; red: 255; alpha: 0);
  {$ENDIF}

  loading_fcv : Boolean = false;


implementation
{$R *.lfm}
{ TFCreator }

procedure TFCreator.RenderText( previsualizar: boolean; texto: string );
var
  Bitmap: TBGRABitmap;
  Renderer: TBGRATextEffectFontRenderer;
  Shader: TPhongShading;
  Grad: TBGRAGradientScanner;

  tox, toy : single;
  dwx, dwy : integer;

  PT : array[0..3] of TPointF;

begin
  if (previsualizar) then
    Bitmap := TBGRABitmap.Create(EdAncho.Value+2,EdAlto.Value+2,CBFondo.ButtonColor)
  else
    Bitmap := TBGRABitmap.Create(EdAncho.Value,EdAlto.Value, CSSTransparent);

  Shader := TPhongShading.Create;
  Renderer := TBGRATextEffectFontRenderer.Create(Shader, True);

  Bitmap.FontRenderer := Renderer;

  Renderer.OutlineVisible       := CBContorno.Checked;
  Renderer.OutlineColor         := ColorToBGRA( ColorToRGB(CBContornoC.ButtonColor) );
  Renderer.OutlineColor.alpha   := EdContornoA.Value;
  Renderer.OutlineWidth         := EdContornoG.Value;
  Renderer.OutlineTexture       := nil;


  Renderer.ShadowVisible        := CBSombra.Checked;
  Renderer.ShadowColor          := ColorToBGRA( ColorToRGB(CBSombraC.ButtonColor) );
  Renderer.ShadowColor.alpha    := EdSombraA.Value;
  Renderer.ShadowRadius         := EdSombraR.Value;
  Renderer.ShadowOffset.X       := EdSombraX.Value;
  Renderer.ShadowOffset.Y       := EdSombraX.Value;
  Renderer.ShadowQuality        := rbNormal;


  Renderer.ShaderActive         := CBShader.Checked;
  Renderer.ShaderLightPosition  := Point(EdShaderX.Value, EdShaderY.Value);


  Bitmap.PenStyle             := psClear;

  Bitmap.FontAntialias        := true;
  Bitmap.FontFullHeight       := FontDialog.Font.Size;
  Bitmap.FontName             := FontDialog.Font.Name;
  Bitmap.FontStyle            := FontDialog.Font.Style;
  //Bitmap.FontOrientation      := 0;
  Bitmap.FontQuality          := fqFineAntialiasing;

  tox := EdX.Value;
  toy := EdY.Value;
  if (previsualizar) then
  begin
    tox += 1;
    toy += 1;
  end;

  if (CBRellenoTipo.Text = 'Solid') then
  begin
    Bitmap.TextOut(tox, toy, texto, ColorToBGRA( ColorToRGB(CBRellenoC1.ButtonColor) ), taCenter);
  end else
  begin
    Grad := TBGRAGradientScanner.Create(
    ColorToBGRA( ColorToRGB(CBRellenoC1.ButtonColor) ),
    ColorToBGRA( ColorToRGB(CBRellenoC2.ButtonColor) ),
    StrToGradientType(CBRellenoTipo.Text),
    PointF(EdRellenoP1X.Value,EdRellenoP1Y.Value),
    PointF(EdRellenoP2X.Value,EdRellenoP2Y.Value),
    CBRellenoGamma.Checked, CBRellenoSinus.Checked);

    Bitmap.TextOut(tox, toy, texto, Grad, taCenter);
    Grad.Free;
  end;


  if (previsualizar) then
  begin
    PT[0].x := 0;
    PT[0].y := 0;
    PT[1].x := PT[0].x+Bitmap.Width-1;
    PT[1].y := PT[0].y;
    PT[2].x := PT[0].x+Bitmap.Width-1;
    PT[2].y := PT[0].y+Bitmap.Height-1;
    PT[3].x := PT[0].x;
    PT[3].y := PT[0].y+Bitmap.Height-1;
    Bitmap.DrawPolygonAntialias(pt, CSSGray, 1);

    FontPreview.Picture.Bitmap.Width:=Bitmap.Width;
    FontPreview.Picture.Bitmap.Height:=Bitmap.Height;
    Bitmap.Draw(FontPreview.Picture.Bitmap.Canvas,0,0);

  (*BmpOut.Free;
  BmpOut := TBGRABitmap.Create(FontPreview.Width, FontPreview.Height, CBFondo.ButtonColor);
  dwx := FontPreview.Width div 2;
  dwy := FontPreview.Height div 2;
  //Bitmap.Draw(FontPreview.Canvas, dwx-tox, dwy-toy);
  tox := Bitmap.Width div 2;
  toy := Bitmap.Height div 2;
  BmpOut.PutImage(dwx-tox, dwy-toy, Bitmap, dmSet);

  PT[0].x := dwx-tox-1;
  PT[0].y := dwy-toy-1;
  PT[1].x := PT[0].x+Bitmap.Width+1;
  PT[1].y := PT[0].y;
  PT[2].x := PT[0].x+Bitmap.Width+1;
  PT[2].y := PT[0].y+Bitmap.Height+1;
  PT[3].x := PT[0].x;
  PT[3].y := PT[0].y+Bitmap.Height+1;
  BmpOut.DrawPolygonAntialias(pt, CSSGray, 1);*)


  //FontPreview.RedrawBitmap;
  FontPreview.Repaint;
  end else
  begin
    FreeAndNil(BmpOut);
    BmpOut := TBGRABitmap.Create(Bitmap.Width, Bitmap.Height, CSSTransparent);
    BmpOut.PutImage(0,0,Bitmap, dmSet);
  end;

  FreeAndNil(Bitmap);
  //Renderer.Free;
end;

procedure TFCreator.TBAbrirClick(Sender: TObject);
var
  Lista : TStringList;
begin
  with OpenDialog1 do
    if Execute then
      if FileName <> '' then
      begin
      Lista := TStringList.Create;
      Lista.LoadFromFile(FileName);

      loading_fcv := true;
      Lista.NameValueSeparator:=':';
      FontDialog.Font.Name  := Lista.Values['FontName'];
      FontDialog.Font.Size  := StrToInt(Lista.Values['FontHeight']);
      FontDialog.Font.Style := TFontStyles(StrToInt(Lista.Values['FontStyle']));

      EdAncho.Value  := StrToInt(Lista.Values['ancho']);
      EdAlto.Value   := StrToInt(Lista.Values['alto']);
      EdX.Value      := StrToInt(Lista.Values['posX']);
      EdY.Value      := StrToInt(Lista.Values['posY']);

      CBContorno.Checked       := StrToBool(Lista.Values['Contorno']);
      EdContornoA.Value        := StrToInt(Lista.Values['ContornoA']);
      CBContornoC.ButtonColor  := StringToColor(Lista.Values['ContornoC']);
      EdContornoG.Value        := StrToFloat(Lista.Values['ContornoG']);

      CBSombra.Checked      := StrToBool(Lista.Values['Sombra']);
      EdSombraA.Value       := StrToInt(Lista.Values['SombraA']);
      CBSombraC.ButtonColor := StringToColor(Lista.Values['SombraC']);
      EdSombraR.Value       := StrToInt(Lista.Values['SombraR']);

      CBRellenoTipo.Text        := Lista.Values['Relleno'];
      CBRellenoC1.ButtonColor   := StringToColor(Lista.Values['RellenoC1']);
      EdRellenoP1X.Value        := StrToFloat(Lista.Values['RellenoP1X']);
      EdRellenoP1Y.Value        := StrToFloat(Lista.Values['RellenoP1Y']);
      CBRellenoC2.ButtonColor   := StringToColor(Lista.Values['RellenoC2']);
      EdRellenoP2X.Value        := StrToFloat(Lista.Values['RellenoP2X']);
      EdRellenoP2Y.Value        := StrToFloat(Lista.Values['RellenoP2Y']);
      CBRellenoGamma.Checked    := StrToBool(Lista.Values['RellenoGamma']);
      CBRellenoSinus.Checked    := StrToBool(Lista.Values['RellenoSinus']);

      CBShader.Checked    := StrToBool(Lista.Values['Shader']);
      EdShaderX.Value     := StrToInt(Lista.Values['ShaderX']);
      EdShaderY.Value     := StrToInt(Lista.Values['ShaderY']);

      EdGlyphs.Text       := Lista.Values['Glyphs'];
      if (EdGlyphs.Text = '') then EdGlyphs.Text:=' !"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~ºáéíóúñÑ¿¡ÁÉÍÓÚüÜ';

      SavePictureDialog.FileName := Lista.Values['Destination'];
      loading_fcv := false;

      PrevisualizarFuente(Sender);
      Lista.Free;

      SaveDialog1.FileName:=FileName;
      end;
end;

procedure TFCreator.TBSalvarClick(Sender: TObject);
var
  Lista : TStringList;
begin
  with SaveDialog1 do
    if Execute then
      if FileName <> '' then
      begin
      Lista := TStringList.Create;

      Lista.Add('#DIYen Font Creator Values#');
      Lista.NameValueSeparator:=':';
      Lista.Values['ancho'] := EdAncho.Text;
      Lista.Values['alto'] := EdAlto.Text;
      Lista.Values['posX'] := EdX.Text;
      Lista.Values['posY'] := EdY.Text;

      Lista.Values['Contorno'] := BoolToStr(CBContorno.Checked);
      Lista.Values['ContornoA'] := EdContornoA.Text;
      Lista.Values['ContornoC'] := ColorToString(CBContornoC.ButtonColor);
      Lista.Values['ContornoG'] := FloatToStr(EdContornoG.Value);

      Lista.Values['Sombra'] := BoolToStr(CBSombra.Checked);
      Lista.Values['SombraA'] := EdSombraA.Text;
      Lista.Values['SombraC'] := ColorToString(CBSombraC.ButtonColor);
      Lista.Values['SombraR'] := EdSombraR.Text;

      Lista.Values['Relleno'] := CBRellenoTipo.Text;
      Lista.Values['RellenoC1'] := ColorToString(CBRellenoC1.ButtonColor);
      Lista.Values['RellenoP1X'] := FloatToStr(EdRellenoP1X.Value);
      Lista.Values['RellenoP1Y'] := FloatToStr(EdRellenoP1Y.Value);
      Lista.Values['RellenoC2'] := ColorToString(CBRellenoC2.ButtonColor);
      Lista.Values['RellenoP2X'] := FloatToStr(EdRellenoP2X.Value);
      Lista.Values['RellenoP2Y'] := FloatToStr(EdRellenoP2Y.Value);
      Lista.Values['RellenoGamma'] := BoolToStr(CBRellenoGamma.Checked);
      Lista.Values['RellenoSinus'] := BoolToStr(CBRellenoSinus.Checked);

      Lista.Values['Shader'] := BoolToStr(CBShader.Checked);
      Lista.Values['ShaderX'] := EdShaderX.Text;
      Lista.Values['ShaderY'] := EdShaderY.Text;


      Lista.Values['FontName'] := FontDialog.Font.Name;
      Lista.Values['FontHeight'] := IntToStr(FontDialog.Font.Size);
      Lista.Values['FontStyle'] := IntToStr(integer(FontDialog.Font.Style));

      Lista.Values['Glyphs'] := EdGlyphs.Text;

      Lista.Values['Destination'] := SavePictureDialog.FileName;

      Lista.SaveToFile(FileName);
      Lista.Free;

      OpenDialog1.FileName:=FileName;
      end;
end;

procedure TFCreator.PrevisualizarFuente(Sender: TObject);
begin
  if not loading_fcv then
    RenderText(true, EdTexto.Text);
end;

procedure TFCreator.FontPreviewRedraw(Sender: TObject; Bitmap: TBGRABitmap);
begin

end;

procedure TFCreator.BGuardarClick(Sender: TObject);
begin
  with SavePictureDialog do
  if (Execute) then
    if (Filename <> '') then
      BmpGlyphs.SaveToFile(Filename);
end;

procedure TFCreator.FormCreate(Sender: TObject);
begin
  BmpOut := TBGRABitmap.Create(1,1);
  BmpGlyphs := TBGRABitmap.Create(1,1);
end;

procedure TFCreator.FormShow(Sender: TObject);
begin
  PrevisualizarFuente(Sender);
end;

procedure TFCreator.GlyphGenRedraw(Sender: TObject; Bitmap: TBGRABitmap);
begin
  GlyphGen.Width:= BmpGlyphs.Width;
  GlyphGen.Height:= BmpGlyphs.Height;
  GlyphGen.Left := 0;
  GlyphGen.Top := ScrollBox.Height div 2 - BmpGlyphs.Height;
  Bitmap.Fill(CBFondo.ButtonColor);
  Bitmap.PutImage(0,0, BmpGlyphs, dmDrawWithTransparency);
end;

procedure TFCreator.FontPreviewClick(Sender: TObject);
begin
  if FontDialog.Execute then PrevisualizarFuente(Sender);
end;

procedure TFCreator.BGenerarClick(Sender: TObject);
var
  n : integer;
  w, h, pa, xt : integer;
  c : char = #0;
  wc : string = '';
  cn : shortint;

  sglyphs : string = '';
  text_width, text_height : integer; // Tamaño esperado de los glyphs

begin

  w := EdAncho.Value;
  h := EdAlto.Value;
  sglyphs := EdGlyphs.Text;
  text_width := UTF8Length(sglyphs)*w;
  text_height:= h;

  FreeAndNil(BmpGlyphs);
  BmpGlyphs := TBGRABitmap.Create(text_width, text_height, CSSTransparent);

  n := 1; xt := 0;
  while n <= Length(sglyphs) do
  begin
    c := sglyphs[n];
    wc := wc+c;
    Inc(n);

    if (c = #195) or (c = #194) then
    begin
      wc := c;
      Continue;
    end;

    RenderText(false, wc);
    BmpGlyphs.PutImage(xt, 0, BmpOut, dmSet);

    wc := '';
    Inc(xt, w);
  end;

  GlyphGen.RedrawBitmap;
end;


end.

