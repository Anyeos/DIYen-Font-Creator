unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, FileCtrl, EditBtn, Spin,
  BGRAVirtualScreen, BGRABitmap,
  BGRABitmapTypes, BGRATransform, LCLProc, Buttons, LazUTF8,
  inifiles;

type

  { TFM }

  TFM = class(TForm)
    BitBtn1: TBitBtn;
    BCenter: TButton;
    CBAlign: TComboBox;
    CBBk: TColorButton;
    CBFont: TColorButton;
    ControlBar1: TPanel;
    EdAlpha: TSpinEdit;
    EdSize: TSpinEdit;
    EdX: TSpinEdit;
    EdY: TSpinEdit;
    PanelSample: TPanel;
    Panel2: TPanel;
    PanelTop: TPanel;
    TextOut: TBGRAVirtualScreen;
    EdTexto: TEdit;
    ImgFont: TBGRAVirtualScreen;
    EdDirFonts: TDirectoryEdit;
    FileList: TFileListBox;
    GroupFontlist: TGroupBox;
    Panel3: TPanel;
    ScrollBox: TScrollBox;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    procedure BCenterClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure EdDirFontsAcceptDirectory(Sender: TObject; var Value: String
      );
    procedure EdDirFontsChange(Sender: TObject);
    procedure EdTextoChange(Sender: TObject);
    procedure FileListClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure ImgFontRedraw(Sender: TObject; Bitmap: TBGRABitmap);
    procedure PanelSampleResize(Sender: TObject);
    procedure PanelTopResize(Sender: TObject);
    procedure TextOutRedraw(Sender: TObject; Bitmap: TBGRABitmap);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  FM: TFM;
  Imagen : TBGRABitmap;
  Config : TIniFile;

  loading_config: Boolean = false;

implementation
  uses creator;

function DesplazarRectangulo(P0 : TPointF; PD : ArrayOfTPointF): ArrayOfTPointF;
begin
  SetLength(Result, 4);
  Result[0] := PointF(PD[0].x+P0.x, PD[0].y+P0.y);
  Result[1] := PointF(PD[1].x+P0.x, PD[1].y+P0.y);
  Result[2] := PointF(PD[2].x+P0.x, PD[2].y+P0.y);
  Result[3] := PointF(PD[3].x+P0.x, PD[3].y+P0.y);
end;

function CrearRectangulo(ancho, alto, angulo : single): ArrayOfTPointF;
var
  PR1, PR2, PR3, PR4 : TPointF;
  P1, P2, P3, P4 : TPointF;
  cosb, senb	: single;
begin
  P1 := PointF(ancho/2, alto/2);
  P2 := PointF(-P1.x, P1.y);
  P3 := PointF(-P1.x, -P1.y);
  P4 := PointF(P1.x, -P1.y);

  cosb := cos(angulo*pi/180);
  senb := sin(angulo*pi/180);

  PR1 := PointF(P1.x*cosb-P1.y*senb, P1.y*cosb+P1.x*senb);
  PR2 := PointF(P2.x*cosb-P2.y*senb, P2.y*cosb+P2.x*senb);
  PR3 := PointF(P3.x*cosb-P3.y*senb, P3.y*cosb+P3.x*senb);
  PR4 := PointF(P4.x*cosb-P4.y*senb, P4.y*cosb+P4.x*senb);

  SetLength(Result, 4);
  Result[0] := PR1;
  Result[1] := PR2;
  Result[2] := PR3;
  Result[3]	:= PR4;
end;

function CrearRectanguloTextura(ancho, alto, angulo : single): ArrayOfTPointF;
var
  PR1, PR2, PR3, PR4 : TPointF;
  P1, P2, P3, P4 : TPointF;
  cosb, senb	: single;
