CONFIG += console

macx {
CONFIG-=app_bundle
}

TARGET = framecounter

QT += core

SOURCES += framecounter.cpp
