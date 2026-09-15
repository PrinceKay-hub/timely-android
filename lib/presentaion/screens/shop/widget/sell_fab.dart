import 'package:booking/presentaion/screens/shop/sell_screen.dart';
import 'package:flutter/material.dart';

class SellFAB extends StatelessWidget {
  const SellFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SellScreen(),)),
        icon:  Icon(Icons.add, color: Theme.of(context).colorScheme.surface,),
        label:  Text('Sell',style: TextStyle(
          color: Theme.of(context).colorScheme.surface,
        ),),
      ),
    );
  }
}