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
#include <XalanTransformer/XalanCompiledStylesheetDefault.hpp>

#include <XPath/Function.hpp>
#include <XPath/XObjectFactory.hpp>

static SV *global_flush_handler = (SV*)NULL;
static HV *out_handler_mapping = (HV*)NULL;

/* 
 * XalanTransformer/XalanTransformerOutputStream.cpp: 
 * returns: number of bytes written
 * void *buffer contains the data to be written,
 * unsigned long buffer_length contains the buffer's length
 * void *out_handle is the filehandle
 */

#ifdef __cplusplus
extern "C" {
#endif

/*
    ./XPath/XPathExecutionContext.hpp:      
    typedef std::vector<XObjectPtr> XObjectArgVectorType;
*/

unsigned long
out_handler_internal(
    const char *buffer, 
    unsigned long buffer_length, 
    void *out_handle) 
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
flush_handler_internal(void *buffer)
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

#ifdef __cplusplus
}
#endif


class UserDefinedFunction : public Function
{
public:
    UserDefinedFunction(
        const char* func_name, 
        SV *func_handler) 
    {
        m_func_name = new char[strlen(func_name) + 1];
        strcpy(m_func_name, func_name);
		m_func_handler = newSVsv(func_handler);
    }

	~UserDefinedFunction()
	{
		//PerlIO_printf(PerlIO_stderr(), "%s destroyed..\n", m_func_name);
		delete m_func_name;
		SvREFCNT_dec(m_func_handler);
	}
    /**
     * Execute an XPath function object.  The function must return a valid
     * object.
     *
     * @param executionContext executing context
     * @param context          current context node
     * @param opPos            current op position
     * @param args             vector of pointers to XObject arguments
     * @return                 pointer to the result XObject
     */
    virtual XObjectPtr
    execute(
            XPathExecutionContext&          executionContext,
            XalanNode*                      context,
            int                             /* opPos */,
            const XObjectArgVectorType&     args)
    {
        dSP;

        int i, j;
        const XObjectPtr *xobj;
        XObjectPtr retxobj;
        int cnt;
        SV *result;
        char *str, *temp_str;
        STRLEN len;
        XalanDOMString tmpDOMString;

//      return executionContext.getXObjectFactory().createNumber(sqrt(args[0]->num()));
//      return executionContext.getXObjectFactory().createString(XalanDOMString(theTimeString));

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        for (i = 0; i < args.size(); i++) {
            tmpDOMString = args[i]->str();
            temp_str = new char[tmpDOMString.length() + 1];
            for (j = 0; j < tmpDOMString.length(); j++) {
                *(temp_str + j) = tmpDOMString[j];
            }
            XPUSHs(sv_2mortal( newSVpv(temp_str, tmpDOMString.length()) ));
            delete temp_str;
        }

        PUTBACK;

        cnt = perl_call_sv(m_func_handler, G_SCALAR);

        SPAGAIN;

        if (cnt != 1)
            executionContext.error("Callback must return a scalar!", context);

        result = POPs;    

        if (!SvOK(result)) 
            executionContext.error("Failed callback!", context);

        str = SvPV(result, len);

        retxobj = executionContext.getXObjectFactory().createString(
            XalanDOMString( str ));

        //PerlIO_printf(PerlIO_stderr(), "str: %s, len: %d\n", str, len);

        PUTBACK;
        FREETMPS;
        LEAVE;

        return retxobj;
    }

    /**
     * Create a copy of the function object.
     *
     * @return pointer to the new object
     */
#if defined(XALAN_NO_COVARIANT_RETURN_TYPE)
    virtual Function*
#else
    virtual UserDefinedFunction*
#endif
    clone() const
    {
        //return new UserDefinedFunction(*this);
        return new UserDefinedFunction(m_func_name, m_func_handler);
    }

private:
    char *m_func_name;
    SV *m_func_handler;
};


MODULE = XML::Xalan::Transformer    PACKAGE = XML::Xalan::Transformer
PROTOTYPES: DISABLE

XalanTransformer*
XalanTransformer::new()

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

const XalanCompiledStylesheet*
compile_stylesheet_file(self, xslfile)
    XalanTransformer *self
    const char *xslfile
    PREINIT:
    int status;
    char *CLASS = "XML::Xalan::CompiledStylesheet";
    CODE:
    const XalanCompiledStylesheet*  theCompiledStylesheet = 0;
    status = self->compileStylesheet(xslfile, theCompiledStylesheet);

    if (status == 0)
    {
        RETVAL = theCompiledStylesheet;
    } else {
        XSRETURN_UNDEF;
    }
    OUTPUT:
    RETVAL

