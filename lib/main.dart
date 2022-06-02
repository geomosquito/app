// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geom/displayMap.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'mosquitogeo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(
          title: 'MosquitoGeo',
        ));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _lat = 0.0, _long = 0.0, _zoom = 19.0;
  var scaffoldKey = GlobalKey<ScaffoldState>();
  late StreamSubscription<Position> positionStream;
  String status = 'Aguardando GPS';
  late Position positionLocation;

  _getPosicao() async {
    ph.PermissionStatus permission = await ph.Permission.location.request();
    var position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _lat = position.latitude;
      _long = position.longitude;
      _zoom = 19.0;
    });
  }

  @override
  void initState() {
    super.initState();
    _getPosicao();
  }

  @override
  Widget build(BuildContext context) {
    return DisplayMap(
      latitude: _lat,
      longitude: _long,
      zoom: _zoom,
    );
  }
}
