/* 

   Copyright (c) 2001  Edwin Pratomo

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file,
   with the exception that it cannot be placed on a CD-ROM or similar media
   for commercial distribution without the prior approval of the author.

*/

#ifdef __cplusplus
    extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
    }
#endif

#undef assert
#undef list

#if defined(XALAN_OLD_STREAM_HEADERS)
    #include <strstream.h>
#else
    #include <strstream>
#endif 

#include <sax/SAXException.hpp>
#include <XalanDOM/XalanDOMException.hpp>

#include <util/PlatformUtils.hpp>
#include <PlatformSupport/DOMStringPrintWriter.hpp>
#include <PlatformSupport/DOMStringHelper.hpp>

#include <XalanSourceTree/XalanSourceTreeDOMSupport.hpp>
#include <XalanSourceTree/XalanSourceTreeParserLiaison.hpp>

#include <XalanTransformer/XalanTransformer.hpp>

static SV *global_flush_handler = (SV*)NULL;
static HV *out_handler_mapping = (HV*)NULL;

void write_err_str(SV *rv, char *msg) {
	if (!SvROK(rv))
		croak("Not a reference to Error."); 
	sv_setpv((SV*)SvRV(rv), msg);
}

unsigned long
out_handler_internal(
    const void *buffer, 
    unsigned long buffer_length, 
    const void *out_handle) 
{
    dSP;
    SV **sv;
    STRLEN len;
    char *key = SvPV((SV*)out_handle, len); 

    sv = hv_fetch(out_handler_mapping, key, len, FALSE);
    if (sv == (SV**)NULL) 
        croak("Not mapped..");

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal( (SV*)out_handle ));
    XPUSHs(sv_2mortal( newSVpv((char*)buffer, buffer_length) ));
    PUTBACK;

    perl_call_sv(*sv, G_VOID);

    FREETMPS;
    LEAVE;
    return buffer_length;
}

void
flush_handler_internal(const void *buffer)
{
    dSP;
    
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal( newSVpv((char*)buffer, 0) ));
    PUTBACK;

    perl_call_sv(global_flush_handler, G_VOID);

    FREETMPS;
    LEAVE;
}

// wrapper to XSLTEngineImpl::process()
int _transform(
    XSLTEngineImpl& engine,
    const XSLTInputSource& theInputSource,
    XSLTResultTarget& theResultTarget,
    StylesheetExecutionContextDefault& ExecutionCtx,
    SV *Error) 
{
    XalanDOMString  theErrorMessage;
    CharVectorType  myError;
    int retval = 0;
    try {
    // Create a problem listener and send output to a XalanDOMString. 
        DOMStringPrintWriter thePrintWriter(theErrorMessage);
        ProblemListenerDefault theProblemListener(&thePrintWriter);
        engine.setProblemListener(&theProblemListener);     
        engine.process(theInputSource, theResultTarget, ExecutionCtx); 

    }
    catch (XSLException& e) {
        if (length(theErrorMessage) != 0) {
            TranscodeToLocalCodePage(theErrorMessage, myError, true);
        } else {
            TranscodeToLocalCodePage(e.getMessage(), myError, true);
        }
        retval = -1;
    }
    catch (SAXException& e) {
        if (length(theErrorMessage) != 0)
        {
            TranscodeToLocalCodePage(theErrorMessage, myError, true);
        } else {
            TranscodeToLocalCodePage(e.getMessage(), myError, true);
        }
        retval = -2;
    }
    catch (XMLException& e) {
        if (length(theErrorMessage) != 0) {
            TranscodeToLocalCodePage(theErrorMessage, myError, true);
        }
        else {
            TranscodeToLocalCodePage(e.getMessage(), myError, true);
        }
        retval = -3;
    }
    catch(const XalanDOMException& e) {
        if (length(theErrorMessage) != 0) {
            TranscodeToLocalCodePage(theErrorMessage, myError, true);
        } else {
            XalanDOMString theMessage("XalanDOMException caught.  The code is ");
            append(theMessage,  LongToDOMString(long(e.getExceptionCode())));
            append(theMessage,  XalanDOMString("."));
            TranscodeToLocalCodePage(theMessage, myError, true);
        }
        retval = -4;
    }
    try {
        //ExecutionCtx.reset();
        engine.setProblemListener(0);
    }
    catch(...) { }
    //sv_setpv(Error, &myError[0]);
	write_err_str(Error, &myError[0]);
    myError.clear();
    myError.push_back(0);
    return retval;
}

MODULE = XML::Xalan     PACKAGE = XML::Xalan
PROTOTYPES: DISABLE

void
initialize()
    CODE:
    // Call the static initializer for Xerces. 
    XMLPlatformUtils::Initialize();
    XalanTransformer::initialize();

void
terminate()
    CODE:
    XalanTransformer::terminate();
    XMLPlatformUtils::Terminate();

void
END()
    CODE:
    XalanTransformer::terminate();
    XMLPlatformUtils::Terminate();

