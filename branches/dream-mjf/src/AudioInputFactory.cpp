#include "AudioInputFactory.h"
#include "creceivedata.h"

CAudioInputFactory::CAudioInputFactory(CReceiveData& cRD) :
deviceInfo(), format()
{
    pAudioInput = nullptr;
    pIODevice = nullptr;
    QObject::connect((QObject*)&cRD, SIGNAL(CReceiveData.AudioInterfaceCreate(QAudioDeviceInfo,QAudioFormat)),this,SLOT(CreateNew()));
    QObject::connect((QObject*)&cRD, SIGNAL(CReceiveData.AudioInterfaceStart()),this,SLOT(Start()));
    QObject::connect((QObject*)&cRD, SIGNAL(CReceiveData.AudioInterfaceStop()),this,SLOT(Stop()));
}

CAudioInputFactory::~CAudioInputFactory()
{
    Stop();
}

void CAudioInputFactory::CreateNew(QAudioDeviceInfo deviceInfo, QAudioFormat format)
{
    QAudioFormat nearestFormat = deviceInfo.nearestFormat(format);
    pAudioInput = new QAudioInput(deviceInfo, nearestFormat);
}

void CAudioInputFactory::Start()
{
    pIODevice = pAudioInput->start();
    if(pAudioInput->error()==QAudio::NoError)
    {
        if(pIODevice->open(QIODevice::ReadOnly)) {
        qDebug("audio input open");
        }
        else {
            qDebug("audio input open failed");
        }
    }
    else
    {
        qDebug("Can't open audio input");
    }
}

void CAudioInputFactory::Stop()
{
    if(pAudioInput != nullptr) {
        pAudioInput->stop();
        delete pAudioInput;
        pAudioInput = nullptr;
    }
    if(pIODevice!=nullptr) {
        pIODevice->close();
        pIODevice = nullptr;
    }
}

