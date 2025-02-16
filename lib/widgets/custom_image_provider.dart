import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:know_keeper/testing/test_configuration.dart';

ImageProvider customImageProvider(String imageUrl) {
  if (TestConfiguration.isTestMode) {
    return AssetImage('assets/testImages/$imageUrl');
  } else {
    return CachedNetworkImageProvider(imageUrl);
  }
}
