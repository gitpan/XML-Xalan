/*
 * Copyright (c) 2001-2002  Edwin Pratomo
 *
 */

// Class header file.
#include "XSv.hpp"

#include <PlatformSupport/DOMStringHelper.hpp>

#ifdef Null
    #undef Null
#endif

#include <XPath/XObjectTypeCallback.hpp>

XalanDOMString  XSv::s_dummyString;

XSv::XSv(SV *val) :
    XObject(eTypeUserDefined)
{
    m_value = newSVsv(val);
    s_dummyString = "Perl SV";
}

XSv::XSv(const XSv& source) :
    XObject(source)
{
    m_value = newSVsv(source.m_value);
}

XSv::~XSv()
{
    SvREFCNT_dec(m_value);
}


#if defined(XALAN_NO_COVARIANT_RETURN_TYPE)
XObject*
#else
XSv*
#endif
XSv::clone(void*    theAddress) const
{
    return theAddress == 0 ? new XSv(*this) : new (theAddress) XSv(*this);
};

XalanDOMString
XSv::getTypeString() const
{
    return XALAN_STATIC_UCODE_STRING("#SV");
}

SV*
XSv::getSV() const
{
    return m_value;
}

const XalanDOMString&
XSv::str() const
{
    //PerlIO_printf(PerlIO_stderr(), "returning dummy string..\n");
    return s_dummyString;
}

void
XSv::str(
            FormatterListener&  formatterListener,
            MemberFunctionPtr   function) const
{
    (formatterListener.*function)(c_wstr(s_dummyString), length(s_dummyString));
}

void
XSv::ProcessXObjectTypeCallback(XObjectTypeCallback&    theCallbackObject)
{
    theCallbackObject.Unknown(*this, str());
}

void
XSv::ProcessXObjectTypeCallback(XObjectTypeCallback&    theCallbackObject) const
{
    theCallbackObject.Unknown(*this, str());
}

void
XSv::initialize()
{
    s_dummyString = XALAN_STATIC_UCODE_STRING("Perl SV");
}

void
XSv::terminate()
{
    releaseMemory(s_dummyString);
}