const XalanCompiledStylesheet*
compile_stylesheet_string(self, xslstring)
    XalanTransformer *self
    const char *xslstring
    PREINIT:
    int status;
    char *CLASS = "XML::Xalan::CompiledStylesheet";
    CODE:
    const XalanCompiledStylesheet*  theCompiledStylesheet = 0;
    istrstream  theXSLStream(xslstring, strlen(xslstring));

    status = self->compileStylesheet(&theXSLStream, theCompiledStylesheet);

    if (status == 0)
    {
        RETVAL = theCompiledStylesheet;
    } else {
        XSRETURN_UNDEF;
    }
    OUTPUT:
    RETVAL

const XalanParsedSource*
parse_file(self, xmlfile)
    XalanTransformer *self
    const char *xmlfile
    PREINIT:
    int status;
    char *CLASS = "XML::Xalan::ParsedSource";
    CODE:
    const XalanParsedSource*  theParsedSource = 0;
    status = self->parseSource(xmlfile, theParsedSource);

    if (status == 0)
    {
        RETVAL = theParsedSource;
    } else {
        XSRETURN_UNDEF;
    }
    OUTPUT:
    RETVAL

const XalanParsedSource*
parse_string(self, xmlstring)
    XalanTransformer *self
    const char *xmlstring
    PREINIT:
    int status;
    char *CLASS = "XML::Xalan::ParsedSource";
    CODE:
    const XalanParsedSource*  theParsedSource = 0;
    istrstream theXMLStream(xmlstring, strlen(xmlstring));

    status = self->parseSource(&theXMLStream, theParsedSource);

    if (status == 0)
    {
        RETVAL = theParsedSource;
    } else {
        XSRETURN_UNDEF;
    }
    OUTPUT:
    RETVAL

int
transform_to_handler(self, xmlsource, stylesheet, out_handle, out_handler, ...)
    XalanTransformer *self
    SV *xmlsource
    SV *stylesheet
    SV *out_handle
    SV *out_handler
    PREINIT:
    int status;
    char *key;
    const char *xmlfile = "";
    const char *xslfile = "";
    XalanParsedSource *parsed_source = 0;
    XalanCompiledStylesheet *compiled_stylesheet = 0;
    STRLEN len;
    CODE:
    if (out_handler_mapping == (HV*) NULL) {
        out_handler_mapping = newHV();
    }

    key = SvPV(out_handle, len);
    hv_store(out_handler_mapping, key, len, newSVsv(out_handler), 0);
    //g_out_handler = out_handler;

    if (items > 5) {
        if (global_flush_handler == (SV*)NULL) {
            global_flush_handler = newSVsv(ST(5));
        } else {
            SvSetSV(global_flush_handler, ST(5)); 
        }   
    }

    if (sv_isobject(xmlsource) && (SvTYPE(SvRV(xmlsource)) == SVt_PVMG))
    {
        parsed_source = (XalanParsedSource *)SvIV((SV*)SvRV( xmlsource ));
    } else {
        xmlfile = (const char *)SvPV(xmlsource, PL_na);
    }

    /* 
        If stylesheet is a CompiledStylesheet object, then the first arg must
        be a ParsedSource object 
    */
    if (sv_isobject(stylesheet) && (SvTYPE(SvRV(stylesheet)) == SVt_PVMG))
    {
        compiled_stylesheet = (XalanCompiledStylesheet *)SvIV((SV*)SvRV( stylesheet ));
        status = items > 5 ? 
            self->transform(
                *parsed_source, compiled_stylesheet, (SV*)out_handle, 
                out_handler_internal, flush_handler_internal)
            :
            self->transform(
                *parsed_source, compiled_stylesheet, (SV*)out_handle, 
                out_handler_internal);
    } else if (SvOK(stylesheet)) {

        xslfile = (const char *)SvPV(stylesheet,PL_na);
        status = items > 5 ? 
            self->transform(
                xmlfile, xslfile, (SV*)out_handle, 
                out_handler_internal)
            :
            self->transform(
                xmlfile, xslfile, (SV*)out_handle, 
                out_handler_internal);
    } else {
        status = items > 5 ? 
            self->transform(
                xmlfile, (SV*)out_handle, 
                out_handler_internal, flush_handler_internal)
            :
            self->transform(
                xmlfile, (SV*)out_handle, 
                out_handler_internal);

    }
    hv_delete(out_handler_mapping, key, len, G_DISCARD);
    if (status == 0) 
        XSRETURN_YES;
    else
        XSRETURN_UNDEF;

