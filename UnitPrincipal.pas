unit UnitPrincipal;

interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, REST.Types,
  Vcl.Buttons, REST.Client, System.JSON,
  Vcl.ComCtrls, Vcl.Imaging.pngimage, Vcl.CheckLst, System.Net.HttpClientComponent;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Bevel1: TBevel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel6: TPanel;
    Panel5: TPanel;
    Bevel2: TBevel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    Bevel3: TBevel;
    Bevel4: TBevel;
    RestCliente: TRESTClient;
    RestRequisicao: TRESTRequest;
    RestResposta: TRESTResponse;
    Nethttp: TNetHTTPClient;

    Bpesquisar: TBitBtn;
    BitBtn2: TBitBtn;
    Bevel5: TBevel;
    Panel10: TPanel;
    TpageControl1: TPageControl;
    Tabsheet1: TTabSheet;
    Tabsheet2: TTabSheet;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Lcategoria: TLabel;
    Lexperiencia: TLabel;
    Lpeso: TLabel;
    LAltura: TLabel;
    LId: TLabel;
    Traço: TLabel;
    Lnome: TLabel;
    Image1: TImage;
    ImagePokemon: TImage;
    ListPokémon: TListView;
    EnomePoke: TButtonedEdit;
    ImageFundo: TImage;
    Image2: TImage;
    PageControl1: TPageControl;
    TabSheet3: TTabSheet;
    LPesquisarPoke: TLabel;
    Panel12: TPanel;
    LfiltroGen: TLabel;
    CbGera: TCheckListBox;
    CbTipo: TCheckListBox;
    LtipagemFiltro: TLabel;
    Ptype1: TPanel;
    Ptype2: TPanel;
    Ltype1: TLabel;
    Ltype2: TLabel;
    procedure BpesquisarClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
    procedure CbGeraClick(Sender: TObject);
    procedure CbTipoClick(Sender: TObject);
    procedure ListPokémonSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
  private
    function TipoSelecionado: string;
    procedure ConfigurarApi;
    procedure LimparDados;
    procedure CarregarListaPokemons;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.ConfigurarApi;
begin
  RestCliente.UserAgent := 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  RestRequisicao.Method := rmGET;
end;

procedure TForm1.BpesquisarClick(Sender: TObject);
var
  NomePokemon, UrlImagem: string;
  LJsonObj: TJSONObject;
  Tipos: TJSONArray;
  Estatisticas: TJSONArray;
  TipoItem: TJSONObject;
  EstatisticaItem: TJSONObject;
  Altura, Peso: double;
  IdPokemon: Integer;
  ValorEstatistica: Integer;
  TextoEstatisticas: string;
  I: Integer;
  LBytes: TBytes;
  LStreamImg: TMemoryStream;
begin
  ImageFundo.SendToBack;

  NomePokemon := Trim(EnomePoke.Text);
  if NomePokemon = '' then
  begin
    LimparDados;
    ShowMessage('Deve introduzir um nome válido');
    Exit;
  end;

  ConfigurarApi;
  RestCliente.BaseURL := 'https://pokeapi.co/api/v2/pokemon/' + NomePokemon;

  try
    RestRequisicao.Execute;
    LimparDados;

    if RestResposta.StatusCode = 200 then
    begin
      LJsonObj := RestResposta.JSONValue as TJSONObject;
      if Assigned(LJsonObj) then
      begin
        LJsonObj.TryGetValue<Integer>('id', IdPokemon);
        LId.Caption := Format('%.4d', [IdPokemon]);

        Lnome.Caption := LJsonObj.GetValue<string>('name');

        if LJsonObj.TryGetValue<Double>('height', Altura) then
        begin
          LAltura.Caption := FormatFloat('0.0', Altura / 10) + 'm';
        end;

        if LJsonObj.TryGetValue<double>('weight', Peso) then
        begin
          Lpeso.Caption := FormatFloat('0.0', Peso / 10) + 'Kg';
        end;




        LExperiencia.Caption := LJsonObj.GetValue<string>('base_experience');

        TextoEstatisticas := '';
        if LJsonObj.TryGetValue<TJSONArray>('stats', Estatisticas) then
          for I := 0 to Estatisticas.Count - 1 do
          begin
            EstatisticaItem := Estatisticas.Items[I] as TJSONObject;
            ValorEstatistica := EstatisticaItem.GetValue<Integer>('base_stat');
            TextoEstatisticas := TextoEstatisticas +
              EstatisticaItem.GetValue<TJSONObject>('stat').GetValue<string>('name') + ': ' +
              IntToStr(ValorEstatistica) + '  ';
          end;
        Lcategoria.Caption := TextoEstatisticas;

        Ltype1.Caption := '';
        Ltype2.Caption := '';
        if LJsonObj.TryGetValue<TJSONArray>('types', Tipos) then
        begin
          if Tipos.Count > 0 then
          begin
            TipoItem := Tipos.Items[0] as TJSONObject;
            Ltype1.Caption := UpperCase(TipoItem.GetValue<TJSONObject>('type').GetValue<string>('name'));
          end;
          if Tipos.Count > 1 then
          begin
            TipoItem := Tipos.Items[1] as TJSONObject;
            Ltype2.Caption := UpperCase(TipoItem.GetValue<TJSONObject>('type').GetValue<string>('name'));
          end;
        end;
        UrlImagem := LJsonObj.GetValue<TJSONObject>('sprites').GetValue<string>('front_default');

        if Trim(UrlImagem) <> '' then
        begin
          RestCliente.BaseURL := UrlImagem;
          RestRequisicao.Execute;

          if RestResposta.StatusCode = 200 then
          begin
            LBytes := RestResposta.RawBytes;
            if Length(LBytes) > 0 then
            begin
              LStreamImg := TMemoryStream.Create;
              try
                LStreamImg.WriteBuffer(LBytes[0], Length(LBytes));
                LStreamImg.Position := 0;
                ImagePokemon.Picture.LoadFromStream(LStreamImg);
              finally
                LStreamImg.Free;
              end;
            end;
          end;
        end
        else
        begin
          ShowMessage('Imagem de pokémon não encontrada');
        end;
      end;
    end
    else
    begin
      ShowMessage('Erro HTTP ao buscar Pokémon. Status: ' + IntToStr(RestResposta.StatusCode));
    end;

  except
    on E: Exception do
      ShowMessage('Erro ao buscar o pokémon: ' + E.Message);
  end;
