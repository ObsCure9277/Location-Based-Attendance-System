import 'package:flutter/material.dart';

Widget customField(
  String hint,
  TextEditingController controller,
  IconData fieldIcon,
  double screenHeight,
  double screenWidth,
) {
  return Container(
    width: screenWidth,
    margin: EdgeInsets.only(bottom: 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(12)),
      boxShadow: [
        BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(2, 2)),
      ],
    ),
    child: Row(
      children: [
        SizedBox(
          width: screenWidth / 6,
          child: Icon(fieldIcon, color: Colors.black, size: screenWidth / 15),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: screenWidth / 12),
            child: TextFormField(
              controller: controller,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  vertical: screenHeight / 35,
                ),
                border: InputBorder.none,
                hintText: hint,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget customPasswordField(
  String hint,
  TextEditingController controller,
  bool isObscure,
  IconData fieldIcon,
  VoidCallback onToggleVisibility,
  double screenHeight,
  double screenWidth,
) {
  return Container(
    width: screenWidth,
    margin: EdgeInsets.only(bottom: 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(12)),
      boxShadow: [
        BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(2, 2)),
      ],
    ),
    child: Row(
      children: [
        SizedBox(
          width: screenWidth / 6,
          child: Icon(fieldIcon, color: Colors.black, size: screenWidth / 15),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: screenWidth / 12),
            child: TextFormField(
              controller: controller,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  vertical: screenHeight / 35,
                ),
                border: InputBorder.none,
                hintText: hint,
                suffixIcon: IconButton(
                  icon: Icon(
                    isObscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: onToggleVisibility,
                ),
              ),
              maxLines: 1,
              obscureText: isObscure,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget editableCustomField(
  String hint,
  TextEditingController controller,
  IconData fieldIcon,
  double screenHeight,
  double screenWidth,
  {required bool readOnly}
) 
{
  return Container(
    width: screenWidth,
    margin: EdgeInsets.only(bottom: 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(12)),
      boxShadow: [
        BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(2, 2)),
      ],
    ),
    child: Row(
      children: [
        SizedBox(
          width: screenWidth / 6,
          child: Icon(fieldIcon, color: Colors.black, size: screenWidth / 15),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: screenWidth / 12),
            child: TextFormField(
              controller: controller,
              enableSuggestions: false,
              autocorrect: false,
              readOnly: readOnly,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  vertical: screenHeight / 35,
                ),
                border: InputBorder.none,
                hintText: hint,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ],
    ),
  );
}