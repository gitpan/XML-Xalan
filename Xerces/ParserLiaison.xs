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

//#include <DOM_Support/DOMSupportDefault.hpp>
#include <XercesParserLiaison/XercesParserLiaison.hpp>
#include <XercesParserLiaison/XercesDOMSupport.hpp>
#include <dom/DOM_Node.hpp>

typedef struct swig_type_info {
  char  *name;                 
  void *(*converter)(void *);
  char  *str;
  struct swig_type_info  *next;
  struct swig_type_info  *prev;
} swig_type_info;

swig_type_info *
SWIG_TypeCheck(char *c, swig_type_info *ty)
{
  swig_type_info *s;
  if (!ty) return 0;        /* Void pointer */
  s = ty->next;             /* First element always just a name */
  while (s) {
    if (strcmp(s->name,c) == 0) {
      if (s == ty->next) return s;
      /* Move s to the top of the linked list */
      s->prev->next = s->next;
      if (s->next) {
    s->next->prev = s->prev;
      }
      /* Insert s as second element in the list */
      s->next = ty->next;
      if (ty->next) ty->next->prev = s;
      ty->next = s;
      return s;
    }
    s = s->next;
  }
  return 0;
}

/* Cast a pointer (needed for C++ inheritance */
void * 
SWIG_TypeCast(swig_type_info *ty, void *ptr) 
{
  if ((!ty) || (!ty->converter)) return ptr;
  return (*ty->converter)(ptr);
}

int
_SWIG_ConvertPtr(SV *sv, void **ptr, swig_type_info *_t)
{
  char *_c;
  swig_type_info *tc;
  IV   tmp;

  /* If magical, apply more magic */
  if (SvGMAGICAL(sv))
    mg_get(sv);

  /* Check to see if this is an object */
  if (sv_isobject(sv)) {
    SV *tsv = (SV*) SvRV(sv);
    if ((SvTYPE(tsv) == SVt_PVHV)) {
      MAGIC *mg;
      if (SvMAGICAL(tsv)) {
    mg = mg_find(tsv,'P');
    if (mg) {
      SV *rsv = mg->mg_obj;
      if (sv_isobject(rsv)) {
        tmp = SvIV((SV*)SvRV(rsv));
      }
    }
      } else {
    return -1;
      }
    } else {
      tmp = SvIV((SV*)SvRV(sv));
    }
    if (!_t) {
      *(ptr) = (void *) tmp;
      return 0;
    }
  } else if (! SvOK(sv)) {            /* Check for undef */
    *(ptr) = (void *) 0;
    return 0;
  } else if (SvTYPE(sv) == SVt_RV) {  /* Check for NULL pointer */
    *(ptr) = (void *) 0;
    if (!SvROK(sv)) 
      return 0;
    else
      return -1;
  } else {                            /* Don't know what it is */
      *(ptr) = (void *) 0;
      return -1;
  }
  if (_t) {
    /* Now see if the types match */      
    _c = HvNAME(SvSTASH(SvRV(sv)));
    tc = SWIG_TypeCheck(_c,_t);
    if (!tc) {
      *ptr = (void *) tmp;
      return -1;
    }
    *ptr = SWIG_TypeCast(tc,(void *)tmp);
    return 0;
  }
  *ptr = (void *) tmp;
  return 0;
}

DOM_Document*
XS_unpack_DOM_DocumentPtr(SV *rv) {
    DOM_Document *dom;
    swig_type_info _t[] = 
    {{"XML::Xerces::DOM_Document", 0, "DOM_Document *"},{"XML::Xerces::DOM_Document"},{0}};
    _SWIG_ConvertPtr(rv, (void **) &dom, _t);
    return dom;
}

void XS_pack_DOM_DocumentPtr(SV *st, DOM_Document *dom) {
}

MODULE = XML::Xerces::ParserLiaison    PACKAGE = XML::Xerces::_ParserLiaison
PROTOTYPES: DISABLE

XercesParserLiaison*
new(CLASS, DOMSupp)
    char *CLASS
    XercesDOMSupport *DOMSupp
    CODE:
    RETVAL = new XercesParserLiaison((XercesDOMSupport &)*DOMSupp);
    OUTPUT:
    RETVAL

XalanDocument*
create_document(self, DOM)
    XercesParserLiaison *self
    DOM_Document *DOM
    PREINIT:
    char *CLASS = "XML::Xalan::Document";
    CODE:
    RETVAL = self->createDocument((DOM_Document&)*DOM);
    OUTPUT:
    RETVAL

void
XercesParserLiaison::DESTROY()

MODULE = XML::Xerces::ParserLiaison    PACKAGE = XML::Xerces::DOMSupport
PROTOTYPES: DISABLE

XercesDOMSupport*
XercesDOMSupport::new()

void
XercesDOMSupport::DESTROY()