begin
  P1 := PointF(ancho, alto);
  P2 := PointF(0, alto);
  P3 := PointF(0, 0);
  P4 := PointF(ancho, 0);

  cosb := cos(angulo*pi/180);
  senb := sin(angulo*pi/180);

  PR1 := PointF(P1.x*cosb-P1.y*senb, P1.y*cosb+P1.x*senb);
  PR2 := PointF(P2.x*cosb-P2.y*senb, P2.y*cosb+P2.x*senb);
  PR3 := PointF(P3.x*cosb-P3.y*senb, P3.y*cosb+P3.x*senb);
  PR4 := PointF(P4.x*cosb-P4.y*senb, P4.y*cosb+P4.x*senb);

  SetLength(Result, 4);
  Result[0] := PR1;
  Result[1] := PR2;
  Result[2] := PR3;
  Result[3]	:= PR4;
end;

function CrearRectanguloP(P0: TPointF; ancho, alto, angulo : single): ArrayOfTPointF;
begin
	SetLength(Result, 4);
  Result := CrearRectangulo(ancho, alto, angulo);
  Result := DesplazarRectangulo(P0, Result);
end;

function RectanguloDeRectangulo(Rectangulo : ArrayOfTPointF): ArrayOfTPointF;
	var
    P1, P2, P3, P4 : TPointF;
    PR	: TPointF;
    a	: integer;
begin
  	P1.x := Rectangulo[0].x;
    P1.y := Rectangulo[0].y;

  	P2.x := Rectangulo[1].x;
    P2.y := Rectangulo[1].y;

   	P3.x := Rectangulo[2].x;
    P3.y := Rectangulo[2].y;

  	P4.x := Rectangulo[3].x;
    P4.y := Rectangulo[3].y;

	for a := 0 to 3 do
  begin
    PR := Rectangulo[a];
  	if (PR.x > P1.x) then P1.x := PR.x;
    if (PR.y > P1.y) then P1.y := PR.y;

    if (PR.x < P2.x) then P2.x := PR.x;
    if (PR.y > P2.y) then P2.y := PR.y;

    if (PR.x < P3.x) then P3.x := PR.x;
    if (PR.y < P3.y) then P3.y := PR.y;

    if (PR.x > P4.x) then P4.x := PR.x;
    if (PR.y < P4.y) then P4.y := PR.y;
  end;
	SetLength(Result, 4);
  Result[0] := P1;
  Result[1] := P2;
  Result[2] := P3;
  Result[3]	:= P4;
end;

{$R *.lfm}

{ TFM }


procedure TFM.EdDirFontsAcceptDirectory(Sender: TObject; var Value: String
  );
begin

end;

procedure TFM.EdDirFontsChange(Sender: TObject);
begin
  FileList.Directory := EdDirFonts.Text;
  Config.WriteString('Visor', 'directory', FileList.Directory);
end;

procedure TFM.BCenterClick(Sender: TObject);
begin
  EdX.Value:=TextOut.Width div 2;
  EdY.Value:=TextOut.Height div 2;
end;

procedure TFM.BitBtn1Click(Sender: TObject);
begin
  //FCreator.Left:=FM.left+FM.Width;
  //FCreator.Top:=FM.Top;
  FCreator.Show;
end;

procedure TFM.EdTextoChange(Sender: TObject);
begin
  if not loading_config then
  begin
    Config.WriteString('Visor', 'text', EdTexto.Text);
    Config.WriteString('Visor', 'align', CBAlign.Text);
    Config.WriteInteger('Visor', 'X', EdX.Value);
    Config.WriteInteger('Visor', 'Y', EdY.Value);
    Config.WriteInteger('Visor', 'Size', EdSize.Value);
    Config.WriteInteger('Visor', 'Alpha', EdAlpha.Value);
    Config.WriteString('Visor', 'Background', ColorToString(CBBk.Color));
    TextOut.RedrawBitmap;
  end;
end;


procedure TFM.FileListClick(Sender: TObject);
var
  fpath : string;
begin
  //if (Imagen <> nil) then Imagen.Free;
  fpath := FileList.Directory+DirectorySeparator+FileList.Items[FileList.ItemIndex];
  Imagen.LoadFromFile(fpath);
  //ImgFont.Caption:=fpath;
  ImgFont.RedrawBitmap;
  TextOut.RedrawBitmap;
end;

