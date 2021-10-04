#ifndef TUNER_H
#define TUNER_H

class CTuner
{
public:
    virtual void SetFrequency(int) = 0;
    virtual ~CTuner();
};

#endif // TUNER_H
