/* 
   $Id: Xalan.xs,v 1.2 2002/04/20 06:37:51 edpratomo Exp $

   Copyright (c) 2001-2002  Edwin Pratomo

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file,
   with the exception that it cannot be placed on a CD-ROM or similar media
   for commercial distribution without the prior approval of the author.

*/

#include "Xalan.hpp"

#ifdef _USE_UTF8
#define DOMSTRING_2CHAR(result, domstring) \
    { \
        unsigned int j; \
        for (j = 0; j < domstring.length(); j++) \
        { \
            if (domstring[j] > 0x80) \
                uv_to_utf8((U8*)(result + j), domstring[j]); \
            else \
                *(result + j) = domstring[j]; \
        } \
        *(result + j) = '\0'; \
    }
#else
#define DOMSTRING_2CHAR(result, domstring) \
    { \
        unsigned int j = 0; \
        result = new char[domstring.length() + 1]; \
        for (j = 0; j < domstring.length(); j++) \
            *(result + j) = domstring[j]; \
        *(result + j) = '\0'; \
    }
#endif

#define BLESS_CORRECT_NODE_CLASS(sv, node) \
    switch (node->getNodeType()) { \
        case XalanNode::ELEMENT_NODE: \
            sv_setref_pv( sv, "XML::Xalan::DOM::Element", (void*)node ); \
            break; \
        case XalanNode::ATTRIBUTE_NODE: \
            sv_setref_pv( sv, "XML::Xalan::DOM::Attr", (void*)node ); \
            break; \
        case XalanNode::TEXT_NODE: \
            sv_setref_pv( sv, "XML::Xalan::DOM::Text", (void*)node ); \
            break; \
        case XalanNode::CDATA_SECTION_NODE: \
            sv_setref_pv( sv, "XML::Xalan::DOM::CDATASection", (void*)node ); \
            break; \
        case XalanNode::ENTITY_REFERENCE_NODE: \
            sv_setref_pv( sv, "XML::Xalan::DOM::EntityReference", (void*)node ); \
            break; \
        case XalanNode::ENTITY_NODE: \
            sv_setref_pv( sv, "XML::Xalan::DOM::Entity", (void*)node ); \
            break; \
        case XalanNode::PROCESSING_INSTRUCTION_NODE: \
            sv_setref_pv( sv, "XML::Xalan::DOM::ProcessingInstruction", (void*)node ); \
            break; \
        case XalanNode::COMMENT_NODE: \
            sv_setref_pv( sv, "XML::Xalan::DOM::Comment", (void*)node ); \
            break; \
        case XalanNode::DOCUMENT_NODE: \
            sv_setref_pv( sv, "XML::Xalan::DOM::Document", (void*)node ); \
            break; \
        case XalanNode::DOCUMENT_TYPE_NODE: \
            sv_setref_pv( sv, "XML::Xalan::DOM::DocumentType", (void*)node ); \
            break; \
        case XalanNode::DOCUMENT_FRAGMENT_NODE: \
            sv_setref_pv( sv, "XML::Xalan::DOM::DocumentFragment", (void*)node ); \
            break; \
        case XalanNode::NOTATION_NODE: \
            sv_setref_pv( sv, "XML::Xalan::DOM::Notation", (void*)node ); \
            break; \
        case XalanNode::UNKNOWN_NODE: \
            sv_setref_pv( sv, "XML::Xalan::DOM::Node", (void*)node ); \
            break; \
    }

