import 'package:flutter/material.dart';

class ButtonOptionWidget extends StatelessWidget {
  const ButtonOptionWidget({
    Key? key,
    required this.text,
    required this.onSelected,
  }) : super(key: key);

  final String text;
  final Function() onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: Colors.black.withAlpha(50),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blueAccent,
            Colors.greenAccent,
          ],
        ),
      ),
      height: 40,
      margin: const EdgeInsets.only(left: 20),
      child: TextButton(
        onPressed: onSelected,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
