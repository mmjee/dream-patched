/******************************************************************************\
* Technische Universitaet Darmstadt, Institut fuer Nachrichtentechnik
* Copyright (c) 2001-2007
*
* Author(s):
*gVolker Fischer, Andrew Murphy, Andrea Russo
*
* Description:
*gLogging to a file
*
*******************************************************************************
*
* This program is free software; you can redistribute it and/or modify it under
* the terms of the GNU General Public License as published by the Free Software
* Foundation; either version 2 of the License, or (at your option) any later
* version.
*
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
* details.
*
* You should have received a copy of the GNU General Public License along with
* this program; if not, write to the Free Software Foundation, Inc.,
* 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*
\******************************************************************************/

#ifndef _RECEPTLOG_H
#define _RECEPTLOG_H

#include "Parameter.h"
#include <fstream>

class CReceptLog
{
  public:
	CReceptLog(CParameter & p):Parameters(p), File(),
        bHeaderNeeded(true), bLogActivated(false),
		bRxlEnabled(false), bPositionEnabled(false),
		iSecDelLogStart(0), iFrequency(0)
	{
	}
	virtual ~CReceptLog()
	{
	}
	void Start(const string & filename);
	void Stop();
	void Update();

	void SetRxlEnabled(const bool b) { bRxlEnabled = b; }
	bool GetRxlEnabled() { return bRxlEnabled; }

	void SetPositionEnabled(const bool b) { bPositionEnabled = b; }
	bool GetPositionEnabled() { return bPositionEnabled; }
	bool GetLoggingActivated() { return bLogActivated; }

	void SetDelLogStart(const int iSecDel) { iSecDelLogStart = iSecDel; }

	int GetDelLogStart() { return iSecDelLogStart; }

	void SetLogFrequency(int iNew);

  protected:
	virtual void init() = 0;
	virtual void writeParameters() = 0;
	virtual void writeHeader() = 0;
	virtual void writeTrailer() = 0;
	char GetRobModeStr();

	string strdate(time_t);
	string strtime(time_t);

	CParameter & Parameters;
	ofstream File;
	bool bHeaderNeeded;
	bool bLogActivated;
	bool bLogEnabled;
	bool bRxlEnabled;
	bool bPositionEnabled;
	int iSecDelLogStart;
	int iFrequency;
};

class CShortLog: public CReceptLog
{
  public:
	CShortLog(CParameter& p):CReceptLog(p) {}
  protected:
	virtual void init();
	virtual void writeParameters();
	virtual void writeHeader();
	virtual void writeTrailer();
	int iCount;
};

class CLongLog: public CReceptLog
{
  public:
	CLongLog(CParameter& p):CReceptLog(p) {}
  protected:
	virtual void init();
	virtual void writeParameters();
	virtual void writeHeader();
	virtual void writeTrailer();
};

#endif