#define TRANSLATE_DOMEXCEPTION_CODE(mesg, code) \
    switch (code) { \
        case XalanDOMException::INDEX_SIZE_ERR: \
            mesg = "INDEX_SIZE_ERR"; \
            break; \
        case XalanDOMException::DOMSTRING_SIZE_ERR: \
            mesg = "DOMSTRING_SIZE_ERR"; \
            break; \
        case XalanDOMException::HIERARCHY_REQUEST_ERR: \
            mesg = "HIERARCHY_REQUEST_ERR"; \
            break; \
        case XalanDOMException::WRONG_DOCUMENT_ERR: \
            mesg = "WRONG_DOCUMENT_ERR"; \
            break; \
        case XalanDOMException::INVALID_CHARACTER_ERR: \
            mesg = "INVALID_CHARACTER_ERR"; \
            break; \
        case XalanDOMException::NO_DATA_ALLOWED_ERR: \
            mesg = "NO_DATA_ALLOWED_ERR"; \
            break; \
        case XalanDOMException::NO_MODIFICATION_ALLOWED_ERR: \
            mesg = "NO_MODIFICATION_ALLOWED_ERR"; \
            break; \
        case XalanDOMException::NOT_FOUND_ERR: \
            mesg = "NOT_FOUND_ERR"; \
            break; \
        case XalanDOMException::NOT_SUPPORTED_ERR: \
            mesg = "NOT_SUPPORTED_ERR"; \
            break; \
        case XalanDOMException::INUSE_ATTRIBUTE_ERR: \
            mesg = "INUSE_ATTRIBUTE_ERR"; \
            break; \
        case XalanDOMException::INVALID_STATE_ERR: \
            mesg = "INVALID_STATE_ERR"; \
            break; \
        case XalanDOMException::SYNTAX_ERR: \
            mesg = "SYNTAX_ERR"; \
            break; \
        case XalanDOMException::INVALID_MODIFICATION_ERR: \
            mesg = "INVALID_MODIFICATION_ERR"; \
            break; \
        case XalanDOMException::NAMESPACE_ERR: \
            mesg = "NAMESPACE_ERR"; \
            break; \
        case XalanDOMException::INVALID_ACCESS_ERR: \
            mesg = "INVALID_ACCESS_ERR"; \
            break; \
        case XalanDOMException::UNKNOWN_ERR: \
            mesg = "UNKNOWN_ERR"; \
            break; \
        case XalanDOMException::TRANSCODING_ERR: \
            mesg = "TRANSCODING_ERR"; \
            break; \
        default: \
            mesg = "Unhandled exception"; \
    }

static SV *global_flush_handler = (SV*)NULL;
static HV *out_handler_mapping = (HV*)NULL;

/* 
 * XalanTransformer/XalanTransformerOutputStream.cpp: 
 * returns: number of bytes written
 * void *buffer contains the data to be written,
 * unsigned long buffer_length contains the buffer's length
 * void *out_handle is the filehandle
 */

/* several notes.. */
/*
    ./XPath/XPathExecutionContext.hpp:      
    typedef std::vector<XObjectPtr> XObjectArgVectorType;
*/

/*
    ./XalanDOM/XalanDOMString.hpp:
    // UTF-16 character...
    typedef unsigned short  XalanDOMChar;
*/