procedure TFM.FormCreate(Sender: TObject);
begin
  // Define estándares para trabajar con archivos
  DefaultFormatSettings.DecimalSeparator:='.';

  Config := TIniFile.Create(GetAppConfigDir(false)+'main.conf');

  PanelTop.Height:=Config.ReadInteger('Visor', 'top.height', PanelTop.Height);
  PanelSample.Width:=Config.ReadInteger('Visor', 'sample.width', PanelSample.Width);
  FM.Width:=Config.ReadInteger('Visor', 'form.width', FM.Width);
  FM.Height:=Config.ReadInteger('Visor', 'form.height', FM.Height);

  EdDirFonts.Text:= Config.ReadString('Visor', 'directory', FileList.Directory);
  Imagen := TBGRABitmap.Create(1,1);

  loading_config := true;
  EdTexto.Text := Config.ReadString('Visor', 'text', EdTexto.Text);
  CBAlign.Text := Config.ReadString('Visor', 'align', CBAlign.Text);
  EdX.Value := Config.ReadInteger('Visor', 'X', TextOut.Width div 2);
  EdY.Value := Config.ReadInteger('Visor', 'Y', TextOut.Height div 2);
  EdSize.Value := Config.ReadInteger('Visor', 'Size', EdSize.Value);
  EdAlpha.Value := Config.ReadInteger('Visor', 'Alpha', EdAlpha.Value);
  CBBk.Color := StringToColor(Config.ReadString('Visor', 'Background', ColorToString(CBBk.Color)));
  loading_config := false;
end;

procedure TFM.FormResize(Sender: TObject);
begin
  Config.WriteInteger('Visor', 'form.width', FM.Width);
  Config.WriteInteger('Visor', 'form.height', FM.Height);
end;

procedure TFM.ImgFontRedraw(Sender: TObject; Bitmap: TBGRABitmap);
begin
  ImgFont.Width := Imagen.Width;
  ImgFont.Height:= Imagen.Height;
  ImgFont.Left := 0;
  ImgFont.Top := ScrollBox.Height div 2 - Imagen.Height;
  Bitmap.Fill(CBBk.ButtonColor);
  Bitmap.PutImage(0,0, Imagen, dmDrawWithTransparency);
end;

procedure TFM.PanelSampleResize(Sender: TObject);
begin
  Config.WriteInteger('Visor', 'sample.width', PanelSample.Width);
end;

procedure TFM.PanelTopResize(Sender: TObject);
begin
  Config.WriteInteger('Visor', 'top.height', PanelTop.Height);
end;

procedure TFM.TextOutRedraw(Sender: TObject; Bitmap: TBGRABitmap);
var
  // Valores iniciales
  x, y, size : integer;
  alpha : byte;
  stexto : string;

  // Para analizar y graficar la cadena
  n : integer;
  w, h, pa, xt : integer;
  c : char;
  wc : string; // WideChar (cuando nos toca Ñ á y esas cosas)
  cn : shortint; // Valor para ubicar el caracter

  affine : TBGRAAffineBitmapTransform; // Para extaer los caracteres de la imagen
  ptt : array[0..3] of TPointF;
  ptg : array[0..3] of TPointF;
  //RRot 		: ArrayOfTPointF;
  //RTam		: ArrayOfTPointF;

  BitmapText : TBGRABitmap;
  text_width, text_height : integer; // Tamaño esperado del texto

  alx, aly : integer; // Punto de partida para alineación
