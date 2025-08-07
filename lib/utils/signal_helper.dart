int signalBars(int dBm) {
  if (dBm > -60) return 4;
  if (dBm > -70) return 3;
  if (dBm > -80) return 2;
  if (dBm > -90) return 1;
  return 0;
}