//unsigned long
CallbackSizeType
out_handler_internal(
    const char *buffer, 
//    unsigned long buffer_length, 
    CallbackSizeType buffer_length, 
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

class Xalan_ExtensionFunction : public Function
{
public:
    Xalan_ExtensionFunction(
        const char* func_name, 
        SV *func_handler,
        bool auto_cast = 0,
        bool with_context = 0):m_auto_cast(auto_cast),m_with_context(auto_cast ? 1 : with_context)
    {
        m_func_name = new char[strlen(func_name) + 1];
        strcpy(m_func_name, func_name);
        m_func_handler = newSVsv(func_handler);
    }

    ~Xalan_ExtensionFunction()
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
//            int                             opPos,
            const XObjectArgVectorType&     args,
            const Locator*                  locator) const
    {
        dSP;

        unsigned int i, j;
        //const XObjectPtr *xobj;
        XObjectPtr retxobj;
        int cnt;
        SV *result, *sv_execution_context, *sv_context, *sv_arg;
        char *str, *temp_str;
        STRLEN len;
        XalanDOMString tmpDOMString;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        if (m_with_context) {
            sv_execution_context = sv_newmortal();
            sv_context = sv_newmortal();
            sv_setref_pv( sv_execution_context, "XML::Xalan::ExecutionContext::XPath", (void*)&executionContext );
            BLESS_CORRECT_NODE_CLASS(sv_context, context)
            XPUSHs(sv_execution_context);
            XPUSHs(sv_context);
        } 

        for (i = 0; i < args.size(); i++) {
            //PerlIO_printf(PerlIO_stderr(), "%s: arg type: %d\n", m_func_name, args[i]->getType());

            if (m_with_context) {
                sv_arg = sv_newmortal();
                const XObject::eObjectType theType = args[i]->getType();
                switch(theType)
                {
                    case XObject::eTypeBoolean:
                        if (m_auto_cast)
                            sv_setiv(sv_arg, args[i].get()->boolean());
                        else 
                            sv_setref_pv( sv_arg, "XML::Xalan::Boolean", (void*)args[i].get() );
                        break;
                    case XObject::eTypeNull:
                        sv_setsv(sv_arg, &PL_sv_undef);
                        break;
                    case XObject::eTypeString:
                    case XObject::eTypeStringReference:
                    case XObject::eTypeStringAdapter:
                    case XObject::eTypeStringCached:
                    case XObject::eTypeXTokenStringAdapter:
                        if (m_auto_cast) {
                            char *temp_str;
                            DOMSTRING_2CHAR(temp_str, args[i].get()->str());
                            sv_setpv(sv_arg, temp_str);
#ifdef _USE_UTF8
                            SvUTF8_on(sv_arg);
#endif
                            delete temp_str;
                        } else {
                            sv_setref_pv( sv_arg, "XML::Xalan::String", (void*)args[i].get() );
                        }
                        break;
                    case XObject::eTypeNumber:
                    case XObject::eTypeXTokenNumberAdapter:
                        if (m_auto_cast) 
                            sv_setnv(sv_arg, args[i].get()->num());
                        else 
                            sv_setref_pv( sv_arg, "XML::Xalan::Number", (void*)args[i].get() );
                        break;
                    case XObject::eTypeNodeSet:
                        sv_setref_pv( sv_arg, "XML::Xalan::NodeSet", (void*)args[i].get() );
                        break;
                    case XObject::eTypeUserDefined:
                        sv_setref_pv( sv_arg, "XML::Xalan::Scalar", (void*)args[i].get() );
                        break;
                    case XObject::eTypeResultTreeFrag:
                        sv_setref_pv( sv_arg, "XML::Xalan::ResultTreeFragment", (void*)args[i].get() );
                        break;
                    default:
                        croak("Unknown XObject type");
                        break;
                }
                XPUSHs(sv_arg);
            } else {
                // always stringify args
                tmpDOMString = args[i]->str();
                temp_str = new char[tmpDOMString.length() + 1];
                for (j = 0; j < tmpDOMString.length(); j++) {
                    *(temp_str + j) = tmpDOMString[j];
                }
                XPUSHs(sv_2mortal( newSVpv(temp_str, tmpDOMString.length()) ));
                delete temp_str;
            }
        }

        PUTBACK;

        cnt = perl_call_sv(m_func_handler, G_SCALAR | G_EVAL);

        SPAGAIN;

        if (SvTRUE(ERRSV)) {
            STRLEN n_a;
            executionContext.error(SvPV(ERRSV, n_a), context);
            POPs ;
            goto XALAN_LEAVE;
        } 

        if (cnt != 1)
            executionContext.error("Callback must return a scalar!", context);

        result = POPs;    

        if (!SvOK(result)) {
            retxobj = executionContext.getXObjectFactory().createNull();
            goto XALAN_LEAVE;
            //executionContext.error("Failed callback!", context);
        }

        // check the returned value
        if (m_with_context) {
            if (sv_isobject(result) && (SvTYPE(SvRV(result)) == SVt_PVMG)
                && (sv_isa(result, "XML::Xalan::XObject") || 
                    sv_derived_from(result, "XML::Xalan::XObject")
                    )
                ) {

                XObject *tmp_xobj = (XObject*)SvIV((SV*)SvRV( result ));

                // should add sanity check here .. how??
                // executionContext.error("Invalid return value!", context);

                // create an XObjectPtr which now takes care of tmp_xobj,
                // and assign it to the retval
                retxobj = *(new XObjectPtr(tmp_xobj));

            } else {
                warn("Callback must return XML::Xalan::XObject object or derived from it.");
                str = SvPV(result, len);
                retxobj = executionContext.getXObjectFactory().createString(XalanDOMString( str ));
            }
        } else {
            if (sv_isobject(result)) {
                warn("Can't return a blessed object.");
                //XObject *tmp_result = new XSv(result);
                executionContext.error("Failed callback!", context);
            } else {
                str = SvPV(result, len);
                retxobj = executionContext.getXObjectFactory().createString(XalanDOMString( str ));
            }
            // PerlIO_printf(PerlIO_stderr(), "type: %d\n", retxobj->getType());
        }

XALAN_LEAVE:
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
    virtual Xalan_ExtensionFunction*
#endif
    clone() const
    {
        return new Xalan_ExtensionFunction(m_func_name, m_func_handler, m_auto_cast, m_with_context);
    }

protected:
    const XalanDOMString
    getError() const
    {
        return XALAN_STATIC_UCODE_STRING(m_func_name);
    }

private:
    char *m_func_name;
    SV *m_func_handler;
    bool m_auto_cast;
    bool m_with_context;
};

static int is_initialized = 0;

MODULE = XML::Xalan    PACKAGE = XML::Xalan::Transformer
PROTOTYPES: DISABLE

BOOT:
#ifdef DEBUG_XALAN
    PerlIO_printf(PerlIO_stderr(), "Bootstrapping Xalan\n");
#endif
    if (is_initialized == 0) {
        XMLPlatformUtils::Initialize();
        XalanTransformer::initialize();
    } else ++is_initialized;
#ifdef DEBUG_XALAN
    PerlIO_printf(PerlIO_stderr(), "is_initialized: %d\n", is_initialized);
#endif

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
#ifdef DEBUG_XALAN
	PerlIO_printf(PerlIO_stderr(), "Inside terminate()..\n");
#endif DEBUG_XALAN
    /* I don't know why this doesn't work with perl 5.005_03 */
    /* Commented out at this moment seems to cause no harm */
    //XalanTransformer::terminate();
    //XMLPlatformUtils::Terminate();

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
    #if !defined(XALAN_NO_NAMESPACES)
        using std::istrstream;
    #endif
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
    #if !defined(XALAN_NO_NAMESPACES)
        using std::istrstream;
    #endif
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
    DOMStringPrintWriter *resultWriter = 0;
    int ret;
    unsigned int i;
    const char *xmlfile = "";
    const char *xslfile = "";
    XalanParsedSource *parsed_source = 0;
    XalanCompiledStylesheet *compiled_stylesheet = 0;

    CODE:
    XalanDOMString resDOMString, tmpDOMString;
    char *temp_str;
    
    resultWriter = new DOMStringPrintWriter(resDOMString);
    if (!resultWriter) {
        croak("Can't create DOMStringPrintWriter object");
    }   

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
            XSLTResultTarget(resultWriter))
        :
        self->transform(xmlfile, compiled_stylesheet, 
            XSLTResultTarget(resultWriter));

    } else if (SvOK(stylesheet)) {

        xslfile = (const char *)SvPV(stylesheet,PL_na);
        ret = parsed_source ? 
        self->transform(*parsed_source, xslfile, 
            XSLTResultTarget(resultWriter))
        :
        self->transform(xmlfile, xslfile, 
            XSLTResultTarget(resultWriter));
    } else {
        if (parsed_source) {
            warn("Stylesheet is undef, accepting XML source with XSLT processing instruction\n ");
            XSRETURN_UNDEF;
        }
        ret = self->transform(xmlfile,  XSLTResultTarget(resultWriter));

    }
    tmpDOMString = resultWriter->getString();

    temp_str = new char[tmpDOMString.length() + 1];
    for (i = 0; i < tmpDOMString.length(); i++) {
        *(temp_str + i) = tmpDOMString[i];
    }
            
    //PerlIO_printf(PerlIO_stderr(), "Pushing the result onto stack..\n");
    
    if (ret == 0) {
        RETVAL = newSVpv(temp_str, tmpDOMString.length());
        delete temp_str;
        delete resultWriter;
    }
    else {
        delete temp_str;
        delete resultWriter;
        XSRETURN_UNDEF;
    }
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
_install_external_function(self, nspace, func_name, func_handler, auto_cast, with_context)
    XalanTransformer *self
    const char *nspace
    const char *func_name
    SV *func_handler
    bool auto_cast
    bool with_context
    CODE:
    self->installExternalFunction(XalanDOMString(nspace), XalanDOMString(func_name), 
        Xalan_ExtensionFunction(func_name, func_handler, auto_cast, with_context));

