#include "data.h"
#include "bitreader.h"
#include "cinefileheader.h"
#include "bitmapinfoheader.h"
#include "imageoffsets.h"
#include "cinereader.h"
#include "cineimage.h"
#include "setup.h"
#include <iostream>
#include <fstream>
#include <assert.h>
#include <stdlib.h>

using namespace std;

int main() {
  // Verify sizes of all datatypes in data.h
  BYTE m_byte;
  CHAR m_char;
  WORD m_word;
  INT16 m_int16;
  SHORT m_short;
  BOOL m_bool;
  DWORD m_dword;
  UINT m_uint;
  LONG m_long;
  INT m_int;
  FLOAT m_float;
  DOUBLE m_double;

  assert(sizeof(m_byte) == 1);
  assert(sizeof(m_char) == 1);

  assert(sizeof(m_word) == 2);
  assert(sizeof(m_int16) == 2);
  assert(sizeof(m_short) == 2);

  assert(sizeof(m_bool) == 4);
  assert(sizeof(m_dword) == 4);
  assert(sizeof(m_uint) == 4);
  assert(sizeof(m_int) == 4);
  assert(sizeof(m_long) == 4);
  assert(sizeof(m_float) == 4);

  assert(sizeof(m_double) == 8);


  //Test actual cine file
  ifstream inputCine("/mnt/Shield/ELEN4012 Videos/HS_Lightning_videos/20170210_163916_ng.cine", ios::in|ios::binary);
  CINEFILEHEADER cineheader(&inputCine);
  cout << cineheader;

  BITMAPINFOHEADER bitmapheader(&inputCine, cineheader);
  cout << bitmapheader;

  IMAGEOFFSETS pimage(&inputCine, cineheader);
  CINEIMAGE im(&inputCine, pimage.getPointer(1000), bitmapheader);

  SETUP  setup(&inputCine, cineheader);

  char* filename = "test.tif";
  cout << setup;
//    im.saveToTIFF(filename);
    cout << im.get16IM();
}
