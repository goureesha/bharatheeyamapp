void main() {
  // Test tara calculation for janma nakshatra = 0 (Ashwini)
  int janma = 0;
  print('Janma Nakshatra: $janma (Ashwini)');
  print('---');
  for (int j = 0; j < 27; j++) {
    int t = (j - janma + 27) % 27 % 9;
    bool g = (t == 1 || t == 3 || t == 5 || t == 7 || t == 8);
    print('Nak $j: Tara=$t ${g ? "GOOD" : "BAD"}');
  }
}