void
uninstall_external_function(self, nspace, func_name)
    XalanTransformer *self
    const char *nspace
    const char *func_name
    CODE:
    self->uninstallExternalFunction(XalanDOMString(nspace), XalanDOMString(func_name));

XalanDocumentBuilder*
XalanTransformer::createDocumentBuilder()
    PREINIT:
    char *CLASS = "XML::Xalan::DocumentBuilder";

void
XalanTransformer::destroyDocumentBuilder(doc_builder)
    XalanDocumentBuilder *doc_builder

void
XalanTransformer::DESTROY()


MODULE = XML::Xalan    PACKAGE = XML::Xalan::ParsedSource
PROTOTYPES: DISABLE

XalanDocument*
XalanParsedSource::getDocument()
    PREINIT:
    char *CLASS = "XML::Xalan::DOM::Document";


MODULE = XML::Xalan    PACKAGE = XML::Xalan::DocumentBuilder
PROTOTYPES: DISABLE

XalanDocument*
XalanDocumentBuilder::getDocument()
    PREINIT:
    char *CLASS = "XML::Xalan::DOM::Document";

ContentHandler*
XalanDefaultDocumentBuilder::getContentHandler()
    PREINIT:
    char *CLASS = "XML::Xalan::ContentHandler";

DTDHandler*
XalanDefaultDocumentBuilder::getDTDHandler()
    PREINIT:
    char *CLASS = "XML::Xalan::DTDHandler";

