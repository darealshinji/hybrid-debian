#include <QList>
#include <QHash>
#include <QFile>
#include <bitset>
#include <QObject>
#include <iostream>
using namespace std;

void adjustGOPSize(int count, int &lastIDRPosition, int &maxGOPsize)
{
  if ((count - lastIDRPosition) > maxGOPsize) {
    maxGOPsize = count - lastIDRPosition;
    lastIDRPosition = count;
  }
}

void checkMPEG2FrameType(const int idx, const int basePatternSize, const int yIndex,
    const QByteArray &buffer, double &count)
{
  // get 1st byte after base pattern
  bitset<8> x(buffer[idx + basePatternSize]);
  if (!x[7]) { // check >= 0x80 <> Picture_Coding_Extension // 459
    return;
  }
  bitset<8> bits(buffer[yIndex]); // decide field type:  get third byte after base pattern and convert byte to bit array
  if (bits[1]) { // ends with 1X
    if (bits[0]) { // ends with 11
      count += 1; // whole frame
    } else { // endsWith 10
      count += 0.5; // 10 bottom field
    }
    // ends with 0X
  } else if (bits[0]) { // ends with 01
    count += 0.5; // top field
  }
}

int framecountOfRawMPEG2(const QString &fileName, const bool noprogress)
{
  QFile file(fileName);
  if (!file.open(QIODevice::ReadOnly)) {
    cerr << "Couldn't open " << qPrintable(fileName) << " for frame parsing." << endl;
    return 0;
  }
  // create base pattern
  QByteArray basePattern;
  basePattern.resize(4); //start code + extension
  basePattern[0] = (char) 0x00;
  basePattern[1] = (char) 0x00;
  basePattern[2] = (char) 0x01;
  basePattern[3] = (char) 0xB5;
  int basePatternSize = basePattern.size();
  int patternSize = basePatternSize + 2;  // +2, because three bytes after pattern are interesting

  double count = 0;
  int idx, yIndex, datasize;
  int filePosition = 1;
  const int mb = 20;
  int readSize = 1 << 20; // 1 MB
  double size = file.size() / double(readSize);
  QByteArray buffer;
  while (!file.atEnd()) { // while not at the end of the file
    buffer.append(file.read(readSize)); //read up to 1 MB
    datasize = buffer.size(); // update data size
    if (datasize > readSize * mb) {
      cerr << "Read " << mb << "MB and found no frame!" << endl;
      return 0;
    }
    if (datasize < patternSize) {
      break; // to short for complete pattern -> finished
    }
    if (!noprogress) { //output position
      cerr << "Frame count analyse at " << filePosition << " of " << size << endl;
      filePosition++;
    }
    idx = buffer.indexOf(basePattern); // find basePattern
    while (idx != -1) {
      yIndex = idx + patternSize;
      if (datasize < yIndex) {  // to short for complete pattern -> finished
        break;
      }
      checkMPEG2FrameType(idx, basePatternSize, yIndex, buffer, count);
      buffer = buffer.remove(0, idx + basePatternSize); // remove start to end of base pattern
      idx = buffer.indexOf(basePattern); // search for base pattern
    }
  }
  file.close();
  return count;
}

