#include <Arduino.h>
#include <Servo.h>
#include <string.h>
#include <stdlib.h>

/*
 * agent_phone_tool — serial servo hand (same wire protocol on ESP32 / STM32 / AVR).
 *
 * Commands (newline-terminated): R/RESET, PING, G/GET/ANGLES,
 *   SU:n SD:n SP:n SA:a,b,c RESTU:n RESTD:n RESTP:n PRESSU:n PRESSD:n PRESSP:n
 *
 * Pin map is set per board via build_flags (see platformio.ini).
 * STM32 Blue Pill: Vol+=A4(PA4) Vol-=A5(PA5) Power=A6(PA6).
 * FireBeetle 2 ESP32-S3: Vol+=A2 Vol-=A1 Power=A0（接线对调后）.
 */

#ifndef SERVO_PIN_VOLUP
#if defined(AGENT_PHONE_BOARD_STM32)
#define SERVO_PIN_VOLUP PA4
#define SERVO_PIN_VOLDOWN PA5
#define SERVO_PIN_POWER PA6
#else
#define SERVO_PIN_VOLUP 4
#define SERVO_PIN_VOLDOWN 5
#define SERVO_PIN_POWER 9
#endif
#endif

#ifndef SERVO_PIN_VOLDOWN
#define SERVO_PIN_VOLDOWN 5
#endif
#ifndef SERVO_PIN_POWER
#define SERVO_PIN_POWER 9
#endif

static const int PIN_VOL_UP = SERVO_PIN_VOLUP;
static const int PIN_VOL_DOWN = SERVO_PIN_VOLDOWN;
static const int PIN_POWER = SERVO_PIN_POWER;

static int restVolUp = 90;
static int restVolDown = 90;
static int restPower = 90;
// Host owns timing; board only stores REST/PRESS for G / calibration sync.
static int pressVolUp = 74;
static int pressVolDown = 114;
static int pressPower = 119;

static int angleVolUp = 90;
static int angleVolDown = 90;
static int anglePower = 90;

Servo servoVolUp;
Servo servoVolDown;
Servo servoPower;

static void quietPin(int pin) {
  pinMode(pin, OUTPUT);
  digitalWrite(pin, LOW);
}

static int clampAngle(int a) {
  if (a < 0) return 0;
  if (a > 180) return 180;
  return a;
}

static void applyAngles() {
  servoVolUp.write(angleVolUp);
  servoVolDown.write(angleVolDown);
  servoPower.write(anglePower);
}

static void setServo(char which, int angle) {
  angle = clampAngle(angle);
  if (which == 'U') angleVolUp = angle;
  else if (which == 'D') angleVolDown = angle;
  else if (which == 'P') anglePower = angle;
  applyAngles();
}

static void resetAllServos() {
  angleVolUp = restVolUp;
  angleVolDown = restVolDown;
  anglePower = restPower;
  applyAngles();
  delay(300);
  Serial.println(F("OK RESET"));
}

static void printAngles() {
  Serial.print(F("OK ANGLES U="));
  Serial.print(angleVolUp);
  Serial.print(F(" D="));
  Serial.print(angleVolDown);
  Serial.print(F(" P="));
  Serial.print(anglePower);
  Serial.print(F(" RESTU="));
  Serial.print(restVolUp);
  Serial.print(F(" RESTD="));
  Serial.print(restVolDown);
  Serial.print(F(" RESTP="));
  Serial.print(restPower);
  Serial.print(F(" PRESSU="));
  Serial.print(pressVolUp);
  Serial.print(F(" PRESSD="));
  Serial.print(pressVolDown);
  Serial.print(F(" PRESSP="));
  Serial.println(pressPower);
}

static bool parseSuffixInt(const char *line, const char *prefix, int *out) {
  size_t n = strlen(prefix);
  if (strncmp(line, prefix, n) != 0) return false;
  *out = clampAngle(atoi(line + n));
  return true;
}

