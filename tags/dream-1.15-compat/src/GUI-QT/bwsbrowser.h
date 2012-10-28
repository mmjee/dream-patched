/******************************************************************************\
 * British Broadcasting Corporation
 * Copyright (c) 2009
 *
 * Author(s):
 *	 Julian Cable
 *
 * Description: Broadcast Website Specialisation of TextBrowser
 *
 *
 ******************************************************************************
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

#ifndef _BWSBROWSER_H
#define _BWSBROWSER_H

#include <map>
#include <QTextBrowser>
#include "../datadecoding/DABMOT.h"

class BWSBrowser : public QTextBrowser
{
	Q_OBJECT
public:
    BWSBrowser(QWidget * parent = 0 );
    ~BWSBrowser() {}
    QVariant loadResource ( int type, const QUrl & name );
    bool changed();
    void setDecoder(CMOTDABDec *d) { decoder = d; }
    void setRestrictedProfile(bool b) { restricted = b; }
    bool restrictedProfile() { return restricted; }
    QString homeUrl() const { return shomeUrl; }

protected:

    CMOTDABDec*   decoder;
    std::map<QString,CMOTObject> pages;
    QString shomeUrl;
    bool restricted;
};

#endif