#include <Wire.h>
#include <Adafruit_PN532.h>
#include <WiFiNINA.h>
#include <ArduinoHttpClient.h>
#include <ArduinoJson.h>
#include <base64.hpp>

#include "secret.h"

#define PN532_IRQ           12
#define PN532_RESET         11

Adafruit_PN532 nfc(PN532_IRQ, PN532_RESET);

#define LED_GREEN           13
#define LED_RED             14

WiFiClient wifiClient;
HttpClient httpClient(wifiClient, API_ADDRESS, API_PORT);

void setup() {
  // put your setup code here, to run once:
  pinMode(LED_GREEN, OUTPUT); pinMode(LED_RED, OUTPUT);
  
  Serial.begin(115200); while (!Serial) {
    digitalWrite(LED_GREEN, HIGH); digitalWrite(LED_RED, HIGH);
    delay(50);
    digitalWrite(LED_GREEN, LOW); digitalWrite(LED_RED, LOW);
    delay(50);
  }

  Serial.println("Smart card ticket vending/lookup");

  digitalWrite(LED_RED, HIGH);

  Serial.print("Initialising PN532...");
  nfc.begin();
  uint32_t nfcVersion = nfc.getFirmwareVersion();
  if (!nfcVersion) {
    Serial.println("failed.");
    while (1);
  }
  Serial.print("done (PN5");
  Serial.print((nfcVersion >> 24) & 0xFF, HEX);
  Serial.print(" V");
  Serial.print((nfcVersion >> 16) & 0xFF, DEC); Serial.print('.'); Serial.print((nfcVersion >> 8) & 0xFF, DEC);
  Serial.println(").");

  Serial.print("Connecting to WiFi SSID "WIFI_SSID"...");
  do {
    int ret = WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    if (ret == WL_CONNECTED) {
      Serial.println("done.");
      break;
    } else {
      Serial.print('(');
      Serial.print(ret);
      Serial.print(')');
      delay(5000);
    }
  } while (1);
  digitalWrite(LED_GREEN, HIGH);

  Serial.print("Checking validation API connection...");
  do {
    do {
      int ret = httpClient.get(API_ONLINE_BASE "/healthcheck");
      if (ret != 0) {
        Serial.print('(');
        Serial.print(ret);
        Serial.print(')');
        delay(1000);
      } else break;
    } while (1);

    int status = httpClient.responseStatusCode();
    if (status != 200 && status != 299) {
      httpClient.stop();
      Serial.print('[');
      Serial.print(status);
      Serial.print(']');
      delay(1000);
      continue;
    }
    
    Serial.print("done, content length = ");
    Serial.print(httpClient.contentLength());
    Serial.println('.');

    httpClient.stop();
    break;
  } while (1);

  // digitalWrite(LED_RED, LOW); digitalWrite(LED_GREEN, LOW);
}

int getInteger() {
  while (!Serial.available());
  int val = Serial.parseInt();
  while (Serial.available()) {
    Serial.read();
    delayMicroseconds(10);
  }
  return val;
}

int getChoice(int min, int max) {
  int ret;
  do {
    Serial.print("Please enter your choice: ");
    ret = getInteger();
    Serial.println(ret);
  } while (ret < min || ret > max);
  return ret;
}

uint32_t waitForCard(uint8_t* uidOut = NULL) {
  Serial.println("Please bring the card towards the reader...");
  while (1) {
    uint8_t uid[7]; uint8_t uidLen;
    int success = nfc.readPassiveTargetID(PN532_MIFARE_ISO14443A, uid, &uidLen);
    if (success) {
      Serial.print("Found card with UID "); nfc.PrintHex(uid, uidLen); Serial.print(" ("); Serial.print(uidLen, DEC); Serial.println(" bytes)");
      if (uidLen != 4) Serial.println(" > Card is NOT Mifare Classic, please try again with another card.");
      else {
        if (uidOut) memcpy(uidOut, uid, 4);
        return ((uint32_t)uid[0] << 24) | ((uint32_t)uid[1] << 16) | ((uint32_t)uid[2] << 8) | ((uint32_t)uid[3] << 0);
      }
    } else Serial.println("Reading failed, please try again.");
  }
}

void convertUUID(const char* uuid, uint8_t* out) {
  uint32_t out32[16];
  sscanf(
      uuid, "%2x%2x%2x%2x-%2x%2x-%2x%2x-%2x%2x-%2x%2x%2x%2x%2x%2x",
      &out32[0], &out32[1], &out32[2], &out32[3],   
      &out32[4], &out32[5],
      &out32[6], &out32[7],
      &out32[8], &out32[9],
      &out32[10], &out32[11], &out32[12], &out32[13], &out32[14], &out32[15]
  );
  for (int i = 0; i < 16; i++) out[i] = out32[i];
}

