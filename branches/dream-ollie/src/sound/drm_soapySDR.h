#ifndef DRM_SOAPYSDR_H
#define DRM_SOAPYSDR_H

#include "../sound/soundinterface.h"
#include "../tuner.h"

namespace SoapySDR {class Device; class Stream;};

class CSoapySDRIn : public CSoundInInterface, public CTuner
{
public:

    CSoapySDRIn();
    virtual ~CSoapySDRIn();
    // CSoundInInterface methods
    virtual bool Init(int iSampleRate, int iNewBufferSize, bool bNewBlocking);
    virtual bool Read(CVector<short>& psData);
    virtual void     Close();
    virtual std::string	GetVersion();

    // CSelectionInterface methods
    virtual void		Enumerate(std::vector<std::string>& names, std::vector<std::string>& descriptions, std::string& defaultDevice);
    virtual std::string	GetDev();
    virtual void		SetDev(std::string sNewDev);

    // CTuner methods
    virtual void SetFrequency(int);
protected:
    std::string currentDev;
    int				iSampleRate;
    int				iBufferSize;
    int             iFrequency;

    SoapySDR::Device *pDevice;
    SoapySDR::Stream *pStream;

    FILE *pFile;
};

#endif // DRM_SOAPYSDR_H
