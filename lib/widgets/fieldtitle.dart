import 'package:flutter/material.dart';

Widget fieldTitle(String title, double screenWidth) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: TextStyle(
        fontSize: screenWidth / 26,
        fontFamily: "Nexabold",
      ),
    ),
  );
}

Widget barTitle(String bar, double screenHeight, double screenWidth) {
  return Container(
    margin: EdgeInsets.only(
      top: screenHeight / 30,
      bottom: screenHeight / 40,
    ),
    child: Text(
      bar,
      style: TextStyle(
        fontSize: screenWidth / 18,
        fontFamily: "Nexabold",
      ),
    ),
  );
}