LexicalHandler*
XalanDefaultDocumentBuilder::getLexicalHandler()
    PREINIT:
    char *CLASS = "XML::Xalan::LexicalHandler";

MODULE = XML::Xalan    PACKAGE = XML::Xalan::ContentHandler
PROTOTYPES: DISABLE

XalanSourceTreeContentHandler*
XalanSourceTreeContentHandler::new()

void
XalanSourceTreeContentHandler::startDocument()

void
XalanSourceTreeContentHandler::endDocument()

void
_start_element(self, uri, localname, qname, attributes)
    XalanSourceTreeContentHandler *self
    char *uri
    char *localname
    char *qname
    SV *attributes
    PREINIT:
    I32 keylen;
    HV *attrs, *attr; 
    /* added const qualifier for gcc 2.95 */
    const char *attr_name, *attr_value, *attr_namespace_uri, *attr_prefix, *attr_localname;
    char *attr_type = "";
    HE *attrs_entry = 0;
    SV **val_ptr;
    STRLEN len;
    AttributesImpl xattrs;
    CODE:
    if( SvROK( attributes ) && (SvTYPE(SvRV(attributes)) == SVt_PVHV) )
        attrs = (HV*)SvRV(attributes);
    else {
        warn("XML::Xalan::ContentHandler::_start_element(): attrs was not an HV ref");
        attrs = newHV();
    }

    xattrs.clear();
    hv_iterinit(attrs);
    while (attrs_entry = hv_iternext(attrs)) {
        /* deref an entry */
        attr = (HV*)SvRV(hv_iterval(attrs, attrs_entry));

        /* retrieve values and add them to AttributesImpl object */
        if (hv_exists(attr, "Name", 4)) {
            val_ptr = hv_fetch(attr, "Name", 4, FALSE);
            attr_name = SvOK(*val_ptr) ? SvPV(*val_ptr, len) : "";
        } else 
            attr_name = "";
        if (hv_exists(attr, "Value", 5)) {
            val_ptr = hv_fetch(attr, "Value", 5, FALSE);
            attr_value = SvOK(*val_ptr) ? SvPV(*val_ptr, len) : "";
        } else 
            attr_value = "";
        if (hv_exists(attr, "NamespaceURI", 12)) {
            val_ptr = hv_fetch(attr, "NamespaceURI", 12, FALSE);
            attr_namespace_uri = SvOK(*val_ptr) ? SvPV(*val_ptr, len) : "";
        } else 
            attr_namespace_uri = "";
        if (hv_exists(attr, "Prefix", 6)) {
            val_ptr = hv_fetch(attr, "Prefix", 6, FALSE);
            attr_prefix = SvOK(*val_ptr) ? SvPV(*val_ptr, len) : "";
        } else 
            attr_prefix = "";
        if (hv_exists(attr, "LocalName", 9)) {
            val_ptr = hv_fetch(attr, "LocalName", 9, FALSE);
            attr_localname = SvOK(*val_ptr) ? SvPV(*val_ptr, len) : "";
        } else 
            attr_localname = "";
        
        xattrs.addAttribute(
            c_wstr(XalanDOMString(attr_namespace_uri)),
            c_wstr(XalanDOMString(attr_localname)),
            c_wstr(XalanDOMString(attr_name)),
            c_wstr(XalanDOMString(attr_type)),
            c_wstr(XalanDOMString(attr_value))
        );
    }
    self->startElement(
        c_wstr(XalanDOMString(uri)), c_wstr(XalanDOMString(localname)),
        c_wstr(XalanDOMString(qname)), xattrs);

