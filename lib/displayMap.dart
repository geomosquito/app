import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class DisplayMap extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double zoom;
  const DisplayMap(
      {Key? key,
      required this.latitude,
      required this.longitude,
      required this.zoom})
      : super(key: key);
  @override
  _DisplayMapState createState() => _DisplayMapState();
}

class _DisplayMapState extends State<DisplayMap> {
  GoogleMapController? mapController;
  Set<Marker> markers = <Marker>{};
  bool _isMarked = false;
  double _novaLatitude = 0.0, _novaLongitude = 0.0;
  bool _formVisible = false;
  int _botaoSimNao = 0;
  int _botaoInsidencia = 0;
  bool _informouTubo = false;
  bool _isLoggin = true;
  bool _erroLogin = false;
  bool _coletou = false;

  bool _tela1 = false;
  bool _tela2 = false;
  bool _tela3 = false;
  bool _tela4 = false;

  final String _ip = 'https://geomosquito.ipe.eco.br/api/';

  final TextEditingController _ctrlQuantidadeMosquito = TextEditingController();
  final TextEditingController _ctrlNumeroTubo = TextEditingController();
  final TextEditingController _ctrlChaveAcesso = TextEditingController();

  final _formKey = GlobalKey<FormState>(); //Controla o Form

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController?.moveCamera(
        CameraUpdate.newLatLng(LatLng(widget.latitude, widget.longitude)));
  }

  Future<void> salvarColeta(int tubo, int quantidade, int insidencia) async {
    try {
      var body = {
        "codigoTubo": tubo.toString(),
        "qtdIndividuos": "0", //quantidade.toString(),
        "latitude": _novaLatitude.toString(),
        "longitude": _novaLongitude.toString(),
        "incidencia": "0" //_botaoInsidencia.toString()
      };
      final response =
          await http.post(Uri.parse(_ip + 'salvarColeta.php'), body: body);
      if (response.statusCode == 200) {
        setState(() {
          _formVisible = false;
          _ctrlNumeroTubo.text = "";
          _ctrlQuantidadeMosquito.text = "";
          _botaoInsidencia = 0;
          _botaoSimNao = 0;
          _coletou = true;
          _tela1 = false; //Telas de instru????o
          _tela2 = false;
          _tela3 = false;
          _tela4 = false;
        });
      } else {
        throw Exception('Erro');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> getAccess(String key) async {
    try {
      final response =
          await http.get(Uri.parse(_ip + 'getAccess.php?key=${key}'));
      if (response.statusCode == 200) {
        if (json.decode(response.body)["result"].toString() == "success") {
          setState(() {
            _isLoggin = false;
            _erroLogin = false;
          });
        } else {
          _isLoggin = false;
          _erroLogin = true;
        }
      } else {
        throw Exception('Erro');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  _inserirMarcador(double latitude, double longitude) {
    setState(() {
      markers.clear();
      final Marker marker = Marker(
          markerId: const MarkerId("123456"),
          position: LatLng(latitude, longitude),
          infoWindow: const InfoWindow(
              title: "Localiza????o do Colaborador",
              snippet: "Local aproximado"));
      markers.add(marker);
      _isMarked = true;
      _novaLatitude = latitude;
      _novaLongitude = longitude;
    });
  }

  _gravaPosicao(double latitude, double longitude) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble("LATITUDE", latitude);
    prefs.setDouble("LONGITUDE", longitude);
    prefs.setBool("MARCADO", true);
  }

  _getPosicao() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getDouble("LATITUDE") != null) {
      if (prefs.getDouble("LONGITUDE") != null) {
        setState(() {
          _novaLatitude = prefs.getDouble("LATITUDE") as double;
          _novaLongitude = prefs.getDouble("LONGITUDE") as double;
        });
      }
    } else {
      setState(() {
        _novaLatitude = widget.latitude;
        _novaLongitude = widget.longitude;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getPosicao();
  }

  @override
  Widget build(BuildContext context) {
    double maxW = MediaQuery.of(context).size.width;
    double maxH = MediaQuery.of(context).size.height;

    if (widget.latitude != 0.0 && !_isMarked) {
      mapController?.moveCamera(
          CameraUpdate.newLatLng(LatLng(widget.latitude, widget.longitude)));
      //_inserirMarcador(_novaLatitude, _novaLongitude);
      _inserirMarcador(widget.latitude, widget.longitude);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("MosquitoGeo - IPE v.0.1.3"),
      ),
      body: Stack(
        children: [
          GoogleMap(
            markers: markers,
            onMapCreated: _onMapCreated,
            mapType: MapType.satellite,
            onTap: (value) {
              _inserirMarcador(value.latitude, value.longitude);
              setState(() {
                _novaLatitude = value.latitude;
                _novaLongitude = value.longitude;
              });
            },
            initialCameraPosition: CameraPosition(
                target: LatLng(
                  _novaLatitude,
                  _novaLongitude,
                ),
                zoom: widget.zoom),
          ),
          Visibility(
            visible: _formVisible,
            child: Center(
              child: Container(
                width: maxW,
                height: maxH,
                color: Colors.yellow[50]!.withOpacity(0.5),
                child: Center(
                  child: Container(
                    width: (maxW * 0.8),
                    height: (maxH * 0.65),
                    padding: const EdgeInsets.all(12.0),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        // ignore: prefer_const_literals_to_create_immutables
                        children: [
                          const Text(
                            "Ol?? cientista cidad??o, tudo bem?",
                            style: TextStyle(
                                fontSize: 20.0, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(
                            height: 15.0,
                          ),
                          const Text(
                            "Para continuar, por favor informe o n??mero do seu tubo",
                            style: TextStyle(fontSize: 15.0),
                          ),
                          TextFormField(
                            controller: _ctrlNumeroTubo,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            autofocus: true,
                            style: const TextStyle(
                                fontSize: 20.0, color: Color(0xFFbdc6cf)),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'N??mero do tubo',
                              contentPadding: const EdgeInsets.only(
                                  left: 14.0, bottom: 2.0, top: 2.0),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(25.7),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(25.7),
                              ),
                            ),
                            onChanged: (text) {
                              setState(() {
                                _informouTubo = false;
                                _informouTubo = (int.parse(text) > 0);
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe o n??mero do seu tubo';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(
                            height: 10.0,
                          ),
                          Column(
                            // ignore: prefer_const_literals_to_create_immutables
                            children: [
                              const Text(
                                "Sua localiza????o mapa est?? correta?",
                                style: TextStyle(fontSize: 15.0),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  MaterialButton(
                                    height: 40.0,
                                    minWidth: 50.0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        side: BorderSide(
                                            color: _botaoSimNao == 1
                                                ? Colors.green
                                                : Colors.white60)),
                                    color: _botaoSimNao == 1
                                        ? Colors.greenAccent
                                        : Colors.grey,
                                    textColor: Colors.white,
                                    child: const Text("Sim"),
                                    onPressed: () {
                                      setState(() {
                                        _botaoSimNao = 1; //sim
                                      });
                                    },
                                    splashColor: Colors.redAccent,
                                  ),
                                  const SizedBox(
                                    width: 50,
                                  ),
                                  MaterialButton(
                                    height: 40.0,
                                    minWidth: 50.0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        side: const BorderSide(
                                            color: Colors.white60)),
                                    color: Colors.grey,
                                    textColor: Colors.white,
                                    child: const Text("N??o"),
                                    onPressed: () {
                                      setState(() {
                                        _formVisible = false;
                                        _botaoSimNao = 0; //n??o
                                      });
                                    },
                                    splashColor: Colors.redAccent,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10.0,
                          ),
                          TextButton(
                            onPressed: () {
                              salvarColeta(
                                int.parse(_ctrlNumeroTubo.text),
                                0, //int.parse(_ctrlQuantidadeMosquito.text),
                                0, //_botaoInsidencia
                              );
                            },
                            child: Text(
                              'Continuar',
                              style: TextStyle(
                                fontSize: 20.0,
                                color: (_informouTubo &&
                                        //_informouQtde &&
                                        _botaoSimNao == 1 //&&
                                    //_botaoInsidencia > 0
                                    )
                                    ? Colors.blueAccent
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    color: Colors.grey[50]!.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          Visibility(
            visible: _coletou,
            child: Center(
              child: Container(
                width: maxW,
                height: maxH,
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    width: maxW * 0.8,
                    height: maxH * 0.6,
                    color: Colors.white60,
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      // ignore: prefer_const_literals_to_create_immutables
                      children: [
                        const Text(
                          'Pronto! Sua coleta foi registrada',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        const Text(
                          'Obrigado por participar da pesquisa, at?? a pr??xima!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        const Text(
                          'Fique de olho nas atualiza????es para acompanhar o resultado',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        MaterialButton(
                          height: 60.0,
                          minWidth: 100.0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              side: BorderSide(
                                  color: _botaoInsidencia == 5
                                      ? Colors.green
                                      : Colors.white60)),
                          color: _botaoInsidencia == 5
                              ? Colors.greenAccent
                              : Colors.grey,
                          textColor: Colors.white,
                          child: const Text("Sair"),
                          onPressed: () {
                            exit(0);
                          },
                          splashColor: Colors.redAccent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Visibility(
            visible: _isLoggin,
            child: Center(
              child: Container(
                width: maxW,
                height: maxH,
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    width: maxW * 0.8,
                    height: maxH * 0.6,
                    color: Colors.white60,
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      // ignore: prefer_const_literals_to_create_immutables
                      children: [
                        const Text(
                          'Ol??! Informe sua chave de acesso',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextFormField(
                          obscureText: true,
                          controller: _ctrlChaveAcesso,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          autofocus: true,
                          style: const TextStyle(
                              fontSize: 20.0, color: Color(0xFFbdc6cf)),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Chave de acesso',
                            contentPadding: const EdgeInsets.only(
                                left: 14.0, bottom: 2.0, top: 2.0),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(25.7),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(25.7),
                            ),
                          ),
                          onChanged: (text) {
                            setState(() {
                              _informouTubo = false;
                              _informouTubo = (int.parse(text) > 0);
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe a chave de acesso';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        MaterialButton(
                          height: 60.0,
                          minWidth: 100.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            side: const BorderSide(
                              color: Colors.green,
                            ),
                          ),
                          color: Colors.greenAccent,
                          textColor: Colors.white,
                          child: const Text("Entrar"),
                          onPressed: () {
                            setState(() {
                              getAccess(_ctrlChaveAcesso.text);
                            });
                          },
                          splashColor: Colors.redAccent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Visibility(
            visible: _erroLogin,
            child: Center(
              child: Container(
                width: maxW,
                height: maxH,
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    width: maxW * 0.8,
                    height: maxH * 0.6,
                    color: Colors.white60,
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      // ignore: prefer_const_literals_to_create_immutables
                      children: [
                        const Text(
                          'Chave inv??lida!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        MaterialButton(
                          height: 60.0,
                          minWidth: 100.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            side: const BorderSide(color: Colors.green),
                          ),
                          color: Colors.greenAccent,
                          textColor: Colors.white,
                          child: const Text("OK"),
                          onPressed: () {
                            setState(() {
                              _erroLogin = false;
                              _isLoggin = true;
                            });
                          },
                          splashColor: Colors.redAccent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          //Instru????es de Uso
          //Tela1
          Visibility(
            visible: _tela1,
            child: Center(
              child: Container(
                width: maxW,
                height: maxH,
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    width: maxW * 0.8,
                    height: maxH * 0.8,
                    color: Colors.white60,
                    padding: const EdgeInsets.all(12.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        // ignore: prefer_const_literals_to_create_immutables
                        children: [
                          const Text(
                            'Ol??, como vai?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const Text(
                            'Agradecemos sua colabora????o no monitoramento dos pernilongos da sua regi??o. Sua ajuda vai gerar importantes informa????es sobre esses bichos, inclusive aqueles que ocorrem no seu bairro. Os dados de cada participante ser??o analisados para estabelecer padr??es na distribui????o de pernilongos do munic??pio, assim poderemos avaliar quais esp??cies ocorrem em quais locais.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          MaterialButton(
                            height: 60.0,
                            minWidth: 100.0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                side: BorderSide(
                                    color: _botaoInsidencia == 5
                                        ? Colors.green
                                        : Colors.white60)),
                            color: _botaoInsidencia == 5
                                ? Colors.greenAccent
                                : Colors.grey,
                            textColor: Colors.white,
                            child: const Text("Continuar"),
                            onPressed: () {
                              setState(() {
                                _tela1 = false;
                                _tela2 = true;
                              });
                            },
                            splashColor: Colors.redAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          //Tela2
          Visibility(
            visible: _tela2,
            child: Center(
              child: Container(
                width: maxW,
                height: maxH,
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    width: maxW * 0.8,
                    height: maxH * 0.8,
                    color: Colors.white60,
                    padding: const EdgeInsets.all(12.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        // ignore: prefer_const_literals_to_create_immutables
                        children: [
                          const Text(
                            '?? simples!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const Text(
                            'Para Coletar os pernilongos:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const Text(
                            'Voc?? recebeu um tubo para participar do projeto e toda vez que voc?? matar um pernilongo basta colet??-lo, colocar no tubo, guardar no congelador e registrar a coleta aqui no app.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const Text(
                            'Para matar os pernilongos voc?? pode utilizar qualquer t??cnica: esmagar (com a m??o ou algum objeto), usar inseticida e at?? usar uma raquete el??trica. O importante ?? que os pernilongos sejam colocados no tubo e guardados no congelador da sua casa at?? a data de entrega do tubo. Recomendamos que voc?? realize as coletas durante um m??s e depois devolva o tubo no lugar combinado.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          MaterialButton(
                            height: 60.0,
                            minWidth: 100.0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                side: BorderSide(
                                    color: _botaoInsidencia == 5
                                        ? Colors.green
                                        : Colors.white60)),
                            color: _botaoInsidencia == 5
                                ? Colors.greenAccent
                                : Colors.grey,
                            textColor: Colors.white,
                            child: const Text("Continuar"),
                            onPressed: () {
                              setState(() {
                                _tela2 = false;
                                _tela3 = true;
                              });
                            },
                            splashColor: Colors.redAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          //Tela3
          Visibility(
            visible: _tela3,
            child: Center(
              child: Container(
                width: maxW,
                height: maxH,
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    width: maxW * 0.8,
                    height: maxH * 0.8,
                    color: Colors.white60,
                    padding: const EdgeInsets.all(12.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        // ignore: prefer_const_literals_to_create_immutables
                        children: [
                          const Text(
                            'Para utilizar o app:',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const Text(
                            'Primeiro voc?? precisa permitir que o app acesse a sua localiza????o e com o GPS do seu celular ligado, registre a localiza????o do local de coleta no aplicativo.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const Text(
                            'Para centralizar o mapa na sua posi????o, toque o primeiro bot??o. Caso voc?? n??o tenha coletado no lugar onde est??, voc?? pode procurar o lugar no mapa e tocar em cima do local da coleta.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const Text(
                            'Para registrar a coleta toque no segundo bot??o, digite o n??mero do tubo e confirme a localiza????o do mapa. Para finalizar, toque no bot??o "Continuar" e aguarde a mensagem de confirma????o. Pronto! Sua coleta foi registrada.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          MaterialButton(
                            height: 60.0,
                            minWidth: 100.0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                side: BorderSide(
                                    color: _botaoInsidencia == 5
                                        ? Colors.green
                                        : Colors.white60)),
                            color: _botaoInsidencia == 5
                                ? Colors.greenAccent
                                : Colors.grey,
                            textColor: Colors.white,
                            child: const Text("Continuar"),
                            onPressed: () {
                              setState(() {
                                _tela3 = false;
                                _tela4 = true;
                              });
                            },
                            splashColor: Colors.redAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          //Tela4
          Visibility(
            visible: _tela4,
            child: Center(
              child: Container(
                width: maxW,
                height: maxH,
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    width: maxW * 0.8,
                    height: maxH * 0.8,
                    color: Colors.white60,
                    padding: const EdgeInsets.all(12.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        // ignore: prefer_const_literals_to_create_immutables
                        children: [
                          const Text(
                            'A fam??lia toda pode participar! Ent??o estimule seus familiares a tamb??m participar das coletas. S?? ?? necess??rio que todos os pernilongos sejam coletados no mesmo lugar.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const Text(
                            'Voc?? pode acompanhar as etapas da pesquisa e esclarecer suas d??vidas no Projeto Ci??ncia Cidad?? no Facebook!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                          GestureDetector(
                            child: const Text(
                                "(https://www.facebook.com/groups/422332278839039)",
                                style: TextStyle(
                                    fontSize: 16,
                                    decoration: TextDecoration.underline,
                                    color: Colors.blue)),
                            onTap: () async {
                              const url =
                                  'https://www.facebook.com/groups/422332278839039';
                              launchUrl(Uri.parse(url));
                            },
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          MaterialButton(
                            height: 60.0,
                            minWidth: 100.0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                side: BorderSide(
                                    color: _botaoInsidencia == 5
                                        ? Colors.green
                                        : Colors.white60)),
                            color: _botaoInsidencia == 5
                                ? Colors.greenAccent
                                : Colors.grey,
                            textColor: Colors.white,
                            child: const Text("Continuar"),
                            onPressed: () {
                              setState(() {
                                _tela3 = false;
                                _tela4 = false;
                              });
                            },
                            splashColor: Colors.redAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Visibility(
        visible: !_formVisible &&
            !_coletou &&
            !_tela1 &&
            !_tela2 &&
            !_tela3 &&
            !_tela4,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          FloatingActionButton(
            child: const Icon(Icons.gps_fixed),
            onPressed: () {
              //CS: Move a camera para o local do dispositivo
              mapController!.animateCamera(CameraUpdate.newLatLng(
                  LatLng(widget.latitude, widget.longitude)));

              //CS: Insere o marcardo no local do dispositivo
              _inserirMarcador(widget.latitude, widget.longitude);
            },
            heroTag: null,
          ),
          const SizedBox(
            height: 10,
            width: 10,
          ),
          FloatingActionButton(
            child: const Icon(Icons.check),
            onPressed: () {
              //GUARDA OS DADOS DA POSICAO E ZOOM ATUAL
              _gravaPosicao(_novaLatitude, _novaLongitude);
              setState(() {
                _formVisible = true;
              });
            },
            heroTag: null,
          ),
          const SizedBox(
            height: 10,
            width: 10,
          ),
          FloatingActionButton(
            child: const Icon(
              Icons.help,
              color: Colors.white,
              size: 55,
            ),
            onPressed: () {
              setState(() {
                _tela4 = false;
                _tela3 = false;
                _tela2 = false;
                _tela1 = true;
              });
            },
            heroTag: null,
          ),
          const SizedBox(
            height: 10,
            width: 10,
          ),
          FloatingActionButton(
            child: const Icon(
              Icons.map,
              color: Colors.white,
              size: 55,
            ),
            onPressed: () async {
              const url = 'https://geomosquito.ipe.eco.br/registros/mapa.php';
              launchUrl(Uri.parse(url));
            },
            heroTag: null,
          ),
        ]),
      ),
    );
  }
}
