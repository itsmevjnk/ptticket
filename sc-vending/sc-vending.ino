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

  // Serial.print("Checking database API connection...");
  // do {
  //   do {
  //     int ret = httpClient.get(API_DB_BASE "/healthcheck");
  //     if (ret != 0) {
  //       Serial.print('(');
  //       Serial.print(ret);
  //       Serial.print(')');
  //       delay(1000);
  //     } else break;
  //   } while (1);

  //   int status = httpClient.responseStatusCode();
  //   if (status != 200) {
  //     Serial.print('[');
  //     Serial.print(status);
  //     Serial.print(']');
  //     delay(1000);
  //     continue;
  //   }
    
  //   Serial.print("done, content length = ");
  //   Serial.print(httpClient.contentLength());
  //   Serial.println('.');

  //   httpClient.stop();
  //   break;
  // } while (1);

  Serial.print("Checking vending API connection...");
  do {
    do {
      int ret = httpClient.get(API_VENDING_BASE "/healthcheck");
      if (ret != 0) {
        Serial.print('(');
        Serial.print(ret);
        Serial.print(')');
        delay(1000);
      } else break;
    } while (1);

    int status = httpClient.responseStatusCode();
    if (status != 200) {
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

  digitalWrite(LED_RED, LOW); digitalWrite(LED_GREEN, LOW);
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

void doPurchaseCard() {
  Serial.println("Select the fare type:");
  Serial.println("1. Full fare");
  Serial.println("2. Concession");
  Serial.println("3. Child");
  Serial.println("4. Carers");
  Serial.println("5. Disability Support Pension");
  Serial.println("6. Seniors");
  Serial.println("7. War Veterans/Widow(er)s");
  int fareType = getChoice(1, 7) - 1;
  
  int balance;
  do {
    Serial.print("Enter the card's initial balance (in cents): ");
    balance = getInteger();
    Serial.println(balance);
  } while (balance < 0);

  int passProduct;
  do {
    Serial.print("Enter the card's prepaid pass product ID (0 for none): ");
    passProduct = getInteger();
    Serial.println(passProduct);
  } while (passProduct < 0);
  int passDuration = 0;
  if (passProduct) {
    do {
      Serial.print("Enter the card's prepaid pass duration (from 7 to 365): ");
      passDuration = getInteger();
      Serial.println(passDuration);
    } while (passDuration < 7 || passDuration > 365);
  }

  uint32_t uid = waitForCard(); // get card UID

  char path[100] = API_VENDING_BASE "/purchase/";
  int len = strlen(path); getCardID(uid, &path[len], sizeof(path) - len);
  String postData = "{\"fareType\":" + String(fareType);
  if (balance > 0) postData += ",\"topUp\":true,\"balance\":" + String(balance); else postData += ",\"topUp\":false";
  if (passProduct > 0) postData += ",\"pass\":true,\"passProduct\":" + String(passProduct) + ",\"passDuration\":" + String(passDuration); else postData += ",\"pass\":false";
  postData += "}";
  Serial.print("Creating ticket...");
  httpClient.beginRequest();
  httpClient.post(path);
  httpClient.sendHeader("Content-Type", "application/json");
  httpClient.sendHeader("Content-Length", postData.length());
  httpClient.beginBody();
  httpClient.print(postData);
  httpClient.endRequest();  

  int statusCode = httpClient.responseStatusCode();
  String responseStr = httpClient.responseBody();

  Serial.println(statusCode);
  Serial.print("Response body: "); Serial.println(responseStr);

  if (statusCode != 200) return;

  JsonDocument response; deserializeJson(response, responseStr);

write:
  uid = waitForCard(); // get card UID
  
  uint8_t sectbuf[16 * 3];

  /* sector 3-4 */
  uint8_t transactions = 0;
  uint8_t passID[16];
  JsonArray transArr = response["message"].as<JsonArray>();
  for (JsonVariant trans : transArr) {
    const char* id = trans["id"].as<const char*>();
    Serial.print("Writing transaction "); Serial.print(id); Serial.print(" as transaction "); Serial.print(transactions); Serial.println("...");
    struct card_trans_sect* sect = (struct card_trans_sect*) sectbuf; memset(sect, 0, sizeof(struct card_trans_sect));
    convertUUID(id, sect->id);
    sect->timestamp = trans["timestamp"];
    sect->balance = trans["balance"];
    sect->type = trans["type"];

    int sectNum = 3 + transactions;
    if (!authenticateSector(uid, sectNum)) goto write;
    if (!nfc.mifareclassic_WriteDataBlock(sectNum * SECTOR_BLOCKS, sectbuf) || !nfc.mifareclassic_WriteDataBlock(sectNum * SECTOR_BLOCKS + 1, &sectbuf[16])) {
      Serial.print("Cannot write sector "); Serial.println(sectNum);
      goto write;
    }

    if (sect->type == 5) memcpy(passID, sect->id, 16); // copy pass ID
    transactions++;
  }

  /* remaining sectors up to 15 */
  memset(sectbuf, 0, 16); // clear transaction ID
  for (int sector = 3 + transactions; sector < 16; sector++) {
    if (!authenticateSector(uid, sector)) goto write;
    if (!nfc.mifareclassic_WriteDataBlock(sector * SECTOR_BLOCKS, sectbuf)) {
      Serial.print("Cannot write sector "); Serial.println(sector);
      goto write;
    }
  }

  /* sector 1 */
  if (!authenticateSector(uid, 1)) goto write;
  struct card_sect1* sect1 = (struct card_sect1*) sectbuf; memset(sect1, 0, sizeof(struct card_sect1));

  if (!nfc.mifareclassic_WriteDataBlock(4, sectbuf) || !nfc.mifareclassic_WriteDataBlock(5, &sectbuf[16])) {
    Serial.println("Cannot write sector 1");
    goto write;
  }

  /* sector 2 */
  if (!authenticateSector(uid, 2)) goto write;
  struct card_sect2* sect2 = (struct card_sect2*) sectbuf; memset(sect2, 0, sizeof(struct card_sect2));

  if (passProduct) {
    memcpy(sect2->p1ID, passID, 16);
    sect2->p1Product = passProduct;
    sect2->p1Expiry = passDuration;
  }

  if (!nfc.mifareclassic_WriteDataBlock(8, sectbuf) || !nfc.mifareclassic_WriteDataBlock(9, &sectbuf[16]) || !nfc.mifareclassic_WriteDataBlock(10, &sectbuf[32])) {
    Serial.println("Cannot write sector 2");
    goto write;
  }
  
  /* sector 0 */
  if (!authenticateSector(uid, 0)) goto write;
  struct card_sect0* sect0 = (struct card_sect0*) sectbuf; memset(sect0, 0, sizeof(struct card_sect0));
  sect0->balance = balance;
  sect0->fareType = fareType;
  sect0->cardExpiry = -1;
  sect0->transTop = transactions;

  if (!nfc.mifareclassic_WriteDataBlock(1, sectbuf) || !nfc.mifareclassic_WriteDataBlock(2, &sectbuf[16])) {
    Serial.println("Cannot write sector 0");
    goto write;
  }
}

void hexdump(const uint8_t* buf, size_t len, bool printAddr = true) {
  char linebuf[4 + 2 + 16 * 3 + 1]; linebuf[0] = '\0';
  for (uint8_t base = 0; base < len; base += 16) {
    int strIdx = 0;
    if (printAddr) strIdx = sprintf(linebuf, "%04x: ", base);
    for (uint8_t i = 0; i < 16 && base + i < len; i++) {
      strIdx += sprintf(&linebuf[strIdx], "%02x ", buf[base + i]);
    }
    Serial.println(linebuf);
  }
}

bool isZero(const uint8_t* buf, size_t len) {
  uint8_t zeroCheck = 0; for (int i = 0; i < len; i++) zeroCheck |= buf[i];
  return (!zeroCheck);
}

void printCurrency(int n) {
  char buf[15];
  sprintf(buf, "$%d.%02u", n / 100, n % 100);
  Serial.println(buf);
}

void doCheckCard() {
  uint32_t uid = waitForCard(); // get card UID

  uint8_t sectbuf[16 * 3];

  /* sector 0 */
  Serial.println("Sector 0:");
  if (!authenticateSector(uid, 0)) return;
  struct card_sect0* sect0 = (struct card_sect0*) sectbuf;
  if (!nfc.mifareclassic_ReadDataBlock(1, sectbuf) || !nfc.mifareclassic_ReadDataBlock(2, &sectbuf[16])) {
    Serial.println("Cannot read sector 0");
    return;
  }
  int transTop = sect0->transTop;
  Serial.print("Fare type               :  "); Serial.println(sect0->fareType);
  Serial.print("Touched on              :  "); Serial.println(sect0->touchedOn);
  Serial.print("Daily expenditure       : ");  printCurrency(sect0->dailyExpenditure);
  Serial.print("Current product         :  "); Serial.println(sect0->currentProduct);
  Serial.print("Product duration        :  "); Serial.print(sect0->prodDuration); Serial.println(" min");
  Serial.print("Card expiry time        :  "); Serial.println(sect0->cardExpiry);
  Serial.print("Balance                 : "); printCurrency(sect0->balance);
  Serial.print("Product validation time :  "); Serial.println(sect0->prodValidated);
  Serial.println("Raw data:");
  hexdump(sectbuf, sizeof(struct card_sect0));
  Serial.println();

  Serial.println("Sector 1:");
  if (!authenticateSector(uid, 1)) return;
  struct card_sect1* sect1 = (struct card_sect1*) sectbuf;
  if (!nfc.mifareclassic_ReadDataBlock(4, sectbuf) || !nfc.mifareclassic_ReadDataBlock(5, &sectbuf[16])) {
    Serial.println("Cannot read sector 1");
    return;
  }
  Serial.print("2-hour products bitmap  :  "); hexdump(sectbuf, 16, false);
  Serial.print("Daily products bitmap   :  "); hexdump(&sectbuf[16], 16, false);
  Serial.println("Raw data:");
  hexdump(sectbuf, sizeof(struct card_sect1));
  Serial.println();

  Serial.println("Sector 2:");
  if (!authenticateSector(uid, 2)) return;
  struct card_sect2* sect2 = (struct card_sect2*) sectbuf;
  if (!nfc.mifareclassic_ReadDataBlock(8, sectbuf) || !nfc.mifareclassic_ReadDataBlock(9, &sectbuf[16]) || !nfc.mifareclassic_ReadDataBlock(10, &sectbuf[32])) {
    Serial.println("Cannot read sector 2");
    return;
  }
  Serial.print("Pass #1 ID              :  "); 
  if (isZero(sect2->p1ID, 16)) Serial.println("N/A");
  else {
    hexdump(sect2->p1ID, 16, false);
    Serial.print("Pass #1 product         :  "); Serial.println(sect2->p1Product);
    Serial.print("Pass #1 expiry/duration :  "); Serial.println(sect2->p1Expiry);
  }
  Serial.print("Pass #2 ID              :  ");
  if (isZero(sect2->p2ID, 16)) Serial.println("N/A");
  else {
    hexdump(sect2->p2ID, 16, false);
    Serial.print("Pass #2 product         :  "); Serial.println(sect2->p2Product);
    Serial.print("Pass #2 expiry/duration :  "); Serial.println(sect2->p2Expiry);
  }
  Serial.println("Raw data:");
  hexdump(sectbuf, sizeof(struct card_sect2));
  Serial.println();

  struct card_trans_sect* sect = (struct card_trans_sect*) sectbuf;
  for (int i = 0; i < 15 - 3 + 1; i++) {
    int sector = transTop - 1 - i; while (sector < 0) sector += 15 - 3 + 1;
    sector += 3; // sector offset
    Serial.print("Transaction "); Serial.print(i); Serial.print(" @ sector "); Serial.print(sector); Serial.println(':');
    if (!authenticateSector(uid, sector)) return;
    if (
      !nfc.mifareclassic_ReadDataBlock(sector * SECTOR_BLOCKS, sectbuf)
      || !nfc.mifareclassic_ReadDataBlock(sector * SECTOR_BLOCKS + 1, &sectbuf[16])
    ) {
      Serial.print("Cannot read sector "); Serial.println(sector);
      return;
    }

    if (isZero(sect->id, 16)) {
      Serial.println("End of transaction list\r\n");
      break;
    }

    Serial.print("Transaction ID          :  "); hexdump(sect->id, 16, false);
    Serial.print("Timestamp               :  "); Serial.println(sect->timestamp);
    Serial.print("Location                :  "); Serial.println(sect->location);
    Serial.print("Type                    :  "); Serial.println(sect->type);
    Serial.print("Balance after trans.    : "); printCurrency(sect->balance);
    Serial.println("Raw data:");
    hexdump(sectbuf, sizeof(struct card_trans_sect));
    Serial.println();
  }
}

void doTopUpBalance() {
  uint32_t uid = waitForCard(); // get card UID
  
  uint8_t sectbuf[16 * 3];

  /* read sector 0 to get next transaction slot */
  if (!authenticateSector(uid, 0)) return;
  struct card_sect0* sect0 = (struct card_sect0*) sectbuf;
  if (!nfc.mifareclassic_ReadDataBlock(1, sectbuf) || !nfc.mifareclassic_ReadDataBlock(2, &sectbuf[16])) {
    Serial.println("Cannot read sector 0");
    return;
  }
  int sector = sect0->transTop + 3;
  sect0->transTop++; if (sect0->transTop == 15 - 3 + 1) sect0->transTop = 0; // increment transaction top

  Serial.print("Current balance: "); printCurrency(sect0->balance);

  int amount;
  do {
    Serial.print("Enter the amount to add to the card (in cents): ");
    amount = getInteger();
    Serial.println(amount);
  } while (amount <= 0);

  char path[100] = API_VENDING_BASE "/balance/";
  int len = strlen(path); getCardID(uid, &path[len], sizeof(path) - len);
  String postData = "{\"amount\":" + String(amount) + "}";
  Serial.print("Topping up...");
  httpClient.beginRequest();
  httpClient.post(path);
  httpClient.sendHeader("Content-Type", "application/json");
  httpClient.sendHeader("Content-Length", postData.length());
  httpClient.beginBody();
  httpClient.print(postData);
  httpClient.endRequest();  

  int statusCode = httpClient.responseStatusCode();
  String responseStr = httpClient.responseBody();

  Serial.println(statusCode);
  Serial.print("Response body: "); Serial.println(responseStr);

  if (statusCode != 200) return;

  JsonDocument response; deserializeJson(response, responseStr);

write:
  uid = waitForCard(); // get card UID

  /* write back */
  sect0->balance = response["message"]["balance"];
  if (!authenticateSector(uid, 0)) goto write;
  if (!nfc.mifareclassic_WriteDataBlock(1, sectbuf) || !nfc.mifareclassic_WriteDataBlock(2, &sectbuf[16])) {
    Serial.println("Cannot write sector 0");
    goto write;
  }

  /* write transaction */
  uint8_t transactions = 0;
  struct card_trans_sect* sect = (struct card_trans_sect*) sectbuf; memset(sect, 0, sizeof(struct card_trans_sect));
  convertUUID(response["message"]["id"].as<const char*>(), sect->id);
  sect->timestamp = response["message"]["timestamp"];
  sect->balance = response["message"]["balance"];
  sect->location = response["message"]["location"];
  sect->type = response["message"]["type"];
  if (!authenticateSector(uid, sector)) goto write;
  if (!nfc.mifareclassic_WriteDataBlock(sector * SECTOR_BLOCKS, sectbuf) || !nfc.mifareclassic_WriteDataBlock(sector * SECTOR_BLOCKS + 1, &sectbuf[16])) {
    Serial.print("Cannot write sector "); Serial.println(sector);
    goto write;
  }
}

void loop() {
  Serial.println("Please select an option from below:");
  Serial.println("1. Purchase new card");
  Serial.println("2. Check card");
  Serial.println("3. Top up balance");
  // Serial.println("4. Top up pass");
  switch (getChoice(1, 4)) {
    case 1: doPurchaseCard(); break;
    case 2: doCheckCard(); break;
    case 3: doTopUpBalance(); break;
    // case 4: doTopUpPass(); break;
  }
}
