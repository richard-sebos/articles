/*
 * Test robot forward and backward
 * - Uses EN pins HIGH (full speed)
 * - Runs forward, stops, then runs backward
 */

// ===== Rear-Right wheel =====
#define RR_IN1_PIN  17
#define RR_IN2_PIN  16
#define RR_EN_PIN    4
// ===== Left-Back wheel =====
#define LB_IN1_PIN  21
#define LB_IN2_PIN  22
#define LB_EN_PIN   23
// ===== Left-Front wheel =====
#define LF_IN1_PIN  25
#define LF_IN2_PIN  26
#define LF_EN_PIN   27
// ===== Right-Front wheel =====
#define RF_IN1_PIN  14
#define RF_IN2_PIN  13
#define RF_EN_PIN   33

// Run times
const unsigned long RUN_MS  = 3000;  // forward/backward duration
const unsigned long STOP_MS = 1500;  // pause between directions

// ---------- Helpers ----------
inline void setForward(int in1, int in2) { digitalWrite(in1, HIGH); digitalWrite(in2, LOW); }
inline void setBackward(int in1, int in2){ digitalWrite(in1, LOW);  digitalWrite(in2, HIGH); }
inline void enableAll() {
  digitalWrite(RR_EN_PIN, HIGH);
  digitalWrite(LB_EN_PIN, HIGH);
  digitalWrite(LF_EN_PIN, HIGH);
  digitalWrite(RF_EN_PIN, HIGH);
}
inline void disableAll() {
  digitalWrite(RR_EN_PIN, LOW);
  digitalWrite(LB_EN_PIN, LOW);
  digitalWrite(LF_EN_PIN, LOW);
  digitalWrite(RF_EN_PIN, LOW);
  // optional brake: all IN pins LOW
  digitalWrite(RR_IN1_PIN, LOW); digitalWrite(RR_IN2_PIN, LOW);
  digitalWrite(LB_IN1_PIN, LOW); digitalWrite(LB_IN2_PIN, LOW);
  digitalWrite(LF_IN1_PIN, LOW); digitalWrite(LF_IN2_PIN, LOW);
  digitalWrite(RF_IN1_PIN, LOW); digitalWrite(RF_IN2_PIN, LOW);
}

void setup() {
  Serial.begin(115200);

  // Setup pins
  pinMode(RR_IN1_PIN, OUTPUT); pinMode(RR_IN2_PIN, OUTPUT); pinMode(RR_EN_PIN, OUTPUT);
  pinMode(LB_IN1_PIN, OUTPUT); pinMode(LB_IN2_PIN, OUTPUT); pinMode(LB_EN_PIN, OUTPUT);
  pinMode(LF_IN1_PIN, OUTPUT); pinMode(LF_IN2_PIN, OUTPUT); pinMode(LF_EN_PIN, OUTPUT);
  pinMode(RF_IN1_PIN, OUTPUT); pinMode(RF_IN2_PIN, OUTPUT); pinMode(RF_EN_PIN, OUTPUT);

  disableAll();
}

void loop() {
  // ---------- Forward ----------
  Serial.println("Forward...");
  setForward(RR_IN1_PIN, RR_IN2_PIN);
  setForward(LB_IN1_PIN, LB_IN2_PIN);
  setForward(LF_IN1_PIN, LF_IN2_PIN);
  setForward(RF_IN1_PIN, RF_IN2_PIN);
  enableAll();
  delay(RUN_MS);

  // ---------- Stop ----------
  Serial.println("Stop...");
  disableAll();
  delay(STOP_MS);

  // ---------- Backward ----------
  Serial.println("Backward...");
  setBackward(RR_IN1_PIN, RR_IN2_PIN);
  setBackward(LB_IN1_PIN, LB_IN2_PIN);
  setBackward(LF_IN1_PIN, LF_IN2_PIN);
  setBackward(RF_IN1_PIN, RF_IN2_PIN);
  enableAll();
  delay(RUN_MS);

  // ---------- Stop ----------
  Serial.println("Stop...");
  disableAll();
  delay(STOP_MS);
}
