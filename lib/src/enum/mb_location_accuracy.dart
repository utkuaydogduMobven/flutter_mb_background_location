enum MBLocationAccuracy {
  best,
  bestForNavigation,
  nearestTenMeters,
  nearestHundredMeters,
  nearestKilometer,
  nearestThreeKilometers,
  reduced,
}

extension MbLocationAccuracyExt on MBLocationAccuracy {
  int get value {
    switch (this) {
      case MBLocationAccuracy.best:
        return 0;
      case MBLocationAccuracy.bestForNavigation:
        return 1;
      case MBLocationAccuracy.nearestTenMeters:
        return 2;
      case MBLocationAccuracy.nearestHundredMeters:
        return 3;
      case MBLocationAccuracy.nearestKilometer:
        return 4;
      case MBLocationAccuracy.nearestThreeKilometers:
        return 5;
      case MBLocationAccuracy.reduced:
        return 6;
      default:
        return 0;
    }
  }
}
