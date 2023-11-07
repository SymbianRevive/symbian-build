@rem
@rem Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
@rem All rights reserved.
@rem This component and the accompanying materials are made available
@rem under the terms of the License "Eclipse Public License v1.0"
@rem which accompanies this distribution, and is available
@rem at the URL "http://www.eclipse.org/legal/epl-v10.html".
@rem
@rem Initial Contributors:
@rem Nokia Corporation - initial contribution.
@rem
@rem Contributors:
@rem
@rem Description:
@rem
rem Compilations needed in order to compile sistools test code
rem =========================================================  
 
rem rtestwrapper.h (and possibly more) in commonutils is needed to compile 
rem swi test code
call cd %SECURITYSOURCEDIR%\commonutils\group
call bldmake bldfiles 
call abld test build winscw udeb

rem swi is needed for tests: testdumpsis, tinterpretsis, tinterpretsisinteg  
rem (note that if swi is compiled after sistools compile errors occur so 
rem it is compiled here instead)
call cd %SECURITYSOURCEDIR%\swi\group
call bldmake bldfiles 
call abld test build winscw udeb

call cd %SECURITYSOURCEDIR%\swi\sistools\group
call bldmake bldfiles 
call abld test build winscw udeb


rem Additional compilations needed to run sistools tests
rem =====================================================
 
rem Needed for execution of tests:  testsignsis, tinterpretsisinteg and tinterpretsis
call cd %SECURITYSOURCEDIR%\installtestframework\testcertificates\group
call bldmake bldfiles 
call abld test build winscw udeb

rem Necessary for test testmakesis.pl  
call cd %SECURITYSOURCEDIR%\testframework\group
call bldmake bldfiles 
call abld test build winscw udeb


 
 
 


 
 
