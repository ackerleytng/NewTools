Class {
	#name : #EDEmergencyDebuggerTest,
	#superclass : #TestCase,
	#instVars : [
		'ed',
		'session',
		'currentDebuggingAPI',
		'debugAPI',
		'mockDisplayAPI'
	],
	#category : #'Emergency-Debugger-Tests'
}

{ #category : #'methods version' }
EDEmergencyDebuggerTest >> compileMethodVersion: version [
	EDMockObjectForTests
		compile:
			'm: i', version, '
	i = 1 ifTrue:[^1].
	^i + (self m: i - 1)'
]

{ #category : #running }
EDEmergencyDebuggerTest >> configureDebugSession [

	"Configure a debug session and moves it to the following stack:
	EDMockObjectForTests>>m: 5
	EDMockObjectForTests>>m: 6
	EDMockObjectForTests>>m: 7
	EDMockObjectForTests>>m: 8
	EDMockObjectForTests>>m: 9
	EDMockObjectForTests>>m: 10
	EDMockObjectForTests>>m: 11
	EDMockObjectForTests>>m: 12
	EDMockObjectForTests>>m: 13
	EDMockObjectForTests>>m: 14
	EDMockObjectForTests>>m: 15
	EDMockObjectForTests>>m: 16
	EDMockObjectForTests>>m: 17
	EDMockObjectForTests>>m: 18
	EDMockObjectForTests>>m: 19
	EDMockObjectForTests>>m: 20
	[ EDMockObjectForTests new m: 20 ] in UndefinedObject>>DoIt"
	
	session stepThrough.
	session stepOver.
	session stepInto.
	session stepOver.
	session stepOver.
	session stepInto.
	session stepOver.
	session stepOver.
	session stepInto.	
	session stepOver.
	session stepOver.
	session stepInto.
	
	session stepOver.
	session stepOver.
	session stepInto.
	session stepOver.
	session stepOver.
	session stepInto.	
	session stepOver.
	session stepOver.
	session stepInto.
	
	session stepOver.
	session stepOver.
	session stepInto.
	session stepOver.
	session stepOver.
	session stepInto.	
	session stepOver.
	session stepOver.
	session stepInto.
	
	session stepOver.
	session stepOver.
	session stepInto.
	session stepOver.
	session stepOver.
	session stepInto.	
	session stepOver.
	session stepOver.
	session stepInto.
	
	session stepOver.
	session stepOver.
	session stepInto.
	session stepOver.
	session stepOver.
	session stepInto.	
	session stepOver.
	session stepOver.
	session stepInto.

]

{ #category : #'text - composition' }
EDEmergencyDebuggerTest >> methodDisplayTextStringExample [
	| method expectedTextStream |
	method := debugAPI methodAt: ed stackSelectionIndex.
	expectedTextStream := WriteStream on: Text new.
	ed writeSectionTitle: 'SOURCE' on: expectedTextStream.
	expectedTextStream << method methodClass name.
	expectedTextStream << '>>'.
	expectedTextStream << method sourceCode.
	expectedTextStream cr.
	^expectedTextStream contents asString
]

{ #category : #running }
EDEmergencyDebuggerTest >> newEd [
	ed := EDEmergencyDebugger new.
	ed repl: EDMockREPLInterface new.
	ed displayInterface: (mockDisplayAPI := EDMockDisplayInterface new).
	ed debug: session

]

{ #category : #'text - composition' }
EDEmergencyDebuggerTest >> resultTextStringExample [
	| expectedTextStream |
	expectedTextStream := WriteStream on: Text new.
	expectedTextStream cr.
	ed writeSectionTitle: 'RES' on: expectedTextStream.
	expectedTextStream << 'result'.
	^ expectedTextStream contents asString
]

{ #category : #running }
EDEmergencyDebuggerTest >> setUp [
	| context process |
	super setUp.	
	currentDebuggingAPI := EDEmergencyDebugger debugAPI.
	EDEmergencyDebugger debugAPI: nil.
	context := [ EDMockObjectForTests new m: 20 ] asContext.
	process := Process
		forContext: context
		priority: Processor userInterruptPriority.
	session := DebugSession
		named: 'test session'
		on: process
		startedAt: context.
	self configureDebugSession.
	debugAPI := EDDebuggingAPI attachTo: session.
	self newEd
]

{ #category : #running }
EDEmergencyDebuggerTest >> tearDown [
	EDEmergencyDebugger debugAPI: currentDebuggingAPI.
	session terminate.
	self compileMethodVersion: ''.
	super tearDown
]

{ #category : #'text - composition' }
EDEmergencyDebuggerTest >> testComposeDisplayText [
	| displayText |
	displayText := ed titleText , ed stackText , ed methodText , ed input
		, ed result.
	self assert: ed composeDisplayText equals: displayText
]

{ #category : #'text - composition' }
EDEmergencyDebuggerTest >> testComposeMethodText [
	ed composeMethodText.
	self
		assert: ed methodText asString
		equals: self methodDisplayTextStringExample
]

{ #category : #'text - composition' }
EDEmergencyDebuggerTest >> testComposePromptWith [
	| rs |
	ed composePromptWith: 'prompt'.
	rs := ed input asString readStream.
	self assert: rs next equals: Character cr.
	self assert: (rs upTo: Character cr) equals: ed separator asString.
	self assert: rs next equals: $>.
	self assert: rs next equals: Character space.
	self assert: rs upToEnd equals: 'prompt'.

]

{ #category : #'text - composition' }
EDEmergencyDebuggerTest >> testComposeResultTitle [
	ed composeResult: 'result' title: 'RES'.
	self assert: ed result asString equals: self resultTextStringExample
]

{ #category : #'text - composition' }
EDEmergencyDebuggerTest >> testComposeStackTest [
	| rs ws stack |
	ed composeStackText.
	rs := ed stackText asString readStream.
	
	self assert: rs next equals: Character cr.
	self assert: (rs upTo: Character cr) equals: ed separator asString.
	self
		assert: (rs upTo: Character cr)
		equals:
			'STACK (' , ed stackSelectionIndex printString , '/'
				, debugAPI stackSize printString , ')'.				
	self assert: (rs upTo: Character cr) equals: ed separator asString.
	
	
	stack := debugAPI stack copyFrom: 1 to: debugAPI displayStackSize.
	
	ws := WriteStream on: String new.
	(stack at: 1) printWithArgsValueOn: ws.
	self assert: (rs upTo: Character cr) equals: ws contents.
	
	ws := WriteStream on: String new.
	(stack at: 2) printWithArgsValueOn: ws.
	self assert: (rs upTo: Character cr) equals: ws contents.
	
	ws := WriteStream on: String new.
	(stack at: 3) printWithArgsValueOn: ws.
	self assert: (rs upTo: Character cr) equals: ws contents.
	
	ws := WriteStream on: String new.
	(stack at: 4) printWithArgsValueOn: ws.
	self assert: (rs upTo: Character cr) equals: ws contents.
	
	ws := WriteStream on: String new.
	(stack at: 5) printWithArgsValueOn: ws.
	self assert: (rs upTo: Character cr) equals: ws contents.
	
	self assert: rs atEnd
	 
]

{ #category : #'text - composition' }
EDEmergencyDebuggerTest >> testComposeStackText [
	| rs ws stack |
	ed composeStackText.
	rs := ed stackText asString readStream.
	
	self assert: rs next equals: Character cr.
	self assert: (rs upTo: Character cr) equals: ed separator asString.
	self
		assert: (rs upTo: Character cr)
		equals:
			'STACK (' , ed stackSelectionIndex printString , '/'
				, debugAPI stackSize printString , ')'.				
	self assert: (rs upTo: Character cr) equals: ed separator asString.
	
	
	stack := debugAPI stack copyFrom: 1 to: debugAPI displayStackSize.
	
	ws := WriteStream on: String new.
	(stack at: 1) printWithArgsValueOn: ws.
	self assert: (rs upTo: Character cr) equals: ws contents.
	
	ws := WriteStream on: String new.
	(stack at: 2) printWithArgsValueOn: ws.
	self assert: (rs upTo: Character cr) equals: ws contents.
	
	ws := WriteStream on: String new.
	(stack at: 3) printWithArgsValueOn: ws.
	self assert: (rs upTo: Character cr) equals: ws contents.
	
	ws := WriteStream on: String new.
	(stack at: 4) printWithArgsValueOn: ws.
	self assert: (rs upTo: Character cr) equals: ws contents.
	
	ws := WriteStream on: String new.
	(stack at: 5) printWithArgsValueOn: ws.
	self assert: (rs upTo: Character cr) equals: ws contents.
	
	self assert: rs atEnd
	 
]

{ #category : #'text - composition' }
EDEmergencyDebuggerTest >> testComposeTitleText [
	ed composeMethodText.
	self
		assert: ed titleText
		equals: self titleDisplayTextStringExample
]

{ #category : #'debug API' }
EDEmergencyDebuggerTest >> testDebugAPI [
	|api|
	api := EDMockObjectForTests new.
	EDEmergencyDebugger debugAPI: api.
	self assert: EDEmergencyDebugger debugAPI identicalTo: api
	
]

{ #category : #'debug API' }
EDEmergencyDebuggerTest >> testDefaultDebugAPI [
	
	self assert: EDEmergencyDebugger debugAPI identicalTo: EDDebuggingAPI
	
]

{ #category : #'text - helpers' }
EDEmergencyDebuggerTest >> testDefaultResultText [

	self assert: ed defaultResultText equals: 'TYPE h FOR HELP'
]

{ #category : #'methods version' }
EDEmergencyDebuggerTest >> testInitialMethodVersion [
	self assert: ed methodVersionSelectionIndex equals: 0
]

{ #category : #setup }
EDEmergencyDebuggerTest >> testIsRunning [
	
	"This is a new Ed, we did not call #debug: so it is not running"
	self deny: EDEmergencyDebugger new isRunning.
	"This Ed, we called #debug: in the test setup so it is running"
	self assert: ed isRunning 
]

{ #category : #'api - stack' }
EDEmergencyDebuggerTest >> testMoveDownInStack [ 
	|selectionIndexBefore shortStackIndexBefore|
	selectionIndexBefore := ed stackSelectionIndex.
	shortStackIndexBefore := ed shortStackIndex.
	ed moveDownInStack.
	self assert: ed stackSelectionIndex 
			equals: ((selectionIndexBefore + 1) min: debugAPI stackSize).
	self assert: ed shortStackIndex equals: (shortStackIndexBefore + 1).
	self assert: ed methodVersionSelectionIndex equals: 0		
]

{ #category : #'api - stack' }
EDEmergencyDebuggerTest >> testMoveDownInStackFromLastElement [ 
	|selectionIndexBefore shortStackIndexBefore|
	ed stackSelectionIndex: debugAPI stackSize.
	selectionIndexBefore := ed stackSelectionIndex.
	shortStackIndexBefore := ed shortStackIndex.
	ed moveDownInStack.
	self assert: ed stackSelectionIndex equals: selectionIndexBefore.
	self assert: ed shortStackIndex equals: shortStackIndexBefore
]

{ #category : #'api - stack' }
EDEmergencyDebuggerTest >> testMoveUpInStack [ 
	ed stackSelectionIndex: debugAPI stackSize.
	ed shortStackIndex: debugAPI stackSize.
	ed moveUpInStack.
	self assert: ed stackSelectionIndex equals: (debugAPI stackSize - 1).
	self assert: ed shortStackIndex equals: (debugAPI stackSize - 1).
	self assert: ed methodVersionSelectionIndex equals: 0		
]

{ #category : #'api - stack' }
EDEmergencyDebuggerTest >> testMoveUpInStackFromFirstElement [ 
	|selectionIndexBefore shortStackIndexBefore|
	selectionIndexBefore := ed stackSelectionIndex.
	shortStackIndexBefore := ed shortStackIndex.
	ed moveUpInStack.
	self assert: ed stackSelectionIndex equals: selectionIndexBefore.
	self assert: ed shortStackIndex equals: shortStackIndexBefore.
	self assert: ed methodVersionSelectionIndex equals: 0		
]

{ #category : #'text - helpers' }
EDEmergencyDebuggerTest >> testNewTextStream [
	|str|
	str := ed newTextStream.
	self assert: str isStream.
	self assert: str contents equals: Text new
]

{ #category : #'methods version' }
EDEmergencyDebuggerTest >> testSelectedMethodVersion [

	
]

{ #category : #'methods version' }
EDEmergencyDebuggerTest >> testSelectedMethodVersionsSize [

	
]

{ #category : #'text - helpers' }
EDEmergencyDebuggerTest >> testSeparator [

	self assert: ed separator asString equals: '--------------------'
]

{ #category : #'api - stack' }
EDEmergencyDebuggerTest >> testShiftDownShortStack [
	ed stackSelectionIndex: debugAPI displayStackSize.
	ed shortStackIndex: debugAPI displayStackSize.
	ed moveDownInStack.
	self assert: ed shortStackIndex equals: 1.
	self
		assertCollection: ed shortStack
		hasSameElements:
			(session stack
				copyFrom: debugAPI displayStackSize + 1
				to: debugAPI displayStackSize * 2)
]

{ #category : #'api - stack' }
EDEmergencyDebuggerTest >> testShiftUpShortStack [
	ed stackSelectionIndex: debugAPI displayStackSize + 1.
	ed shortStackIndex: 1.
	ed moveUpInStack.
	self assert: ed shortStackIndex equals: debugAPI displayStackSize.
	self
		assertCollection: ed shortStack
		hasSameElements: (session stack copyFrom: 1 to: debugAPI displayStackSize)
]

{ #category : #'api - stack' }
EDEmergencyDebuggerTest >> testShortStack [ 
	self assert: ed shortStack size equals: 5.	
	self assertCollection: (session stackOfSize: 5) hasSameElements: ed shortStack
]

{ #category : #'methods version' }
EDEmergencyDebuggerTest >> testShowMoreRecentMethodVersion [
	ed showMoreRecentMethodVersion.
	self assert: ed methodVersionSelectionIndex equals: 1.
	ed showOlderMethodVersion.
	ed showMoreRecentMethodVersion.
	self assert: ed methodVersionSelectionIndex equals: 1
]

{ #category : #'methods version' }
EDEmergencyDebuggerTest >> testShowOlderMethodVersion [
	self compileMethodVersion: '2'.
	ed showOlderMethodVersion.
	self assert: ed methodVersionSelectionIndex equals: 1.
	ed showOlderMethodVersion.
	self assert: ed methodVersionSelectionIndex equals: 2
]

{ #category : #'methods version' }
EDEmergencyDebuggerTest >> testShowSelectedMethodVersion [

	
]

{ #category : #setup }
EDEmergencyDebuggerTest >> testTerminate [
	
	ed terminate.
	self deny: ed isRunning 
]

{ #category : #updating }
EDEmergencyDebuggerTest >> testUpdateDisplay [
	ed updateDisplay.
	self assert: mockDisplayAPI isCleared.
	self assert: mockDisplayAPI displayData equals: ed composeDisplayText 
]

{ #category : #updating }
EDEmergencyDebuggerTest >> testUpdatePrompt [
	| promptUpdate rs |
	promptUpdate := 'PROMPT UPDATE'.
	ed updatePrompt: promptUpdate.
	rs := ed input readStream.
	rs upTo: $>.
	rs upTo: Character space.
	self assert: (rs upTo: Character cr) equals: promptUpdate
]

{ #category : #'api - stack' }
EDEmergencyDebuggerTest >> testUpdateShortStackForDisplay [ 
	
]

{ #category : #'text - helpers' }
EDEmergencyDebuggerTest >> testWriteSectionTitleOn [
	| expectedTextStream actualTextStream |
	
	expectedTextStream := WriteStream on: Text new.
	ed writeSeparatorOn: expectedTextStream.
	expectedTextStream << 'TEST'.
	expectedTextStream cr.
	ed writeSeparatorOn: expectedTextStream. 
	
	actualTextStream := WriteStream on: Text new.	
	ed writeSectionTitle: 'TEST' on: actualTextStream.

	self assert: actualTextStream contents asString 
		  equals: expectedTextStream contents asString
]

{ #category : #'text - helpers' }
EDEmergencyDebuggerTest >> testWriteSeparatorOn [
	| expectedTextStream actualTextStream |
	
	expectedTextStream := WriteStream on: Text new.
	expectedTextStream << ed separator.
	expectedTextStream cr.
	
	actualTextStream := WriteStream on: Text new.	
	ed writeSeparatorOn: actualTextStream.

	self assert: actualTextStream contents asString 
		  equals: expectedTextStream contents asString
]

{ #category : #'text - composition' }
EDEmergencyDebuggerTest >> titleDisplayTextStringExample [
	^ 'Hi, I''m ED - What is the nature of your debugging emergency?'
]