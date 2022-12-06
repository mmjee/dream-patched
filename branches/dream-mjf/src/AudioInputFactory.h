#ifndef AUDIOINPUTFACTORY_H
#define AUDIOINPUTFACTORY_H

#include <QObject>
#include <QAudioDeviceInfo>
#include <QAudioInput>
#include <QIODevice>
#include "creceivedata.h"

QAudioInput*        pAudioInput;
QIODevice*          pIODevice;

class CAudioInputFactory: public QObject
{
    Q_OBJECT
public:
    CAudioInputFactory(CReceiveData& cRD);
    virtual ~CAudioInputFactory();
public slots:
    virtual void CreateNew(QAudioDeviceInfo deviceInfo, QAudioFormat format);
    virtual void Start();
    virtual void Stop();
protected:
    QAudioDeviceInfo    deviceInfo;
    QAudioFormat        format;
};

#endif // AUDIOINPUTFACTORY_H
