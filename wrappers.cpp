/* 

   Copyright (c) 2001  Edwin Pratomo

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file,
   with the exception that it cannot be placed on a CD-ROM or similar media
   for commercial distribution without the prior approval of the author.

*/

#include "Xalan.hpp"


// wrapper for XObjectFactory

Xalan_XObjectFactory::Xalan_XObjectFactory(
    XPathExecutionContext *xpath_exec_ctx_ptr):
    m_execution_context(xpath_exec_ctx_ptr) {
}

Xalan_XObjectFactory::~Xalan_XObjectFactory() {
    // don't: delete m_execution_context;
    // cerr << "XObjectFactory destroyed\n";
}

XObject* Xalan_XObjectFactory::create_nodeset(
        unsigned int num,
        SV**  sv_node
    ) {
    typedef XPathExecutionContext::BorrowReturnMutableNodeRefList BorrowReturnMutableNodeRefList;
    BorrowReturnMutableNodeRefList result(*m_execution_context);

    for (unsigned int i = 0; i < num; i++) {
        XalanNode *the_node = (XalanNode*) SvIV(*(sv_node + i));
        //stupid mistake: result->addNode(the_node + i);
        result->addNode(the_node);
    }   
    XObjectPtr xobj_ptr = m_execution_context->getXObjectFactory().createNodeSet(result);
    return xobj_ptr.get()->clone(); // caller is responsible to free this
}

XObject* Xalan_XObjectFactory::create_boolean(bool val) {
    XObjectPtr xobj_ptr = m_execution_context->getXObjectFactory().createBoolean(val);
    return xobj_ptr.get()->clone();
}

XObject* Xalan_XObjectFactory::create_number(double val) {
    XObjectPtr xobj_ptr = m_execution_context->getXObjectFactory().createNumber(val);
    return xobj_ptr.get()->clone();
}

XObject* Xalan_XObjectFactory::create_string(char* val) {
    XObjectPtr xobj_ptr = m_execution_context->getXObjectFactory().createString(XalanDOMString(val));
    //returning the XObject* directly for later reconstructing into XObjectPtr always fail:
    //return xobj_ptr.get();
    return xobj_ptr.get()->clone();
}

XObject* Xalan_XObjectFactory::create_scalar(SV* sv) {
    XSv* const theXSv = new XSv(sv);
    theXSv->setFactory(&m_execution_context->getXObjectFactory());
    XObjectPtr xobj_ptr(theXSv);
    return xobj_ptr.get()->clone();
}

/*

unimplemented yet:
XObject* Xalan_XObjectFactory::create_result_tree_frag() {

    }
*/

