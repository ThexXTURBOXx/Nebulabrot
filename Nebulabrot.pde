import java.util.concurrent.atomic.AtomicIntegerArray;

static final int WIDTH = 1024;
static final int HEIGHT = 1024;
static final double MIN_X = -2.5;
static final double MIN_Y = -2;
static final double MAX_X = 1.5;
static final double MAX_Y = 2;
static final int MAX_ITERATIONS_R = 2000;
static final int MAX_ITERATIONS_G = 200;
static final int MAX_ITERATIONS_B = 20;
static final int MAX_ITERATIONS_MAX = max(MAX_ITERATIONS_R, MAX_ITERATIONS_G, MAX_ITERATIONS_B);
static final int MAX_ITERATIONS_DIV = 2000;
static final boolean ANTI_BUDDHABROT = false;
static final double MIN_X_CALC = -2.5;
static final double MIN_Y_CALC = -2;
static final double MAX_X_CALC = 1.5;
static final double MAX_Y_CALC = 2;
static final int WIDTH_CALC = 8186;
static final int HEIGHT_CALC = 8186;
static final String FILE_NAME = "nebulabrot.png";

volatile boolean finished = false;
AtomicIntegerArray counters_r;
AtomicIntegerArray counters_g;
AtomicIntegerArray counters_b;

void settings() {
  size(WIDTH, HEIGHT);
}

void setup() {
  counters_r = new AtomicIntegerArray(WIDTH * HEIGHT);
  counters_g = new AtomicIntegerArray(WIDTH * HEIGHT);
  counters_b = new AtomicIntegerArray(WIDTH * HEIGHT);
  thread("calculateAll");
}

void draw() {
  background(0);
  int max_r = max(counters_r);
  int max_g = max(counters_g);
  int max_b = max(counters_b);
  for (int y = 0; y < HEIGHT; y++) {
    for (int x = 0; x < WIDTH; x++) {
      int index = getIndex(x, y);
      set(x, y, color(
        (int) lerp(0, 255, colorFunction((double) counters_r.get(index) / max_r)),
        (int) lerp(0, 255, colorFunction((double) counters_g.get(index) / max_g)),
        (int) lerp(0, 255, colorFunction((double) counters_b.get(index) / max_b))));
    }
  }
  if (finished) {
    noLoop();
    save(FILE_NAME);
    println("Finished rendering");
  }
}

int getIndex(int x, int y) {
  return x + y * WIDTH;
}

int max(AtomicIntegerArray arr) {
  int max = Integer.MIN_VALUE;
  for (int i = 0; i < arr.length(); i++) {
    int val = arr.get(i);
    if (val > max) {
      max = val;
    }
  }
  return max;
}

void calculateAll() {
  for (int y = 0; y < HEIGHT_CALC; y++) {
    for (int x = 0; x < WIDTH_CALC; x++) {
      double currX = lerp(MIN_X_CALC, MAX_X_CALC, (double) x / WIDTH_CALC);
      double currY = lerp(MIN_Y_CALC, MAX_Y_CALC, (double) y / HEIGHT_CALC);
      if (ANTI_BUDDHABROT == isInMandelbrot(currX, currY)) {
        double prevA = 0;
        double prevB = 0;
        for (int iter = 0; iter <= MAX_ITERATIONS_MAX; iter++) {
          double newA = prevA * prevA - prevB * prevB + currX;
          double newB = 2 * prevA * prevB + currY;
          prevA = newA;
          prevB = newB;
          int index = getIndexOfComplex(prevA, prevB);
          if (index == -1) {
            continue;
          }
          if (iter < MAX_ITERATIONS_R) {
            counters_r.addAndGet(index, 1);
          }
          if (iter < MAX_ITERATIONS_G) {
            counters_g.addAndGet(index, 1);
          }
          if (iter < MAX_ITERATIONS_B) {
            counters_b.addAndGet(index, 1);
          }
        }
      }
    }
  }
  finished = true;
}

int getIndexOfComplex(double a, double b) {
  if (a < MIN_X || a > MAX_X || b < MIN_Y || b > MAX_Y || !Double.isFinite(a) || !Double.isFinite(b)) {
    return -1;
  }
  int x = round(lerp(0, WIDTH - 1, amt(MIN_X, MAX_X, a)));
  int y = round(lerp(0, HEIGHT - 1, amt(MIN_Y, MAX_Y, b)));
  if (x < 0 || x >= WIDTH || y < 0 || y >= HEIGHT) {
    return -1;
  }
  return x + y * WIDTH;
}

boolean isInMandelbrot(double a, double b) {
  double prevA = 0;
  double prevB = 0;
  for (int iter = 0; iter <= MAX_ITERATIONS_DIV; iter++) {
    // If square of magnitude > 4 -> definetly not in Mandelbrot set
    if (magSq(prevA, prevB) > 4) {
      return false;
    }
    double newA = prevA * prevA - prevB * prevB + a;
    double newB = 2 * prevA * prevB + b;
    prevA = newA;
    prevB = newB;
  }
  return true;
}

double lerp(double start, double stop, double amt) {
  if (amt <= 0) {
    return start;
  }
  if (amt >= 1) {
    return stop;
  }
  return start + (stop - start) * amt;
}

double amt(double start, double stop, double lerp) {
  return (lerp - start) / (stop - start);
}

double magSq(double a, double b) {
  return a * a + b * b;
}

int round(double n) {
  return (int) Math.round(n);
}

double colorFunctionOld(double a) {
  return 2.0 / (1.0 + 1.0 / a);
}

double colorFunction(double a) {
  return a;
}
