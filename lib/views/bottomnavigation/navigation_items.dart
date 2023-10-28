import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:monami/views/home_view.dart';

class NavigatorItem {
  final String label;
  final IconData iconPath;
  final int index;
  final Widget screen;

  NavigatorItem(this.label, this.iconPath, this.index, this.screen);
}

List<NavigatorItem> navigatorItems = [
  // ignore: deprecated_member_use
  NavigatorItem("Home", FontAwesomeIcons.homeAlt, 0, const HomeView()),
  // ignore: deprecated_member_use
  NavigatorItem("Search", FontAwesomeIcons.search, 1, Container()),
  NavigatorItem("Message", FontAwesomeIcons.message, 2, Container()),
  NavigatorItem("Profile", FontAwesomeIcons.person, 3, Container()),
  NavigatorItem(
      "Settings",
      // ignore: deprecated_member_use
      FontAwesomeIcons.gripHorizontal,
      4,
      const HomeView()),
];
