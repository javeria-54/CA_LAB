int main() {
    volatile int a = 5;    // volatile prevents optimization
    volatile int b = 10;
    volatile int c = a + b;      // c = 15
    volatile int d = c - a;      // d = 10
    volatile int e = 0;          // e = d * b (10 * 10 = 100)
    volatile int f = 0;          // f = e / a (100 / 5 = 20)

    // Multiply d * b using a loop
    for (int i = 0; i < b; i++) {
        e += d;
    }

    // Divide e / a using a loop
    while (e >= a) {
        e -= a;
        f++;
    }

    // Return result to prevent optimization
    return f;  // Should return 20
}