begin
  x := StrToIntDef(EdX.Text, 0);
  y := StrToIntDef(EdY.Text, 0);
  size := StrToIntDef(EdSize.Text, 0);
  alpha := Byte(StrToIntDef(EdAlpha.Text, 0));

  Bitmap.Fill(CBBk.ButtonColor);
  stexto := EdTexto.Text;


  w := Imagen.Width div 111;
  h := Imagen.Height;

  text_width := Utf8Length(stexto)*w;
  text_height:= h;
  //BitmapText := TBGRABitmap.Create(text_width*size div 100, text_height*size div 100);
  BitmapText := TBGRABitmap.Create(text_width, text_height);

  n := 1; xt := 0;
  while n <= Length(stexto) do
  begin
    c := stexto[n];
    Inc(n);

    if (c = #195) or (c = #194) then
    begin
      wc := c+stexto[n];
      Continue;
    end else
    begin
      case wc of
      'º' : cn := 95;
      'á' : cn := 96;
      'é' : cn := 97;
      'í' : cn := 98;
      'ó' : cn := 99;
      'ú' : cn := 100;
      'ñ' : cn := 101;
      'Ñ' : cn := 102;
      '¿' : cn := 103;
      '¡' : cn := 104;
      'Á' : cn := 105;
      'É' : cn := 106;
      'Í' : cn := 107;
      'Ó' : cn := 108;
      'Ú' : cn := 109;
      'ü' : cn := 110;
      'Ü' : cn := 111;
      otherwise
        cn := Ord(c)-32;
      end;
      wc := '';
    end;


    ptg[0].x := cn*w+w;
    ptg[0].y := h;
    ptg[1].x := cn*w;
    ptg[1].y := h;
    ptg[2].x := cn*w;
    ptg[2].y := 0;
    ptg[3].x := cn*w+w;
    ptg[3].y := 0;
    //Bitmap.FillPoly(pts, Imagen, dmLinearBlend);

    affine := TBGRAAffineBitmapTransform.Create(Imagen,False,False, rfLinear);
    //affine.GlobalOpacity := 20;
    //affine.RotateDeg(angulo);
    //RRot 	:= CrearRectanguloP(PointF(x+w div 2, y+h div 2), w, h, 0);
    ptt[0].x := xt+w;
    ptt[0].y := h;
    ptt[1].x := xt;
    ptt[1].y := h;
    ptt[2].x := xt;
    ptt[2].y := 0;
    ptt[3].x := xt+w;
    ptt[3].y := 0;
    //RTam 	:= CrearRectanguloTextura(Imagen.width, Imagen.Height, 0);
    //usar esta transformación como parámetro en vez de tex
    BitmapText.FillPolyLinearMapping(ptt, affine, ptg, true );
    //image.FillPoly(RRot, affine, dmDrawWithTransparency);
    //image.FillPolyAntialias(RRot, affine);
    //image.DrawPolygonAntialias(RRot, BGRABlue, 2);
    //image.DrawPolygonAntialias(RTam, BGRARed, 2);
    //image.DrawPolygonAntialias(RectanguloDeRectangulo(RRot), BGRAGreen, 2);

    affine.Free;
    Inc(xt, w);
  end;

  //BitmapText.Filter

  // La alineación la realizamos acá
  case CBAlign.Text of
    'TA_TOP_LEFT':
      begin
      alx := 0;
      aly := 0;
      end;
    'TA_TOP':
      begin
      alx := -BitmapText.Width div 2;
      aly := 0;
      end;
    'TA_TOP_RIGHT':
      begin
      alx := -BitmapText.Width;
      aly := 0;
      end;
    'TA_CENTER_LEFT':
      begin
      alx := 0;
      aly := -BitmapText.Height div 2;
      end;
    'TA_CENTER':
      begin
      alx := -BitmapText.Width div 2;
      aly := -BitmapText.Height div 2;
      end;
    'TA_CENTER_RIGHT':
      begin
      alx := -BitmapText.Width;
      aly := -BitmapText.Height div 2;
      end;
    'TA_BOTTOM_LEFT':
      begin
      alx := 0;
      aly := -BitmapText.Height;
      end;
    'TA_BOTTOM':
      begin
      alx := -BitmapText.Width div 2;
      aly := -BitmapText.Height;
      end;
    'TA_BOTTOM_RIGHT':
      begin
      alx := -BitmapText.Width;
      aly := -BitmapText.Height;
      end;
    otherwise
      alx := 0;
      aly := 0;
  end;

  Bitmap.BlendImageOver(x+alx, y+aly, BitmapText, boLinearBlend, alpha, true);
  BitmapText.Free;
end;

end.

