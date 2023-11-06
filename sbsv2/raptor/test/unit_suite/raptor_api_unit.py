#
# Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description: 
# raptor_api_unit module

import generic_path
import raptor
import raptor_api
import unittest
import raptor_tests

class TestRaptorApi(unittest.TestCase):
			
	def testContext(self):
		api = raptor_api.Context()
		
	def testContextInitialiser(self):
		r = raptor.Raptor()
		api = raptor_api.Context(r)
		
	def testAliases(self):
		r = raptor.Raptor()
		r.cache.Load( generic_path.Join(r.home, "test", "configapi", "api.xml") )

		api = raptor_api.Context(r)
	
		aliases = api.getaliases() # type == ""
		self.assertEqual(len(aliases), 4)
		self.assertEqual(set(["alias_A","alias_B","s1","s2"]),
							 set(a.name for a in aliases))
		
		aliaslist = [a.name for a in aliases] # verify that the list is sorted
		self.assertEqual(["alias_A","alias_B","s1","s2"], aliaslist)
		
		aliases = api.getaliases(raptor_api.ALL) # ignore type
		self.assertEqual(len(aliases), 6)
		
		aliases = api.getaliases("X") # type == "X"
		self.assertEqual(len(aliases), 1)
		self.assertEqual(aliases[0].name, "alias_D")
		self.assertEqual(aliases[0].meaning, "a.b.c.d")
	
	def testConfig(self):
		r = raptor.Raptor()
		r.cache.Load( generic_path.Join(r.home, "test", "configapi", "api.xml") )

		api = raptor_api.Context(r)
		
		if r.filesystem == "unix":
			path = "/home/raptor/foo/bar"
		else:
			path = "C:/home/raptor/foo/bar"
			
		config = api.getconfig("buildme")
		self.assertEqual(config.meaning, "buildme")
		self.assertEqual(config.outputpath, path)
		
		# metadata
				
		metadatamacros = [str(x.name+"="+x.value) if x.value else str(x.name) for x in config.metadata.platmacros]
		metadatamacros.sort()
		results = ['SBSV2=_____SBSV2', '__GNUC__=3']
		results.sort()
		self.assertEqual(metadatamacros, results)
		
		includepaths = [str(x.path) for x in config.metadata.includepaths]
		includepaths.sort()
		expected_includepaths = [raptor_tests.ReplaceEnvs("$(EPOCROOT)/epoc32/include/variant"), 
								raptor_tests.ReplaceEnvs("$(EPOCROOT)/epoc32/include"), "."]
		expected_includepaths.sort()
		self.assertEqual(includepaths, expected_includepaths)
		
		preincludefile = str(config.metadata.preincludeheader.file)
		self.assertEqual(preincludefile, raptor_tests.ReplaceEnvs("$(EPOCROOT)/epoc32/include/variant/Symbian_OS.hrh"))
		
		# build
		
		sourcemacros = [str(x.name+"="+x.value) if x.value else str(x.name) for x in config.build.sourcemacros]
		results = ['__BBB__', '__AAA__', '__DDD__=first_value', '__CCC__', '__DDD__=second_value']
		self.assertEqual(sourcemacros, results)
		
		compilerpreincludefile = str(config.build.compilerpreincludeheader.file)
		self.assertEqual(compilerpreincludefile, raptor_tests.ReplaceEnvs("$(EPOCROOT)/epoc32/include/preinclude.h"))

		expectedtypes = ["one", "two"]
		expectedtypes.sort()
		types = [t.name for t in config.build.targettypes]
		types.sort()
		self.assertEqual(types, expectedtypes)

		# general

		config = api.getconfig("buildme.foo")
		self.assertEqual(config.meaning, "buildme.foo")
		self.assertEqual(config.outputpath, path)
		
		config = api.getconfig("s1")
		self.assertEqual(config.meaning, "buildme.foo")
		self.assertEqual(config.outputpath, path)
		
		config = api.getconfig("s2.product_A")
		self.assertEqual(config.meaning, "buildme.foo.bar.product_A")
		self.assertEqual(config.outputpath, path)
		
	def testProducts(self):
		r = raptor.Raptor()
		r.cache.Load( generic_path.Join(r.home, "test", "configapi", "api.xml") )

		api = raptor_api.Context(r)
		
		products = api.getproducts() # type == "product"
		self.assertEqual(len(products), 2)
		self.assertEqual(set(["product_A","product_C"]),
							 set(p.name for p in products))
		productlist = [p.name for p in products] # verify that the list is sorted
		self.assertEqual(["product_A","product_C"], productlist)
		
# run all the tests

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.name = "raptor_api_unit"

	tests = unittest.makeSuite(TestRaptorApi)
	result = unittest.TextTestRunner(verbosity=2).run(tests)

	if result.wasSuccessful():
		t.result = SmokeTest.PASS
	else:
		t.result = SmokeTest.FAIL

	return t