end;

function TForm1.TipoSelecionado: string;
begin
  Result := '';
  if (CbTipo.ItemIndex < 0) or not CbTipo.Checked[CbTipo.ItemIndex] then
    Exit;

  case CbTipo.ItemIndex of
    0: Result := 'steel'; 1: Result := 'water'; 2: Result := 'bug';
    3: Result := 'dragon'; 4: Result := 'electric'; 5: Result := 'fairy';
    6: Result := 'ghost'; 7: Result := 'fire'; 8: Result := 'ice';
    9: Result := 'bug'; 10: Result := 'fighting'; 11: Result := 'normal';
    12: Result := 'rock'; 13: Result := 'psychic'; 14: Result := 'dark';
  end;
end;

procedure TForm1.CarregarListaPokemons;
var
  LJsonObj: TJSONObject;
  LresultsArray: TJSONArray;
  LitemObj: TJSONObject;
  PokemonObj: TJSONObject;
  I: integer;
  ListItem: TListItem;
begin
   if CbGera.ItemIndex < 0 then
     CbGera.ItemIndex := 0;

   if TipoSelecionado <> '' then
     RestCliente.BaseURL := 'https://pokeapi.co/api/v2/type/' + LowerCase(TipoSelecionado)
   else
   case CbGera.ItemIndex of
    0: RestCliente.BaseURL := 'https://pokeapi.co/api/v2/pokemon?limit=151';
    1: RestCliente.BaseURL := 'https://pokeapi.co/api/v2/generation/2/';
    2: RestCliente.BaseURL := 'https://pokeapi.co/api/v2/generation/3/';
    3: RestCliente.BaseURL := 'https://pokeapi.co/api/v2/generation/4/';
    4: RestCliente.BaseURL := 'https://pokeapi.co/api/v2/generation/5/';
    5: RestCliente.BaseURL := 'https://pokeapi.co/api/v2/generation/6/';
    6: RestCliente.BaseURL := 'https://pokeapi.co/api/v2/generation/7/';
    7: RestCliente.BaseURL := 'https://pokeapi.co/api/v2/generation/8/';
    8: RestCliente.BaseURL := 'https://pokeapi.co/api/v2/generation/9/';
    else
      RestCliente.BaseURL := 'https://pokeapi.co/api/v2/pokemon?limit=151';
   end;

   // para não perder o chamado de api antes ao carregar a lista
   ConfigurarApi;

   try
      RestRequisicao.Execute;

      if RestResposta.StatusCode = 200 then
      begin
        ListPokémon.Items.Clear;

        LJsonObj := RestResposta.JSONValue as TJSONObject;
        if Assigned(LJsonObj) then
        begin
          if not LJsonObj.TryGetValue<TJSONArray>('results', Lresultsarray) then
          begin
            LjsonObj.TryGetValue<TJsonarray>('pokemon_species', Lresultsarray);
            end;
            if Assigned(LresultsArray) then
            begin
              ListPokémon.Items.BeginUpdate;
            try
              for I := 0 to LresultsArray.Count - 1 do
              begin
                LitemObj := LresultsArray.Items[I] as TJSONObject;
                ListItem := ListPokémon.Items.Add;
                if LitemObj.TryGetValue<TJSONObject>('pokemon', PokemonObj) then
                  ListItem.Caption := PokemonObj.GetValue<string>('name')
                else
                  ListItem.Caption := LitemObj.GetValue<string>('name');
              end;
            finally
              ListPokémon.Items.EndUpdate;
            end;
          end;
        end;
      end
      else
      begin
        ShowMessage('Erro HTTP ao carregar lista. Status: ' + IntToStr(RestResposta.StatusCode));
      end;

   except
      on E: Exception do
        ShowMessage('Erro ao carregar a lista pokémon: ' + E.Message);
   end;
end;

procedure TForm1.CbGeraClick(Sender: TObject);
begin
  CarregarListaPokemons;
end;

procedure TForm1.CbTipoClick(Sender: TObject);
begin
  CarregarListaPokemons;
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if key = #13 then
  begin
    Bpesquisar.Click;
    key := #0;
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  LimparDados;

  // Para não Falhar a requisição em outras redes wifi
  ConfigurarApi;

  CbGera.ItemIndex := 0;
  CarregarListaPokemons;
  EnomePoke.SetFocus;
end;

procedure TForm1.LimparDados;
begin
  LId.Caption := '';
  lnome.Caption := '';
  laltura.Caption := '';
  lpeso.Caption := '';
  Lexperiencia.Caption := '';
  ImagePokemon.Picture.Graphic := nil;
end;

procedure TForm1.ListPokémonSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
var
  NomePokemon: string;
begin
  if Selected and Assigned(Item) then
  begin
      NomePokemon := item.Caption;
      EnomePoke.Text := NomePokemon;
      Bpesquisar.Click;
  end;
end;

end.