void getCardID(uint32_t uid, char* output, uint8_t outputLen) {
  // snprintf(output, outputLen, "%08x-0000-0000-0000-0123456789ab", uid);
  snprintf(output, outputLen, "%08x", uid);
}

void getCardUUID(uint32_t uid, char* output, uint8_t outputLen) {
  snprintf(output, outputLen, "%08x-0000-0000-0000-0123456789ab", uid);
}

#define SECTOR_BLOCKS             4
#define SECTOR(block)             ((block) / SECTOR_BLOCKS)
#define TRAILER_BLOCK(sector)     (((sector) + 1) * SECTOR_BLOCKS - 1)

uint8_t ACCESS_KEY[6] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

bool authenticateSector(uint32_t uid, int sector) {
  uint8_t uidBuf[4] = {
    (uid >> 24) & 0xFF,
    (uid >> 16) & 0xFF,
    (uid >> 8) & 0xFF,
    (uid >> 0) & 0xFF
  };

  if (!nfc.mifareclassic_AuthenticateBlock(uidBuf, 4, sector * SECTOR_BLOCKS, 1, ACCESS_KEY)) {
    Serial.print("Authentication failed for sector "); Serial.println(sector);
    return false;
  } else {
    Serial.print("Sector "); Serial.print(sector); Serial.println(" authentication completed");
    return true;
  }
}

/* sector data structures */
struct card_sect0 {
  uint8_t fareType;
  uint8_t touchedOn;
  uint16_t dailyExpenditure;
  uint8_t currentProduct;
  uint8_t transTop;
  uint16_t prodDuration;
  uint64_t cardExpiry;
  uint32_t balance;
  uint32_t reserved;
  uint64_t prodValidated;
} __attribute__((packed));

struct card_sect1 {
  uint8_t bitmap0[16];
  uint8_t bitmap1[16];
} __attribute__((packed));

struct card_sect2 {
  uint8_t p1ID[16];
  uint8_t p2ID[16];
  uint8_t p1Product;
  uint64_t p1Expiry : 56;
  uint8_t p2Product;
  uint64_t p2Expiry : 56;
} __attribute__((packed));

struct card_trans_sect {
  uint8_t id[16];
  uint64_t timestamp;
  uint32_t location : 24;
  uint8_t type;
  uint32_t balance;
} __attribute__((packed));

#define COOLDOWN 2000

void loop() {
  digitalWrite(LED_RED, LOW); digitalWrite(LED_GREEN, LOW);
  Serial.println("Tap your card to validate");

  uint32_t uid = waitForCard();

  uint8_t sectbuf[16 * 3];
  if (!authenticateSector(uid, 0)) return;
  struct card_sect0* sect0 = (struct card_sect0*) sectbuf;
  if (!nfc.mifareclassic_ReadDataBlock(1, sectbuf)/* || !nfc.mifareclassic_ReadDataBlock(2, &sectbuf[16])*/) {
    Serial.println("Cannot read sector 0");
    return;
  }
  if (sect0->fareType & (1 << 7)) {
    Serial.println("Card has been disabled");
    digitalWrite(LED_RED, HIGH);
    delay(COOLDOWN);
    return;
  }

  digitalWrite(LED_RED, HIGH); digitalWrite(LED_GREEN, HIGH);

  char uuid[37]; getCardUUID(uid, uuid, sizeof(uuid));
  String postData =
    "{\"location\":" LOCATION_ID ",\"card\":{\"type\":\"sc\",\"id\":\"" + String(uuid) + "\",\"skipValidation\":true}}"; // TODO: card validation
  Serial.print("Validating ticket...");
  httpClient.beginRequest();
  httpClient.post(API_ONLINE_BASE "/validate");
  httpClient.sendHeader("Content-Type", "application/json");
  httpClient.sendHeader("Content-Length", postData.length());
  httpClient.beginBody();
  httpClient.print(postData);
  httpClient.endRequest();

  int statusCode = httpClient.responseStatusCode();
  if (statusCode == 200) {
    digitalWrite(LED_RED, LOW);
    Serial.print("SUCCESS: ");
  } else {
    digitalWrite(LED_GREEN, LOW);
    Serial.print("FAILED ("); Serial.print(statusCode); Serial.print(") : ");
  }

  String responseStr = httpClient.responseBody();
  JsonDocument response; deserializeJson(response, responseStr);
  Serial.println(response["message"]["text"].as<const char*>());

  Serial.print("Request body    : "); Serial.println(postData);
  Serial.print("Response string : "); Serial.println(responseStr);

done:
  delay(COOLDOWN); // cooldown
}
