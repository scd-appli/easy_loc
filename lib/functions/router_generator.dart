import 'package:easy_loc/screens/camera_scan.dart';
import 'package:easy_loc/screens/history.dart';
import 'package:easy_loc/screens/home.dart';
import 'package:easy_loc/screens/settings.dart';
import 'package:flutter/material.dart';

enum From {right, left, top, bottom}

class RouteGenerator{
  Route? routeGenerate(RouteSettings settings){

    switch(settings.name){
      case '/':
        return _createSlideRoute(Home());
      case '/settings':
        return _createSlideRoute(Settings());
      case '/scan':
        return _createScaleRoute<String>(CameraScan());
      case '/history':
        return _createSlideRoute(History(), from: From.bottom);
    }

    return null;
  }

  Route _createSlideRoute<T>(Widget page, {From from = From.right}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        late Offset begin;
        switch(from){
          case From.right:
            begin = Offset(1.0,0.0);
            break;
          case From.left:
            begin = Offset(-1.0,0.0);
            break;
          case From.top:
            begin = Offset(0.0,-1.0);
            break;
          case From.bottom:
            begin = Offset(0.0,1.0);
            break;
        }

        const end = Offset.zero;
        const curve = Curves.ease;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  Route _createScaleRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOut;
        
        var scaleTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        
        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: child,
        );
      },
    );
  }
}