void
_end_element(self, uri, localname, qname)
    XalanSourceTreeContentHandler *self
    char *uri
    char *localname
    char *qname
    CODE:
    self->endElement(
        c_wstr(XalanDOMString(uri)),
        c_wstr(XalanDOMString(localname)),
        c_wstr(XalanDOMString(qname))
        );

void
_characters(self, chars)
    XalanSourceTreeContentHandler *self
    char *chars
    CODE:
    self->characters(
        c_wstr(XalanDOMString(chars)), 
        strlen(chars));

void
_ignorable_whitespace(self, chars)
    XalanSourceTreeContentHandler *self
    char *chars
    CODE:
    self->ignorableWhitespace(
        c_wstr(XalanDOMString(chars)), 
        strlen(chars));

void
_start_prefix_mapping(self, prefix, uri)
    XalanSourceTreeContentHandler *self
    char *prefix
    char *uri
    CODE:
    self->startPrefixMapping(
        c_wstr(XalanDOMString(prefix)), 
        c_wstr(XalanDOMString(uri)));

void
_end_prefix_mapping(self, prefix)
    XalanSourceTreeContentHandler *self
    char *prefix
    CODE:
    self->endPrefixMapping(
        c_wstr(XalanDOMString(prefix)));

void
_processing_instruction(self, target, data)
    XalanSourceTreeContentHandler *self
    char *target
    char *data
    CODE:
    self->processingInstruction(
        c_wstr(XalanDOMString(target)), 
        c_wstr(XalanDOMString(data)));

void
_skipped_entitiy(self, name)
    XalanSourceTreeContentHandler *self
    char *name
    CODE:
    self->skippedEntity(
        c_wstr(XalanDOMString(name)));
  
MODULE = XML::Xalan    PACKAGE = XML::Xalan::DTDHandler
PROTOTYPES: DISABLE

void
_notation_decl(self, name, public_id, system_id)
    XalanSourceTreeContentHandler *self
    char *name
    char *public_id
    char *system_id
    CODE:
    self->notationDecl(
        c_wstr(XalanDOMString(name)),
        c_wstr(XalanDOMString(public_id)),
        c_wstr(XalanDOMString(system_id)));

void
_unparsed_entitiy_decl(self, name, public_id, system_id, notation_name)
    XalanSourceTreeContentHandler *self
    char *name
    char *public_id
    char *system_id
    char *notation_name
    CODE:
    self->unparsedEntityDecl(
        c_wstr(XalanDOMString(name)),
        c_wstr(XalanDOMString(public_id)),
        c_wstr(XalanDOMString(system_id)),
        c_wstr(XalanDOMString(notation_name)));

MODULE = XML::Xalan    PACKAGE = XML::Xalan::LexicalHandler
PROTOTYPES: DISABLE

void
_start_dtd(self, name, public_id, system_id)
    XalanSourceTreeContentHandler *self
    char *name
    char *public_id
    char *system_id
    CODE:
    self->startDTD(
        c_wstr(XalanDOMString(name)),
        c_wstr(XalanDOMString(public_id)),
        c_wstr(XalanDOMString(system_id)));

void
XalanSourceTreeContentHandler::endDTD()

void
_start_entity(self, name)
    XalanSourceTreeContentHandler *self
    char *name
    CODE:
    self->startEntity(
        c_wstr(XalanDOMString(name)));

void
_end_entity(self, name)
    XalanSourceTreeContentHandler *self
    char *name
    CODE:
    self->startEntity(
        c_wstr(XalanDOMString(name)));

void
XalanSourceTreeContentHandler::startCDATA()

void
XalanSourceTreeContentHandler::endCDATA()

void
_comment(self, chars)
    XalanSourceTreeContentHandler *self
    char *chars
    CODE:
    self->comment(
        c_wstr(XalanDOMString(chars)), 
        strlen(chars));

INCLUDE: xs.xpath
INCLUDE: xs.dom