MODULE = XML::Xalan     PACKAGE = XML::Xalan::_XSLTEngineImpl
PROTOTYPES: DISABLE

XSLTEngineImpl*
new(CLASS, ParserLiaison, XSLTPEnvSupp, DOMSupp, XObjFac, XPathFac)
    char *CLASS
    XalanSourceTreeParserLiaison *ParserLiaison
    XSLTProcessorEnvSupportDefault *XSLTPEnvSupp
    XalanSourceTreeDOMSupport *DOMSupp
    XObjectFactoryDefault *XObjFac
    XPathFactoryDefault *XPathFac
    CODE:
    RETVAL = new XSLTEngineImpl(
        (XalanSourceTreeParserLiaison &)*ParserLiaison, 
        (XSLTProcessorEnvSupportDefault &)*XSLTPEnvSupp,
        (XalanSourceTreeDOMSupport &)*DOMSupp, 
        (XObjectFactoryDefault &) *XObjFac, 
        (XPathFactoryDefault &) *XPathFac);
    OUTPUT:
    RETVAL

int
_transform_to_file(self, xml_in, xml_out, ExecutionCtx, Error)
    XSLTEngineImpl *self
    const char *xml_in
    const char *xml_out
    StylesheetExecutionContextDefault *ExecutionCtx
    SV *Error
    CODE:
    const XalanDOMString theDOMStringXMLFileName(xml_in);
    XSLTInputSource theInputSource(c_wstr(theDOMStringXMLFileName));

    const XalanDOMString theDomStringOutFileName(xml_out);
    //XSLTResultTarget theResultTarget(XalanDOMString(xml_out));
    XSLTResultTarget theResultTarget(theDomStringOutFileName);

    if (_transform((XSLTEngineImpl &)*self, 
        theInputSource, theResultTarget, 
        (StylesheetExecutionContextDefault &) *ExecutionCtx, 
        Error) < 0) {
        XSRETURN_UNDEF;
    } else {
        XSRETURN_YES;
    } 

int
_transform_doc_to_file(self, xalan_doc, xml_out, ExecutionCtx, Error)
    XSLTEngineImpl *self
    XalanDocument *xalan_doc
	const char *xml_out
    StylesheetExecutionContextDefault *ExecutionCtx
    SV *Error
    CODE:
    // Set input sources
    XSLTInputSource theInputSource(xalan_doc);

    const XalanDOMString theDomStringOutFileName(xml_out);
    XSLTResultTarget theResultTarget(theDomStringOutFileName);

    if (_transform(*self, theInputSource, theResultTarget, 
        *ExecutionCtx, Error) < 0) {
        XSRETURN_UNDEF;
    } else {
		XSRETURN_YES;
    }

char*
_transform_to_data(self, xml_in, ExecutionCtx, Error)
    XSLTEngineImpl *self
    char *xml_in
    StylesheetExecutionContextDefault *ExecutionCtx
    SV *Error
    CODE:
    //#if !defined(XALAN_NO_NAMESPACES)
    //    using std::ostrstream;
    //#endif
    ostrstream  theOutputStream;

    // Set input sources
    const XalanDOMString theDOMStringXMLFileName(xml_in);
    XSLTInputSource theInputSource(c_wstr(theDOMStringXMLFileName));

    XSLTResultTarget theResultTarget(&theOutputStream);
    if (_transform(*self, theInputSource, theResultTarget, 
        *ExecutionCtx, Error) < 0) {
        XSRETURN_UNDEF;
    } else {
        // Null-terminate the data.
        theOutputStream << '\0';
        RETVAL = theOutputStream.str();
    }
    OUTPUT:
    RETVAL

char*
_transform_doc_to_data(self, xalan_doc, ExecutionCtx, Error)
    XSLTEngineImpl *self
    XalanDocument *xalan_doc
    StylesheetExecutionContextDefault *ExecutionCtx
    SV *Error
    CODE:
    //#if !defined(XALAN_NO_NAMESPACES)
    //    using std::ostrstream;
    //#endif
    ostrstream  theOutputStream;

    // Set input sources
    XSLTInputSource theInputSource(xalan_doc);

    XSLTResultTarget theResultTarget(&theOutputStream);
    if (_transform(*self, theInputSource, theResultTarget, 
        *ExecutionCtx, Error) < 0) {
        XSRETURN_UNDEF;
    } else {
        // Null-terminate the data.
        theOutputStream << '\0';
        RETVAL = theOutputStream.str();
    }
    OUTPUT:
    RETVAL


StylesheetRoot*
_processStylesheet(self, xsl_file, ConstructionCtx)
    XSLTEngineImpl *self
    char *xsl_file
    StylesheetConstructionContextDefault *ConstructionCtx
    PREINIT:
    char *CLASS = "XML::Xalan::StylesheetRoot";
    CODE:
    const XalanDOMString theDOMStringXSLFileName(xsl_file);
    XSLTInputSource theStylesheetSource(c_wstr(theDOMStringXSLFileName));

    RETVAL = self->processStylesheet(theStylesheetSource, 
        (StylesheetConstructionContextDefault &)*ConstructionCtx);

    OUTPUT:
    RETVAL