static void handleLine(char *line) {
  for (char *p = line; *p; ++p) {
    if (*p >= 'a' && *p <= 'z') *p = *p - 'a' + 'A';
    if (*p == '\r' || *p == '\n') {
      *p = 0;
      break;
    }
  }
  if (line[0] == 0) return;

  int v = 0;

  if (!strcmp(line, "R") || !strcmp(line, "RESET")) {
    resetAllServos();
  } else if (!strcmp(line, "PING")) {
    Serial.println(F("OK PONG"));
  } else if (!strcmp(line, "G") || !strcmp(line, "GET") || !strcmp(line, "ANGLES")) {
    printAngles();
  } else if (parseSuffixInt(line, "SU:", &v) || parseSuffixInt(line, "S U:", &v)) {
    setServo('U', v);
    Serial.print(F("OK SU:"));
    Serial.println(angleVolUp);
  } else if (parseSuffixInt(line, "SD:", &v)) {
    setServo('D', v);
    Serial.print(F("OK SD:"));
    Serial.println(angleVolDown);
  } else if (parseSuffixInt(line, "SP:", &v)) {
    setServo('P', v);
    Serial.print(F("OK SP:"));
    Serial.println(anglePower);
  } else if (parseSuffixInt(line, "RESTU:", &v)) {
    restVolUp = v;
    Serial.print(F("OK RESTU:"));
    Serial.println(restVolUp);
  } else if (parseSuffixInt(line, "RESTD:", &v)) {
    restVolDown = v;
    Serial.print(F("OK RESTD:"));
    Serial.println(restVolDown);
  } else if (parseSuffixInt(line, "RESTP:", &v)) {
    restPower = v;
    Serial.print(F("OK RESTP:"));
    Serial.println(restPower);
  } else if (parseSuffixInt(line, "PRESSU:", &v)) {
    pressVolUp = v;
    Serial.print(F("OK PRESSU:"));
    Serial.println(pressVolUp);
  } else if (parseSuffixInt(line, "PRESSD:", &v)) {
    pressVolDown = v;
    Serial.print(F("OK PRESSD:"));
    Serial.println(pressVolDown);
  } else if (parseSuffixInt(line, "PRESSP:", &v)) {
    pressPower = v;
    Serial.print(F("OK PRESSP:"));
    Serial.println(pressPower);
  } else if (!strncmp(line, "SA:", 3)) {
    char *p = line + 3;
    int a = clampAngle(atoi(p));
    while (*p && *p != ',') p++;
    int b = (*p == ',') ? clampAngle(atoi(++p)) : a;
    while (*p && *p != ',') p++;
    int c = (*p == ',') ? clampAngle(atoi(++p)) : b;
    angleVolUp = a;
    angleVolDown = b;
    anglePower = c;
    applyAngles();
    Serial.print(F("OK SA:"));
    Serial.print(a);
    Serial.print(',');
    Serial.print(b);
    Serial.print(',');
    Serial.println(c);
  } else {
    Serial.print(F("ERR UNKNOWN "));
    Serial.println(line);
  }
}

void setup() {
  quietPin(PIN_VOL_UP);
  quietPin(PIN_VOL_DOWN);
  quietPin(PIN_POWER);

  Serial.begin(115200);
#if defined(ARDUINO_USB_CDC_ON_BOOT)
  delay(800);
#elif defined(AGENT_PHONE_BOARD_STM32)
  delay(400);
#endif

  servoVolUp.attach(PIN_VOL_UP);
  servoVolDown.attach(PIN_VOL_DOWN);
  servoPower.attach(PIN_POWER);

  angleVolUp = restVolUp;
  angleVolDown = restVolDown;
  anglePower = restPower;
  applyAngles();
  delay(400);

  Serial.println(F("READY agent_phone_tool"));
#if defined(AGENT_PHONE_BOARD_FIREBEETLE2)
  Serial.println(F("BOARD firebeetle2_esp32s3 silk A2=VOL+ A1=VOL- A0=POWER"));
  Serial.print(F("PINS VOL+=GPIO"));
  Serial.print(PIN_VOL_UP);
  Serial.print(F(" VOL-=GPIO"));
  Serial.print(PIN_VOL_DOWN);
  Serial.print(F(" POWER=GPIO"));
  Serial.println(PIN_POWER);
#elif defined(AGENT_PHONE_BOARD_STM32)
  Serial.println(F("BOARD stm32 A4=VOL+ A5=VOL- A6=POWER"));
  Serial.print(F("PINS VOL+=PA"));
  Serial.print(4);
  Serial.print(F(" VOL-=PA"));
  Serial.print(5);
  Serial.print(F(" POWER=PA"));
  Serial.println(6);
#else
  Serial.print(F("PINS VOL+=GPIO"));
  Serial.print(PIN_VOL_UP);
  Serial.print(F(" VOL-=GPIO"));
  Serial.print(PIN_VOL_DOWN);
  Serial.print(F(" POWER=GPIO"));
  Serial.println(PIN_POWER);
#endif
  Serial.println(F("CMDS: R G PING SU:n SD:n SP:n SA:a,b,c RESTU:n PRESSU:n ..."));
}

void loop() {
  static char buf[48];
  static uint8_t len = 0;

  while (Serial.available()) {
    char c = (char)Serial.read();
    if (c == '\n' || c == '\r') {
      if (len > 0) {
        buf[len] = 0;
        handleLine(buf);
        len = 0;
      }
    } else if (len < sizeof(buf) - 1) {
      buf[len++] = c;
    } else {
      len = 0;
    }
  }
}
