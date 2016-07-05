//==========
// This file is derived from boost/config/select_stdlib_config.hpp
//
//  (C) Copyright Boost.org 2001. Permission to copy, use, modify, sell and
//  distribute this software is granted provided this copyright notice appears
//  in all copies. This software is provided "as is" without express or implied
//  warranty, and with no claim as to its suitability for any purpose.

//  See http://www.boost.org for most recent version.
//==========

// locate which std lib we are using and define CROSS_STDLIB_CONFIG as needed:

// we need to include a std lib header here in order to detect which
// library is in use, use <utility> as it's about the smallest
// of the std lib headers - do not rely on this header being included -
// users can short-circuit this header if they know whose std lib
// they are using.

// See CVS for full change history. (Simplifies source mirrors, merging, and the clincher was Boost made the same decision!)

#include <utility>

// NB: the include files listed here only exist for platforms we have used at ADInstruments!

#if defined(__SGI_STL_PORT) || defined(_STLPORT_VERSION)
// STLPort library; this _must_ come first, otherwise since
// STLport typically sits on top of some other library, we
// can end up detecting that first rather than STLport:
#  define CROSS_STDLIB_CONFIG "CrossPlatform/config/stdlib/stlport.hpp"

#elif defined(__LIBCOMO__)
// Commeau STL:
#define CROSS_STDLIB_CONFIG "CrossPlatform/config/stdlib/libcomo.hpp"

#elif defined(__STD_RWCOMPILER_H__) || defined(_RWSTD_VER)
// Rogue Wave library:
#  define CROSS_STDLIB_CONFIG "CrossPlatform/config/stdlib/roguewave.hpp"

#elif defined(__GLIBCPP__) || defined(__GLIBCXX__)
// GNU libstdc++ 3 (and 4?)
#  define CROSS_STDLIB_CONFIG "CrossPlatform/config/stdlib/libstdcpp3.hpp"

#elif defined(__STL_CONFIG_H)
// generic SGI STL
#  define CROSS_STDLIB_CONFIG "CrossPlatform/config/stdlib/sgi.hpp"

#elif defined(__MSL_CPP__)
// MSL standard lib:
#  define CROSS_STDLIB_CONFIG "CrossPlatform/config/stdlib/msl.hpp"

#elif defined(__IBMCPP__)
// take the default VACPP std lib
#  define CROSS_STDLIB_CONFIG "CrossPlatform/config/stdlib/vacpp.hpp"

#elif defined(MSIPL_COMPILE_H)
// Modena C++ standard library
#  define CROSS_STDLIB_CONFIG "CrossPlatform/config/stdlib/modena.hpp"

#elif (defined(_YVALS) && !defined(__IBMCPP__)) || defined(_CPPLIB_VER)
// Dinkumware Library (this has to appear after any possible replacement libraries):
//#  define BOOST_STDLIB_CONFIG "boost/config/stdlib/dinkumware.hpp"

#elif defined (CROSS_ASSERT_CONFIG)
// this must come last - generate an error if we don't
// recognise the library:
#  error "Unknown standard library."

#endif

