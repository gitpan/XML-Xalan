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

/* 
 * XalanTransformer/XalanTransformerOutputStream.cpp: 
 * returns: number of bytes written
 * void *buffer contains the data to be written,
 * unsigned long buffer_length contains the buffer's length
 * void *out_handle is the filehandle
 */

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

int
transform_to_handler(self, xmlfile, xslfile, out_handle, out_handler, ...)
    XalanTransformer *self
    const char *xmlfile
    const char *xslfile
    SV *out_handle
    SV *out_handler
    PREINIT:
    int status;
    char *key;
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
        status = self->transform(
            xmlfile, xslfile, (SV*)out_handle, 
            out_handler_internal, flush_handler_internal);
    } else {
        status = self->transform(
            xmlfile, xslfile, (SV*)out_handle, 
            out_handler_internal);
    }
    hv_delete(out_handler_mapping, key, len, G_DISCARD);
    if (status == 0) 
        XSRETURN_YES;
    else
        XSRETURN_UNDEF;

int
transform_to_file(self, xmlfile, xslfile, outfile)
    XalanTransformer *self
    const char *xmlfile
    const char *xslfile
    const char *outfile
    PREINIT:
    int ret;
    CODE:
    ret = self->transform(xmlfile, xslfile, outfile);
    if (ret == 0) 
        XSRETURN_YES;
    else
        XSRETURN_UNDEF;

SV*
transform_to_data(self, xmlfile, xslfile)
    XalanTransformer *self
    const char *xmlfile
    const char *xslfile
    PREINIT:
    int ret;
    CODE:
    ostrstream theOutputStream;
    ret = self->transform(xmlfile, xslfile, theOutputStream);
    theOutputStream << '\0';
    //PerlIO_puts((PerlIO*)IoIFP( sv_2io(fh) ), theOutputStream.str());
    if (ret == 0) 
        RETVAL = newSVpv(theOutputStream.str(), 0);
    else 
        XSRETURN_UNDEF;
    OUTPUT:
    RETVAL

void
END()
    CODE:
    //PerlIO_stdoutf("Entering END()\n");
    XalanTransformer::terminate();
    // Call the static terminator for Xerces.
    XMLPlatformUtils::Terminate();


const char*
XalanTransformer::getLastError()
 
void
XalanTransformer::DESTROY()