int framecountOfRawH264(const QString &input, const bool list, const bool noprogress)
{
  //cerr << "Analysing framecountOfRawH264 for: " << qPrintable(input) << endl;
  QFile file(input);
  if (!file.open(QIODevice::ReadOnly)) {
    cerr << "Couldn't open " << qPrintable(input) << " for frame parsing." << endl;
    return 0;
  }

  /**
   *   NAL Units start code: 00 00 01 X Y
   *   X =  IDR Picture NAL Units (25, 45, 65)
   *   X = Non IDR Picture NAL Units (01, 21, 41, 61) ; 01 = b-frames, 41 = p-frames
   *   since frames can be splitted over multiple NAL Units only count the NAL Units with Y > 0x80
   **/
  QByteArray data, basePattern;
  basePattern.resize(3);
  //start code:
  basePattern[0] = (char) 0x00;
  basePattern[1] = (char) 0x00;
  basePattern[2] = (char) 0x01;

  char end1 = 0x25, end2 = 0x45, end3 = 0x65; //IDR-Frames
  char end4 = 0x01, end5 = 0x21, end6 = 0x41, end7 = 0x61; //non IDR
  char end8 = 0x09, end9 = 0x67; //SPS
  char end10 = 0x68; //PPS

  char x;
  int idx, yIndex, count = 0, datasize;
  int sizecount = 1;
  int readSize = 2 << 20;
  double size = file.size() / double(readSize);
  int basePatternSize = basePattern.size();
  int patternSize = basePatternSize + 2;
  QString prefix;
  int position = 0;
  int lastIDRPosition = 0;
  int maxGOPsize = 0;
  bool validY = false;
  QHash<char, int> counted, unknown, spspps;
  while (!file.atEnd()) {
    data.append(file.read(readSize)); //read 1MB
    datasize = data.size();
    if (datasize > readSize * 20) {
      cerr << "Read 20MB and found no frame!" << endl;
      return 0;
    }
    if (datasize < patternSize) {
      break; //no complete pattern -> finished
    }
    if (!noprogress) {
      //output position
      cerr << "Frame count analyse at " << sizecount << " of " << size << endl;
      sizecount++;
    }

    idx = data.indexOf(basePattern); //next basePattern index
    while (idx != -1) {
      yIndex = idx + basePatternSize + 1;
      if (datasize < yIndex) {
        break; //no complete pattern
      }
      /*
       * char end1 = 0x25, end2 = 0x45, end3 = 0x65; //IDR-Frames
       char end4 = 0x01, end5 = 0x21, end6 = 0x41, end7 = 0x61; //non IDR
       char end8 = 0x09, end9 = 0x67; //SPS
       char end10 = 0x68; //PPS
       */
      x = data[idx + basePatternSize];
      validY = (data[yIndex] & 0x80) > 0;
      if (x == end1 || x == end2 || x == end3 || x == end4 || x == end5 || x == end6 || x == end7) {
        if (validY) {
          counted.insert(x, counted.value(x) + 1);
          ++count;
          if (x == end1) {
            if (list) {
              cerr << position << " : IDR (0x25)" << endl;
            }
            adjustGOPSize(count, lastIDRPosition, maxGOPsize);
          } else if (x == end2) {
            if (list) {
              cerr << position << " : IDR (0x45)" << endl;
            }
            adjustGOPSize(count, lastIDRPosition, maxGOPsize);
          } else if (x == end3) {
            if (list) {
              cerr << position << " : IDR (0x65)" << endl;
            }
            adjustGOPSize(count, lastIDRPosition, maxGOPsize);
          } else if (list) {
            if (x == end4) {
              cerr << position << " : B (0x01)" << endl;
            } else if (x == end5) {
              cerr << position << " : non-IDR (0x21)" << endl;
            } else if (x == end6) {
              cerr << position << " : P (0x41)" << endl;
            } else if (x == end7) {
              cerr << position << " : non-IDR (0x61)" << endl;
            }
          }
          position++;
        }
        data = data.remove(0, idx + patternSize); //remove all up to end of pattern
      } else if (x == end8 || x == end9 || x == end10) {
        if (validY) {
          spspps.insert(x, spspps.value(x) + 1); //insert spspps ending
          data = data.remove(0, idx + patternSize); //remove all up to end of pattern
        } else {
          data = data.remove(0, idx + 1); //remove all up to current index
        }
      } else {
        if (validY) {
          unknown.insert(x, unknown.value(x) + 1); //insert unknown ending
        }
        data = data.remove(0, idx + 1); //remove all up to current index
      }

      datasize = data.size();
      idx = data.indexOf(basePattern);
    }
  }
  file.close();

  int endingCount;
  char current;
  QList<char> endings;

  //output counted endings
  endings = counted.keys();
  endingCount = endings.count();
  if (endingCount > 0) {
    cerr << endl;
    cerr << "counted:" << endl;

    for (int i = 0; i < endingCount; ++i) {
      current = endings.at(i);
      prefix = (current < 10) ? "0x0" : "0x";
      prefix += QString::number(current, 16);
      if (prefix == "0x25" || prefix == "0x45" || prefix == "0x65") {
        prefix = "IDR (" + prefix + ")";
      } else if (prefix == "0x41") {
        prefix = "P (" + prefix + ")";
      } else if (prefix == "0x01") {
        prefix = "B (" + prefix + ")";
      } else if (prefix == "0x01") {
        prefix = "B (" + prefix + ")";
      } else if (prefix == "0x21" || prefix == "0x61") {
        prefix = "non-IDRB (" + prefix + ")";
      } else {
        prefix = "unknown (" + prefix + ")";
      }
      cerr << qPrintable(prefix);
      cerr << " " << counted.value(current) << " times." << endl;
    }
  }

  //output spspps endings
  endings = spspps.keys();
  endingCount = endings.count();
  if (count > 0) {
    cerr << endl;
    cerr << "sps/pps:" << endl;

    for (int i = 0; i < endingCount; ++i) {
      current = endings.at(i);
      prefix = (current < 10) ? "0x0" : "0x";
      cerr << qPrintable(prefix + QString::number(current, 16));
      cerr << " " << spspps.value(current) << " times." << endl;
    }
  }

  //output unknown endings
  endings = unknown.keys();
  endingCount = endings.count();
  if (endingCount > 0) {
    cerr << endl;
    cerr << "unknown:" << endl;
    for (int i = 0; i < endingCount; ++i) {
      current = endings.at(i);
      prefix = (current < 10) ? "0x0" : "0x";
      cerr << qPrintable(prefix + QString::number(current, 16));
      cerr << " " << unknown.value(current) << " times." << endl;
    }
  }
  //output max gop size
  cerr << endl;
  cerr << qPrintable("max gop size: " + QString::number(maxGOPsize)) << endl;
  cerr << endl;
  return count - 1;
}

