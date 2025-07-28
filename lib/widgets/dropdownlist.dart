import 'package:flutter/material.dart';

Widget customDropdown(
  String hint,
  String value,
  List<String> items,
  double screenHeight,
  double screenWidth,
  IconData icon,
  ValueChanged<String?> onChanged,
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
          child: Icon(icon, color: Colors.black, size: screenWidth / 15),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: screenWidth / 12),
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                contentPadding: EdgeInsets.symmetric(
                  vertical: screenHeight / 35,
                ),
              ),
              items:
                  items
                      .map(
                        (role) =>
                            DropdownMenuItem(value: role, child: Text(role)),
                      )
                      .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    ),
  );
}