int
_set_stylesheet_param(self, key, value, Error)
    XSLTEngineImpl *self
    SV *key
    SV *value
    SV *Error
    CODE:
    const XalanDOMString param_key(SvPV(key, PL_na));
    const XalanDOMString param_val(SvPV(value, PL_na));
    try {
        self->setStylesheetParam(param_key, param_val);
    }
    catch(...) {
        write_err_str(Error, "Fail to setStylesheetParam()");
        XSRETURN_UNDEF;
    }
    XSRETURN_YES;

void
XSLTEngineImpl::reset()

void
XSLTEngineImpl::DESTROY()

MODULE = XML::Xalan     PACKAGE = XML::Xalan::_ParserLiaison
PROTOTYPES: DISABLE

XalanSourceTreeParserLiaison*
new(CLASS, DOMSupp)
    char *CLASS
    XalanSourceTreeDOMSupport *DOMSupp
    CODE:
    RETVAL = new XalanSourceTreeParserLiaison(
        (XalanSourceTreeDOMSupport &)*DOMSupp);
    //sv_setiv((SV*)SvRV( ST(1) ), (IV)DOMSupp);
    OUTPUT:
    RETVAL

void
XalanSourceTreeParserLiaison::reset()

void
XalanSourceTreeParserLiaison::DESTROY()


MODULE = XML::Xalan     PACKAGE = XML::Xalan::ProcessorEnvSupport
PROTOTYPES: DISABLE

XSLTProcessorEnvSupportDefault*
XSLTProcessorEnvSupportDefault::new()

void
XSLTProcessorEnvSupportDefault::setProcessor(Processor)
    XSLTEngineImpl *Processor

void
XSLTProcessorEnvSupportDefault::reset()

void
XSLTProcessorEnvSupportDefault::DESTROY()


MODULE = XML::Xalan     PACKAGE = XML::Xalan::_DOMSupport
PROTOTYPES: DISABLE

XalanSourceTreeDOMSupport*
XalanSourceTreeDOMSupport::new()

void
XalanSourceTreeDOMSupport::setParserLiaison(ParserLiaison)
    XalanSourceTreeParserLiaison *ParserLiaison

void
XalanSourceTreeDOMSupport::DESTROY()


MODULE = XML::Xalan     PACKAGE = XML::Xalan::_ExecutionContext
PROTOTYPES: DISABLE

StylesheetExecutionContextDefault*
new(CLASS, Processor, EnvSupport, DOMSupport, XObjFac)
    char *CLASS
    XSLTEngineImpl *Processor
    XSLTProcessorEnvSupportDefault *EnvSupport
    XalanSourceTreeDOMSupport *DOMSupport
    XObjectFactoryDefault *XObjFac
    CODE:
    RETVAL = new StylesheetExecutionContextDefault(
        (XSLTEngineImpl &)*Processor,
        (XSLTProcessorEnvSupportDefault &)*EnvSupport, 
        (XalanSourceTreeDOMSupport &)*DOMSupport, 
        (XObjectFactoryDefault &)*XObjFac);

    OUTPUT:
    RETVAL

void
StylesheetExecutionContextDefault::setStylesheetRoot(StyleRoot)
    StylesheetRoot *StyleRoot

void
StylesheetExecutionContextDefault::reset()

void
DESTROY(self)
    StylesheetExecutionContextDefault *self
    CODE:
    delete self;

MODULE = XML::Xalan     PACKAGE = XML::Xalan::_ConstructionContext
PROTOTYPES: DISABLE

StylesheetConstructionContextDefault*
new(CLASS, Processor, EnvSupport, XPathFac)
    char *CLASS
    XSLTEngineImpl *Processor
    XSLTProcessorEnvSupportDefault *EnvSupport
    XPathFactoryDefault *XPathFac
    CODE:
    RETVAL = new StylesheetConstructionContextDefault(
        (XSLTEngineImpl &)*Processor, 
        (XSLTProcessorEnvSupportDefault &)*EnvSupport, 
        (XPathFactoryDefault &)*XPathFac);
    
    OUTPUT:
    RETVAL

void
StylesheetConstructionContextDefault::DESTROY()

MODULE = XML::Xalan     PACKAGE = XML::Xalan::ObjectFactory
PROTOTYPES: DISABLE

XObjectFactoryDefault*
XObjectFactoryDefault::new()

void
XObjectFactoryDefault::DESTROY()

MODULE = XML::Xalan     PACKAGE = XML::Xalan::XPathFactory
PROTOTYPES: DISABLE

XPathFactoryDefault*
XPathFactoryDefault::new()

void
XPathFactoryDefault::DESTROY()