int framecountOfRawPatternSizeFour(const QString &input, const int pattern, const bool noprogress)
{
  QFile file(input);
  if (!file.open(QIODevice::ReadOnly)) {
    cerr << qPrintable(QObject::tr("Couldn't open for frame parsing: ") + input) << endl;
    return 0;
  }
  QByteArray data, basePattern;
  switch (pattern)
  {
    case 2 :
      /**
       * MPEG-4 ASP
       * VOB Start-Code / base pattern: 00 00 01 B6
       * 00  intra-coded (I)
       * 01  predictive-coded (P)
       * 10  bidirectionally-predictive-coded (B)
       * 11  sprite (S)
       * */
      basePattern.resize(4);
      basePattern[0] = (char) 0x00;
      basePattern[1] = (char) 0x00;
      basePattern[2] = (char) 0x01;
      basePattern[3] = (char) 0xb6;
      //counting all VOBS
      break;
    case 1 : //VC-1
      basePattern.resize(4);
      basePattern[0] = (char) 0x00;
      basePattern[1] = (char) 0x00;
      basePattern[2] = (char) 0x01;
      basePattern[3] = (char) 0x0d;
      break;
    default : //unknown pattern
      cerr << qPrintable(QObject::tr("Unknown pattern: %1").arg(pattern)) << endl;
      return 0;
  }
  int idx, count = 0;
  int sizecount = 1;
  QString tmp1 = "Frame count analyse at ";
  QString tmp2 = " of " + QString::number(file.size() / 1048576.0);
  while (!file.atEnd()) {
    data.append(file.read(1024 * 1024)); //1MB
    if (data.size() < 4) {
      break;
    }
    if (!noprogress) {
      cerr << qPrintable(tmp1) << sizecount << qPrintable(tmp2) << endl;
      sizecount++;
    }

    idx = data.indexOf(basePattern);
    while (idx != -1) {
      ++count;
      data = data.remove(0, idx + 4);
      idx = data.indexOf(basePattern);
    }
  }
  return count;
}

int analyse(QString input, bool list, bool noprogress)
{
  if (input.endsWith(".264", Qt::CaseInsensitive) || input.endsWith(".h264", Qt::CaseInsensitive)
      || input.endsWith(".avc", Qt::CaseInsensitive)) {
    cerr << "analysing h.264 frame count of: " << qPrintable(input) << endl;
    return framecountOfRawH264(input, list, noprogress);
  } else if (input.endsWith(".vc1", Qt::CaseInsensitive)
      || input.endsWith(".vc-1", Qt::CaseInsensitive)) {
    cerr << "analysing vc-1 frame count of: " << qPrintable(input) << endl;
    return framecountOfRawPatternSizeFour(input, 1, noprogress);
  } else if (input.endsWith(".m4v", Qt::CaseInsensitive)) {
    cerr << "analysing mpeg-4 part 2 frame count of: " << qPrintable(input) << endl;
    return framecountOfRawPatternSizeFour(input, 2, noprogress);
  } else if (input.endsWith(".m2v", Qt::CaseInsensitive)) {
    cerr << "analysing mpeg-2 frame count of: " << qPrintable(input) << endl;
    return framecountOfRawMPEG2(input, noprogress);
  } else {
    cerr << "Unsupported input: " << qPrintable(input) << endl;
  }
  return 0;
}

int main(int argc, char *argv[])
{
  //cerr << "argc " << argc << endl;
  if (argc < 2 || argc > 4) {
    cerr << "framecount: 0" << endl;
    return -1;
  }
  bool list = false;
  bool noprogress = false;
  QString current;
  for (int i = 2; i < argc; ++i) {
    current = QString(argv[i]);
    if (current == QLatin1String("list")) {
      list = true;
      cerr << "listing elements enabled" << endl;
      continue;
    }
    if (current == QLatin1String("noprogress")) {
      noprogress = true;
      cerr << "disabling progress indication" << endl;
      continue;
    }
  }
  cerr << "framecount: " << analyse(argv[1], list, noprogress);
  return 0;
}
