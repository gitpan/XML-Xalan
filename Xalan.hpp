/* 

   Copyright (c) 2001  Edwin Pratomo

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file,
   with the exception that it cannot be placed on a CD-ROM or similar media
   for commercial distribution without the prior approval of the author.

*/

#ifndef __XML_XALAN_HPP
#define __XML_XALAN_HPP

#include <Include/PlatformDefinitions.hpp>

#if defined(XALAN_OLD_STREAM_HEADERS)
    #include <strstream.h>
#else
    #include <strstream>
#endif 

#include <sax/SAXException.hpp>
#include <sax/DTDHandler.hpp>
#include <sax2/ContentHandler.hpp>
#include <sax2/LexicalHandler.hpp>
#include <XalanDOM/XalanDOMException.hpp>
#include <XalanDOM/XalanDocumentType.hpp>
#include <XalanDOM/XalanElement.hpp>
#include <XalanDOM/XalanAttr.hpp>
#include <XalanDOM/XalanCDATASection.hpp>
#include <XalanDOM/XalanEntity.hpp>
#include <XalanDOM/XalanProcessingInstruction.hpp>
#include <XalanDOM/XalanDocumentFragment.hpp>
#include <XalanDOM/XalanNotation.hpp>

#include <XalanDOM/XalanDOMImplementation.hpp>
#include <XalanDOM/XalanNodeList.hpp>
#include <XalanDOM/XalanNamedNodeMap.hpp>

#include <util/PlatformUtils.hpp>
#include <PlatformSupport/DOMStringPrintWriter.hpp>
#include <PlatformSupport/DOMStringHelper.hpp>
#include <PlatformSupport/AttributesImpl.hpp>

#include <XalanSourceTree/XalanSourceTreeDOMSupport.hpp>
#include <XalanSourceTree/XalanSourceTreeParserLiaison.hpp>

#include <XalanTransformer/XalanTransformer.hpp>
#include <XalanTransformer/XalanCompiledStylesheetDefault.hpp>
#include <XalanTransformer/XalanDefaultDocumentBuilder.hpp>

#include <XPath/Function.hpp>
#include <XPath/XObjectFactoryDefault.hpp>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#ifdef _EXPERIMENTAL
    #include "XSv.hpp"
#endif


class XALAN_PLATFORM_EXPORT Xalan_XObjectFactory
{
public:
    Xalan_XObjectFactory(
        XPathExecutionContext *xpath_exec_ctx_ptr
        );

    ~Xalan_XObjectFactory();

    XObject* create_nodeset(
        unsigned int num,
        SV**  sv_node
    );

    XObject* create_boolean(bool val);

    XObject* create_number(double val);

    XObject* create_string(char* val);

    XObject* create_scalar(SV* sv);

/*
    unimplemented yet:
    XObject* create_result_tree_frag();
*/

private:
    XPathExecutionContext *m_execution_context; // _address_ of execution context who created this Xalan_XObjectFactory object
};


#endif

