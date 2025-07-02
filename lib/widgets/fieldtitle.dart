import 'package:flutter/material.dart';

Widget fieldTitle(
  String title, 
  double screenWidth,
) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: TextStyle(fontSize: screenWidth / 26, fontFamily: "NexaBold"),
    ),
  );
}

Widget barTitle(
  String bar, 
  double screenHeight, 
  double screenWidth,
) {
  return Container(
    margin: EdgeInsets.only(top: screenHeight / 30, bottom: screenHeight / 40),
    child: Text(
      bar,
      style: TextStyle(
        wordSpacing: 3,
        fontSize: screenWidth / 18,
        fontFamily: "NexaBold",
      ),
    ),
  );
}

Widget profileSectionTitle(
  String bar, 
  double screenHeight, 
  double screenWidth,
  double textSize,
) {
  return Container(
    margin: EdgeInsets.only(top: screenHeight / 30, bottom: screenHeight / 40),
    child: Text(
      bar,
      style: TextStyle(
        wordSpacing: 3,
        fontSize: textSize,
        fontFamily: "NexaBold",
      ),
    ),
  );
}

Widget buttonInText(
  String buttonText,
  double screenHeight,
  double screenWidth,
) {
  return Container(
    height: 50,
    width: screenWidth,
    margin: EdgeInsets.only(top: screenHeight / 40),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.all(const Radius.circular(30)),
    ),
    child: Center(
      child: Text(
        buttonText,
        style: TextStyle(
          fontSize: screenWidth / 26,
          color: Colors.white,
          fontFamily: "NexaBold",
          letterSpacing: 2,
        ),
      ),
    ),
  );
}

Widget initialButtonInText(
  String buttonText,
  double screenHeight,
  double screenWidth,
) {
  return Container(
    height: 50,
    width: 300,
    margin: EdgeInsets.only(top: screenHeight / 40),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.all(const Radius.circular(30)),
    ),
    child: Center(
      child: Text(
        buttonText,
        style: TextStyle(
          fontSize: screenWidth / 45,
          color: Colors.black,
          fontFamily: "NexaBold",
        ),
      ),
    ),
  );
}

Widget successButtonInText(
  String buttonText,
  double screenHeight,
  double screenWidth,
) {
  return Container(
    height: 50,
    width: screenWidth,
    margin: EdgeInsets.only(top: screenHeight / 40),
    decoration: BoxDecoration(
      color: Colors.green,
      borderRadius: BorderRadius.all(const Radius.circular(30)),
    ),
    child: Center(
      child: Text(
        buttonText,
        style: TextStyle(
          fontSize: screenWidth / 26,
          color: Colors.white,
          fontFamily: "NexaBold",
          letterSpacing: 2,
        ),
      ),
    ),
  );
}

Widget errorButtonInText(
  String buttonText,
  double screenHeight,
  double screenWidth,
) {
  return Container(
    height: 50,
    width: screenWidth,
    margin: EdgeInsets.only(top: screenHeight / 40),
    decoration: BoxDecoration(
      color: Colors.red,
      borderRadius: BorderRadius.all(const Radius.circular(30)),
    ),
    child: Center(
      child: Text(
        buttonText,
        style: TextStyle(
          fontSize: screenWidth / 26,
          color: Colors.white,
          fontFamily: "NexaBold",
          letterSpacing: 2,
        ),
      ),
    ),
  );
}

Widget leaveRequestButtonInText(
  String buttonText,
  double screenHeight,
  double screenWidth,
  double fontsize,
  Color color,
) {
  return Container(
    height: 50,
    width: screenWidth,
    margin: EdgeInsets.only(top: screenHeight / 40),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.all(const Radius.circular(30)),
    ),
    child: Center(
      child: Text(
        buttonText,
        style: TextStyle(
          fontSize: fontsize,
          color: Colors.white,
          fontFamily: "NexaBold",
          letterSpacing: 2,
        ),
      ),
    ),
  );
}