/*
 * Copyright 2001-2002, Edwin Pratomo
 *
 */

#if !defined(XSV_HEADER_GUARD_1357924680)
#define XSV_HEADER_GUARD_1357924680

// Base header file.  Must be first.
#include <XPath/XPathDefinitions.hpp>

// Base class header file.
#include <XPath/XObject.hpp>


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


//class XALAN_XPATH_EXPORT XSv : public XObject
class XALAN_PLATFORM_EXPORT XSv : public XObject
{
public:

    /**
     * Perform static initialization.  See class XPathInit.
     */
    static void
    initialize();

    /**
     * Perform static shut down.  See class XPathInit.
     */
    static void
    terminate();

    /* constructors */
    XSv(SV *val);
    XSv(const XSv&  source);

    virtual
    ~XSv();

    // These methods are inherited from XObject ...

#if defined(XALAN_NO_COVARIANT_RETURN_TYPE)
    virtual XObject*
#else
    virtual XSv*
#endif
    clone(void*     theAddress = 0) const;

    virtual XalanDOMString
    getTypeString() const;

    virtual SV*
    getSV() const;

    virtual const XalanDOMString&
    str() const;

    virtual void
    str(
            FormatterListener&  formatterListener,
            MemberFunctionPtr   function) const;

    virtual void 
    ProcessXObjectTypeCallback(XObjectTypeCallback& theCallbackObject);

    virtual void 
    ProcessXObjectTypeCallback(XObjectTypeCallback& theCallbackObject) const;

private:
    SV *m_value;

    static XalanDOMString   s_dummyString;
};

#endif  // XSV_HEADER_GUARD_1357924680