int
transform_to_file(self, xmlsource, stylesheet, outfile)
    XalanTransformer *self
    SV *xmlsource
    SV *stylesheet
    const char *outfile
    PREINIT:
    int ret;
    const char *xmlfile = "";
    const char *xslfile = "";
    XalanParsedSource *parsed_source = 0;
    XalanCompiledStylesheet *compiled_stylesheet = 0;
    CODE:
    if (sv_isobject(xmlsource) && (SvTYPE(SvRV(xmlsource)) == SVt_PVMG))
    {
        parsed_source = (XalanParsedSource *)SvIV((SV*)SvRV( xmlsource ));
    } else {
        xmlfile = (const char *)SvPV(xmlsource, PL_na);
    }

    if (sv_isobject(stylesheet) && (SvTYPE(SvRV(stylesheet)) == SVt_PVMG))
    {
        compiled_stylesheet = (XalanCompiledStylesheet *)SvIV((SV*)SvRV( stylesheet ));
        ret = parsed_source ? 
        self->transform(*parsed_source, compiled_stylesheet, outfile) :
        self->transform(xmlfile, compiled_stylesheet, outfile);
    } else if (SvOK(stylesheet)) {
        xslfile = (const char *)SvPV(stylesheet,PL_na);
        ret = parsed_source ? 
        self->transform(*parsed_source, xslfile, outfile) :
        self->transform(xmlfile, xslfile, outfile);
    } else {
        if (parsed_source) {
            warn("Stylesheet is undef, accepting XML source with XSLT processing instruction\n ");
            XSRETURN_UNDEF;
        }
        ret = self->transform(xmlfile, outfile);
    }

    if (ret == 0) 
        XSRETURN_YES;
    else
        XSRETURN_UNDEF;

SV*
transform_to_data(self, xmlsource, stylesheet)
    XalanTransformer *self
    SV *xmlsource
    SV *stylesheet
    PREINIT:
    int ret;
    const char *xmlfile = "";
    const char *xslfile = "";
    XalanParsedSource *parsed_source = 0;
    XalanCompiledStylesheet *compiled_stylesheet = 0;
    CODE:
    ostrstream theOutputStream;

    if (sv_isobject(xmlsource) && (SvTYPE(SvRV(xmlsource)) == SVt_PVMG))
    {
        parsed_source = (XalanParsedSource *)SvIV((SV*)SvRV( xmlsource ));
    } else {
        xmlfile = (const char *)SvPV(xmlsource, PL_na);
    }

    if (sv_isobject(stylesheet) && (SvTYPE(SvRV(stylesheet)) == SVt_PVMG))
    {
        compiled_stylesheet = (XalanCompiledStylesheet *)SvIV((SV*)SvRV( stylesheet ));
        ret = parsed_source ? 
        self->transform(*parsed_source, compiled_stylesheet, 
            theOutputStream)
        :
        self->transform(xmlfile, compiled_stylesheet, 
            theOutputStream);

    } else if (SvOK(stylesheet)) {

        xslfile = (const char *)SvPV(stylesheet,PL_na);
        ret = parsed_source ? 
        self->transform(*parsed_source, xslfile, 
            theOutputStream)
        :
        self->transform(xmlfile, xslfile, 
            theOutputStream);
    } else {
        if (parsed_source) {
            warn("Stylesheet is undef, accepting XML source with XSLT processing instruction\n ");
            XSRETURN_UNDEF;
        }
        ret = self->transform(xmlfile, theOutputStream);

    }
    theOutputStream << '\0';
    //PerlIO_puts((PerlIO*)IoIFP( sv_2io(fh) ), theOutputStream.str());
    if (ret == 0) 
        RETVAL = newSVpv(theOutputStream.str(), 0);
    else 
        XSRETURN_UNDEF;
    OUTPUT:
    RETVAL

void
set_stylesheet_param(self, key, val)
    XalanTransformer *self
    const char *key
    const char *val
    PREINIT:
    int ret;
    CODE:
    self->setStylesheetParam(
        XalanDOMString(key), XalanDOMString(val));

void
END()
    CODE:
    //PerlIO_stdoutf("Entering END()\n");
    XalanTransformer::terminate();
    // Call the static terminator for Xerces.
    XMLPlatformUtils::Terminate();

const char*
XalanTransformer::getLastError()
 
int
destroy_stylesheet(self, compiled_stylesheet)
    XalanTransformer *self
    const XalanCompiledStylesheet *compiled_stylesheet
    PREINIT:
    int ret;
    CODE:
    ret = self->destroyStylesheet(compiled_stylesheet);
    if (ret == 0)
        XSRETURN_YES;
    else 
        XSRETURN_UNDEF;

int
destroy_parsed_source(self, parsed_source)
    XalanTransformer *self
    const XalanParsedSource *parsed_source
    PREINIT:
    int ret;
    CODE:
    ret = self->destroyParsedSource(parsed_source);
    if (ret == 0)
        XSRETURN_YES;
    else 
        XSRETURN_UNDEF;

void
install_external_function(self, nspace, func_name, func_handler)
    XalanTransformer *self
    const char *nspace
    const char *func_name
    SV *func_handler
    CODE:
    self->installExternalFunction(XalanDOMString(nspace), XalanDOMString(func_name), UserDefinedFunction(func_name, func_handler));

void
uninstall_external_function(self, nspace, func_name)
	XalanTransformer *self
	const char *nspace
	const char *func_name
	CODE:
	self->uninstallExternalFunction(XalanDOMString(nspace), XalanDOMString(func_name));

void
XalanTransformer::DESTROY()

