import 'package:flutter/material.dart';
import '../utils/royal_colors.dart';

class AstraLogo extends StatelessWidget {
  final double size;
  const AstraLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'A',
            style: TextStyle(
              fontSize: size * 0.85,
              fontWeight: FontWeight.w900,
              color: RoyalColors.darkPrimary, // Royal Blue
              height: 1.0,
              fontFamily: 'Inter',
            ),
          ),
          Positioned(
            top: size * 0.1,
            right: size * 0.1,
            child: Icon(
              Icons.star_rounded,
              size: size * 0.35,
              color: RoyalColors.darkAccent, // Gold
            ),
          ),
        ],
      ),
    );
  }
}
