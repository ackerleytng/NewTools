"
The StDebugger is a presenter that provides Pharo debugging functionality by using a DebugSession.

The debugging logic is in DebugSession and the corresponding debugging actions. 

SpecDebugger only provides a graphical interface to access that functionality. 
To interact with the DebugSession, the debugger uses a StDebuggerActionModel, which has responsibility to perform actions to the execution context.


!!Structure of the Pharo debugger

!!!Sub-presenters and layouts
The debugger is composed of default views and extension views.
Default views are the stack, the commands, the status line, the code pane and the inspector.
An extension view automatically appears if any debugging extension is present and if extensions are activated in the settings.
If not, extensions do not appear.

Default and extension views are available in a vertical and an horizontal layout.
It is configureable in the settings under ==Tools >> Debugging >> Debugger layout==.
It is possible to fully customize the debugger layout, and therefore to add or remove any view.
The customized layout must then me selected in the aforementioned setting to be set as default.
To appear in that setting's list of possible values, the layout must be implemented in a method under the ==specs== protocol of the ==StDebugger== class side.

""""The stack.""""
It shows the call stack of the current interrupted context.
Each element in the stack is a context representing a message send.

The context menu (through right click) provides different interactions with the selected stack element: inspection, exploration, exportation, etc.

By default, only a small part of the stack is shown.
More of the stack is observable by either clicking on the bottom context (the last in the stack) or through the context menu.

""""Commands.""""
Commands are actions applicable to the current context
After each debugging action (''e.g.'', a step), the list of commands is being updated.
New commands may appear or disappear.
It depends if they are applicable or not to the current context and debugging session.
For instance, when a ==doesNotUnderstand== exception is raised (''i.e.'', a method does not exist), the command ''createMethod'' will appear.
In that case, it gives users the possibility to create the missing method and continue the execution.

""""The status line.""""
This view provides information about the current context.
Non-critical information, such as the current instruction being stepped, are displayed in gray.
Critical information ,such as halts or breakpoints or DNU exceptions, are displayed in red.

""""The code.""""
The code pane shows the source code of the interrupted context's method.
The source code is annotated with informations about the position of the interrupted execution.
This position corresponds to the next execution that will be executed if a step action is performed.
It is coloured in blue if that instruction is selected in the source code, or in orange and underlined if the selection is empty.

A context menu (through right click) provides inspection, exploration, and stepping actions applicable to the context.
Such actions include, ''e.g.'', browse implementors of a selected message or skip execution of selected parts of the code.

""""The inspector.""""
It provides views on the current context.
It contains tabs with different inspections or views on the current context or on the system.

The raw inspection shows three items: ''Receiver'', ''Temps'' and ''Context''.
The receiver item shows information about the receiver of the message, or the object executing the method from the context.
The temps item shows the temporary variables of the current context.
Finally, the context item shows lower-level details, such as the interrupted context, the debug session or the debugger itself.
Double-clicking on an item will spawn a new view in the same inspector, with an inspection on the selected item.

The breakpoints inspection shows all breakpoints installed for the current receiver.
Those breakpoints are either installed on the receiver's class (''e.g.'', halts) or on that specific receiver (''i.e.'', object-centric breakpoints or halts.)
Ticking or unticking a breakpoint in that list will activate or deactivate that breakpoint.

The meta inspection shows methods of the receiver's class hierarchy.
Methods can be modified and saved in directly in that pane.
"
Class {
	#name : #StDebugger,
	#superclass : #StPresenter,
	#instVars : [
		'sessionHolder',
		'code',
		'toolbar',
		'stackTable',
		'inspector',
		'breakpointInspector',
		'stackHeader',
		'codeHeader',
		'extensionTools',
		'extensionToolsNotebook',
		'toolbarCommandGroup',
		'debuggerActionModel',
		'codeCommands',
		'debuggerCommandGroup'
	],
	#classVars : [
		'ActivateDebuggerExtensions',
		'Available',
		'DefaultDebugger',
		'ErrorRecursion',
		'ExtensionToolsSettings',
		'UsingSpecSelector'
	],
	#category : #'NewTools-Debugger-View'
}

{ #category : #accessing }
StDebugger class >> activateDebuggerExtensions [
	^ ActivateDebuggerExtensions
		ifNil: [ ActivateDebuggerExtensions := true ]
]

{ #category : #accessing }
StDebugger class >> activateDebuggerExtensions: anObject [
	ActivateDebuggerExtensions := anObject
]

{ #category : #'tools registry' }
StDebugger class >> availableAutomatically [
	"Should this debugger be taken into account when looking for a debugger to handle an exception."
	^Available ifNil:[Available := true]
]

{ #category : #'tools registry' }
StDebugger class >> availableExtensionToolsClassesSettings [
	| settingToClass |
	settingToClass := Dictionary new.
	self collectExtendedToolsClasses
		do: [ :toolClass | 
			self extensionToolsSettings
				at: toolClass debuggingExtensionToolName
				ifPresent:
					[ :settings | settings do: [ :s | settingToClass at: s put: toolClass ] ] ].
	^ settingToClass 
]

{ #category : #specs }
StDebugger class >> availableSpecSelectors [
	^ self class allSelectorsInProtocol: 'specs - selectors'
]

{ #category : #commands }
StDebugger class >> buildCommandsGroupWith: stDebuggerInstance forRoot: rootCommandGroup [
	StDebuggerStackCommandTreeBuilder
		buildCommandsGroupWith: stDebuggerInstance
		forRoot: rootCommandGroup.
	StDebuggerToolbarCommandTreeBuilder
		buildCommandsGroupWith: stDebuggerInstance
		forRoot: rootCommandGroup.
	StDebuggerCodeCommandTreeBuilder
		buildCommandsGroupWith: stDebuggerInstance
		forRoot: rootCommandGroup
]

{ #category : #utilities }
StDebugger class >> closeAllDebuggers [
	<script>
	StDebugger allInstancesDo: [ :dbg | dbg close ]
]

{ #category : #specs }
StDebugger class >> codeLayout [
	^ SpBoxLayout newVertical
		add:
			(SpBoxLayout newVertical
				add: #toolbar;
				add: #codeHeader
					expand: true
					fill: true
					padding: 0;
				yourself)
			withConstraints: [ :constraints | 
				constraints
					expand: false;
					height: self toolbarHeight * 2 ];
		add: #code;
		yourself
]

{ #category : #'tools registry' }
StDebugger class >> collectExtendedToolsClasses [
	^ self collectExtendedToolsClassesFor: self extendedToolsPragma
]

{ #category : #'tools registry' }
StDebugger class >> collectExtendedToolsClassesFor: pragmaSelector [
	^ (self collectExtendedToolsPragmaFor: pragmaSelector)
		collect: [ :prg | prg methodClass soleInstance ]
]

{ #category : #'tools registry' }
StDebugger class >> collectExtendedToolsPragmaFor: pragmaSelector [
	self flag: 'PragmaCollector might be changed in the near future?'.
	^ (PragmaCollector filter: [ :prg | prg selector = pragmaSelector ])
		reset collected
]

{ #category : #settings }
StDebugger class >> debuggerExtensionSettingsForClass: toolClass builder: aBuilder [
	| settings |

	settings := self extensionToolSettingsFor: toolClass.
	settings
		do: [ :s | 
			(aBuilder group: toolClass debuggingExtensionToolName asSymbol)
				label: toolClass debuggingExtensionToolName;
				with: [ 
					(aBuilder setting: #showInDebugger)
						label: 'Show in debugger';
						target: s;
						default: s defaultShowInDebugger;
						description: 'Activate the tool tab in the debugger right column.'.
					(aBuilder pickOne: #displayOrder)
						label: 'Position';
						target: s;
						default: s defaultDisplayOrder;
						domainValues: (1 to: 100) asArray;
						description: 'Position of the tool tab in the debugger right column.' ] ]
]

{ #category : #settings }
StDebugger class >> debuggerExtensionSettingsOn: aBuilder [
	<systemsettings>
	(aBuilder group: #debuggerExtensions)
		label: 'Debugger Extensions';
		parent: #debugging;
		description:
			'Tools that extend the StDebugger and appear in the right column of the debugger';
		with: [ | settingsGroup |
			settingsGroup := (aBuilder setting: #activateDebuggerExtensions)
				label: 'Activate extensions';
				target: self;
				default: true;
				description:
					'(De)Activate the debugger extensions tools in the debugger right column.'.
			self
				debuggerExtensionsSettingsOn: aBuilder
				parentGroup: settingsGroup ]
]

{ #category : #settings }
StDebugger class >> debuggerExtensionsSettingsOn: aBuilder parentGroup: settingsGroup [
	
	settingsGroup with: [ 
		self collectExtendedToolsClasses do: [ :toolClass | 
			self debuggerExtensionSettingsForClass: toolClass builder: aBuilder ] ]
]

{ #category : #settings }
StDebugger class >> debuggerLayoutSettingsOn: aBuilder [
	<systemsettings>
	(aBuilder pickOne: #usingSpecSelector)
		label: 'Default debugger spec layout';
		target: self;
		default: #debuggerWithoutExtensionsSpec;
		parent: #debugging;
		domainValues: self availableSpecSelectors;
		description: 'Sets the default spec layout of the debugger.'
]

{ #category : #'specs - selectors' }
StDebugger class >> debuggerWithExtensionsSpec [
	^ SpPanedLayout newVertical
		position: 65 percent;
		add:
			(SpPanedLayout newHorizontal
				position: 65 percent;
				add: self stackAndCodeLayout;
				add: #extensionToolsNotebook;
				yourself);
		add: #inspector;
		yourself
]

{ #category : #'specs - selectors' }
StDebugger class >> debuggerWithoutExtensionsSpec [
	^ SpPanedLayout newVertical
		position: 65 percent;
		add: self stackAndCodeLayout;
		add: #inspector;
		yourself
]

{ #category : #settings }
StDebugger class >> defaultDebugger [
	^DefaultDebugger
]

{ #category : #settings }
StDebugger class >> defaultDebugger: aSymbol [
	Available := (aSymbol = #GT) not.
	DefaultDebugger := aSymbol 
]

{ #category : #settings }
StDebugger class >> defaultDebuggerSettingsOn: aBuilder [
	<systemsettings>
	(aBuilder pickOne: #defaultDebugger)
		label: 'Default debugger';
		target: self;
		default: #NewTools;
		parent: #debugging;
		domainValues: #(#GT #NewTools);
		description: 'Sets the default debugger.'
]

{ #category : #specs }
StDebugger class >> defaultSpec [
	^ self perform: self usingSpecSelector
]

{ #category : #'tools registry' }
StDebugger class >> extendedToolsPragma [	

	^ #debuggerExtensionOrder:showByDefault:
]

{ #category : #'tools registry' }
StDebugger class >> extensionToolSettingsFor: aToolClass [
	^ self extensionToolsSettings
		at: aToolClass debuggingExtensionToolName
		ifAbsentPut:
			[ StDebuggerExtensionSetting fromDebuggerExtensionClass: aToolClass ]
]

{ #category : #'tools registry' }
StDebugger class >> extensionToolsSettings [
	^ ExtensionToolsSettings
		ifNil: [ ExtensionToolsSettings := Dictionary new ]
]

{ #category : #opening }
StDebugger class >> handlesContext: aContext [
	^self availableAutomatically 
]

{ #category : #'tools registry' }
StDebugger class >> hasAnyActivatedExtension [
	^ self activateDebuggerExtensions
		and: [ self extensionToolsSettings values
				anySatisfy:
					[ :toolSettings | toolSettings anySatisfy: [ :setting | setting showInDebugger ] ] ]
]

{ #category : #'debugger declaration' }
StDebugger class >> iAmADebugger [
	"Leave blank for intermediate classes. Add the <iAmADebugger> pragma for concrete debugger classes. This pragma is used by the system to find all available debuggers"

	"For compatibility with DebuggerSelector https://github.com/dupriezt/DebuggerSelector"

	<iAmADebugger>
	self flag: 'I am not sure this is good design'
]

{ #category : #'class initialization' }
StDebugger class >> initialize [ 
	
	ErrorRecursion := false.

	"Ugly check to make sure the debugger will work until everything is in the image"
	(Smalltalk tools respondsTo: #registerDebugger:withRank:) ifFalse: [ ^ self ].

	"Add ourselves to registry. See [Smalltalk tools]" 
	Smalltalk tools registerDebugger: self withRank: self rank.
	
]

{ #category : #opening }
StDebugger class >> openOn: aDebugSession withFullView: aBool [
	
	^ self openOn: aDebugSession withFullView: aBool andNotification: nil
]

{ #category : #opening }
StDebugger class >> openOn: aDebugSession withFullView: aBool andNotification: aString [
	| debugger |
	debugger := self on: aDebugSession.
	debugger openWithFullView.
	^ debugger
]

{ #category : #'class initialization' }
StDebugger class >> rank [
	^ 80
]

{ #category : #'class initialization' }
StDebugger class >> rankDebugSession: aDebugSession [
	"Returns an integer representing how much this debugger is suitable to debug @aDebugSession. The higher the integer returned, the more suitable this debugger is. Signal the DebugSessionCannotBeOpenedByThisDebugger exception if this debugger absolutely cannot debug @aDebugSession (for example if this debugger can only handle debug sessions from test executions, and @aDebugSession does not come from a test execution)"
	"For compatibility with DebuggerSelector https://github.com/dupriezt/DebuggerSelector"
	^ self rank.
]

{ #category : #'tools registry' }
StDebugger class >> register [
	self flag: 'Maybe this is no longer necessary now that we have DebuggerSelector?'.
	self registerToolsOn: Smalltalk tools
]

{ #category : #'tools registry' }
StDebugger class >> registerToolsOn: registry [
	self flag: 'Maybe this is no longer necessary now that we have DebuggerSelector?'.
	"Add ourselves to registry. See [Smalltalk tools]" 
	registry register: self as: #debugger.

]

{ #category : #accessing }
StDebugger class >> sessionClass [
	self flag: 'Should be replaced by Sindarin - should even be removed in that case!'.
	^ DebugSession
]

{ #category : #accessing }
StDebugger class >> spanNewSessionFrom: anotherSession [
	self flag: 'Where is that used? 2019-06-28'.
	^ anotherSession spanNewSession
]

{ #category : #specs }
StDebugger class >> stackAndCodeLayout [
	^ SpPanedLayout newVertical
		position: 30 percent;
		add: self stackLayout;
		add: self codeLayout;
		yourself
]

{ #category : #specs }
StDebugger class >> stackLayout [
	^ SpBoxLayout newVertical
		add: #stackHeader
			expand: false
			fill: false
			padding: 5;
		add: #stackTable;
		yourself
]

{ #category : #icons }
StDebugger class >> taskbarIconName [

	^#smallDebugIcon
]

{ #category : #specs }
StDebugger class >> usingSpecSelector [
	^ (UsingSpecSelector
		ifNil: [ UsingSpecSelector := StDebuggerSpecSelector defaultSelector ])
		selectSpecSelector
]

{ #category : #specs }
StDebugger class >> usingSpecSelector: aSelector [

	UsingSpecSelector := StDebuggerSpecSelector on: aSelector
]

{ #category : #commands }
StDebugger >> buildCommandTree [
	debuggerCommandGroup := self rootCommandsGroup
]

{ #category : #commands }
StDebugger >> buildContextMenus [
	| stackGroup |
	self buildCommandTree.

	"Stack"
	stackGroup := debuggerCommandGroup
		/ StDebuggerStackCommandTreeBuilder groupName.
	stackTable contextMenu: stackGroup beRoot asMenuPresenter.

	"Toolbar"
	toolbarCommandGroup := debuggerCommandGroup
		/ StDebuggerToolbarCommandTreeBuilder groupName.
	SpToolbarPresenterBuilder new
		toolbarPresenter: toolbar;
		visit: toolbarCommandGroup.
	self updateToolbarDebugActions.

	"Code"
	codeCommands := debuggerCommandGroup
		/ StDebuggerCodeCommandTreeBuilder groupName.
	code contextMenu: codeCommands beRoot asMenuPresenter
]

{ #category : #commands }
StDebugger >> canExecuteCreateMissingClassCommand [
	^ self debuggerActionModel isInterruptedContextMissingClassException
]

{ #category : #commands }
StDebugger >> canExecuteCreateMissingMethodCommand [
	^ self debuggerActionModel isInterruptedContextDoesNotUnderstand
]

{ #category : #commands }
StDebugger >> canExecuteCreateSubclassResponsibilityCommand [
	^ self debuggerActionModel isInterruptedContextSubclassResponsibilityException
]

{ #category : #commands }
StDebugger >> canExecuteDebugCommand [
	^ self debuggerActionModel isContextSteppable
]

{ #category : #commands }
StDebugger >> canExecuteRestartCommand [
	^ self debuggerActionModel isInterruptedContextPostMortem not
]

{ #category : #actions }
StDebugger >> clear [
	extensionToolsNotebook pages
		do: [ :page | page activePresenter windowIsClosing ].
	extensionTools := nil.
	self removeActionsForSession: self session.
	self debuggerActionModel clearDebugSession
]

{ #category : #'updating widgets' }
StDebugger >> clearCode [
	
	self code
		clearInteractionModel;
		clearSelection;
		clearContent
]

{ #category : #opening }
StDebugger >> close [
	self withWindowDo: #close
]

{ #category : #'accessing widgets' }
StDebugger >> code [

	^ code
]

{ #category : #'accessing context' }
StDebugger >> context [
 
	^ self interruptedContext
]

{ #category : #actions }
StDebugger >> copyStackToClipboard [
	self debuggerActionModel copyStackToClipboard
]

{ #category : #actions }
StDebugger >> createMissingClass [
	| message exception variableNode |
	self flag: #DBG_MISSINGTEST.
	message := self interruptedContext tempAt: 1.
	exception := self interruptedContext tempAt: 2.
	variableNode := exception variableNode.
	[ OCUndeclaredVariableWarning new
		node: variableNode;
		defineClass: variableNode name ]
		on: Abort
		do: [ ^ self ].
	self
		createMissingMethodFor: message
		in: self interruptedContext receiver class.
	self debuggerActionModel restartContext: self interruptedContext
]

{ #category : #actions }
StDebugger >> createMissingMethod [
	| msg chosenClass |
	self flag: #DBG_MISSINGTEST.
	msg := self interruptedContext tempAt: 1.
	"chosenClass := (self
		requestSuperclassOf: self interruptedContext receiver class
		to: ProtoObject
		toImplement: msg selector
		ifCancel: [ ^ self ]) value."
	chosenClass := self interruptedContext receiver class.
	self createMissingMethodFor: msg in: chosenClass
]

{ #category : #actions }
StDebugger >> createMissingMethodFor: aMessage in: aClass [
	self flag: #DBG_MISSINGTEST.
	self debuggerActionModel
		implement: aMessage
		classified: Protocol unclassified
		inClass: aClass
		forContext: self interruptedContext.
	self selectTopContext
]

{ #category : #actions }
StDebugger >> createSubclassResponsibility [
	| senderContext msg msgCategory chosenClass |
	senderContext := self interruptedContext sender.
	msg := Message
		selector: senderContext selector
		arguments: senderContext arguments.
	msgCategory := senderContext methodClass organization
		categoryOfElement: msg selector.
	chosenClass := (self
		requestSuperclassOf: senderContext receiver class
		to: senderContext methodClass
		toImplement: senderContext selector
		ifCancel: [ ^ self ]) value.
	self debuggerActionModel
		implement: msg
		classified: msgCategory
		inClass: chosenClass
		forContext: senderContext
]

{ #category : #'accessing context' }
StDebugger >> currentContext [
	"I answer the context on which an action should be executed.
	This is either the selected context or if nothing is selected the interrupted context."
	
	^ self selectedContext isNil 
		ifTrue: [ self interruptedContext ]
		ifFalse: [ self selectedContext ]
]

{ #category : #accessing }
StDebugger >> debuggerActionModel [
	^ debuggerActionModel
		ifNil: [ debuggerActionModel := StDebuggerActionModel on: self session]
]

{ #category : #stack }
StDebugger >> expandStackIfLastItemIsSelected [
	| selection |
	selection := stackTable selection.
	selection selectedItem == stackTable items last ifFalse: [ ^ self ].
	stackTable items: (self filterStack:
			 (self session stackOfSize: 2 * stackTable items size)).
	stackTable selectIndex: selection selectedIndex
]

{ #category : #extensions }
StDebugger >> extensionTools [
	^ extensionTools ifNil: [ extensionTools := OrderedCollection new ]
]

{ #category : #actions }
StDebugger >> fileOutSelectedContext [
	self debuggerActionModel
		fileOutMethod: stackTable selection selectedItem method
]

{ #category : #stack }
StDebugger >> filterStack: aStack [
	^self debuggerActionModel filterStack: aStack
]

{ #category : #stack }
StDebugger >> findFirstRelevantStackIndexIn: aStack [
	| counter |
	counter := 1.
	aStack do: [ :context | 
		context method methodClass == TestAsserter ifFalse: [ ^ counter ].
		counter := counter + 1 ].
	^ 1
]

{ #category : #'updating session' }
StDebugger >> forceSessionUpdate [
	self sessionHolder valueChanged
]

{ #category : #api }
StDebugger >> initialExtent [ 
	"This code was taken from the old debugger to get the same behavior. Fell free to refactor"
	self flag: 'Do it better'.
	"RealEstateAgent standardWindowExtent y < 400"true "a tiny screen" 
		ifTrue: [ ^ 1000@800 ].
	
	^ [ | w h |
		w := Display width.
		h := Display height.
		(w - (w // 3)) @ (h - (h // 5)) ]
		on: Error
		do: [ 850@650 ]
]

{ #category : #initialization }
StDebugger >> initialize [
	super initialize.
	self setSessionHolderSubscriptions.
	self forceSessionUpdate
]

{ #category : #initialization }
StDebugger >> initializeBreakpointInspector [
	breakpointInspector := self
		instantiate: StDebuggerBreakpointInspection
		on: (StInspectorModel on: nil).
]

{ #category : #initialization }
StDebugger >> initializeCode [
	self flag: #DBG_IMPROVE.
	 "Add metalink information in the gutter!"
	
	code := self newCode.
	code whenSubmitDo: [ :text | 
		self
			recompileMethodTo: text string
			inContext: self stackTable selection selectedItem
			notifying: nil ].
	code whenResetDo: [ self updateCodeFromContext ].	
			
	codeHeader := self instantiate: StHeaderBar.	
	codeHeader removeStyleFromLabel: 'label.header'.	
	codeHeader applyStyleToLabel: 'label.headerError'.
	codeHeader label: self session name
]

{ #category : #extensions }
StDebugger >> initializeExtensionTools [
	| settingsToClasses sortedSettings pages |
	extensionToolsNotebook := self newNotebook.
	self class hasAnyActivatedExtension
		ifFalse: [ ^ self ].
	settingsToClasses := self class
		availableExtensionToolsClassesSettings.
	sortedSettings := SortedCollection
		sortBlock: [ :s1 :s2 | s1 displayOrder <= s2 displayOrder ].
	sortedSettings addAll: settingsToClasses keys.
	sortedSettings := sortedSettings select: [ :s | s showInDebugger ].
	pages := sortedSettings
		collect: [ :s | self instantiateExtensionToolsPage: (settingsToClasses at: s) ].
	extensionToolsNotebook pages: pages
]

{ #category : #initialization }
StDebugger >> initializeInspector [
	inspector := self
		instantiate: StDebuggerInspector
		on: (StDebuggerInspectorModel on: nil).
	inspector label: 'Receiver'
]

{ #category : #initialization }
StDebugger >> initializePresenters [

	self initializeStack.
	self initializeToolbar.
	self initializeCode.
	self initializeInspector.
	self initializeExtensionTools
]

{ #category : #initialization }
StDebugger >> initializeStack [
	stackTable := self newTable.
	stackTable
		addColumn: (SpStringTableColumn
				 title: 'Class'
				 evaluated: [ :item | item receiver class ]);
		addColumn:
			(SpStringTableColumn title: 'Method' evaluated: [ :item | 
					 | method |
					 method := item method.
					 method isCompiledBlock
						 ifTrue: [ method sourceNode sourceCode ]
						 ifFalse: [ method selector ] ])";
		addColumn: (SpStringTableColumn
				 title: 'Context'
				 evaluated: [ :item | item sender stDisplayString ])".
	stackTable transmitDo: [ :context | 
		stackTable selection isEmpty ifFalse: [ 
			self updateInspectorFromContext: context.
			self updateCodeFromContext: context.
			self updateTitle.
			self expandStackIfLastItemIsSelected ] ].
	stackHeader := self instantiate: StHeaderBar.
	stackHeader label: 'Stack'
]

{ #category : #initialization }
StDebugger >> initializeToolbar [
	toolbar := self newToolbar.
	toolbar displayMode: self application toolbarDisplayMode
]

{ #category : #initialization }
StDebugger >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter 
		title: self title;
		initialExtent: self initialExtent;
		whenClosedDo: [ self clear ]
]

{ #category : #extensions }
StDebugger >> instantiateExtensionToolsPage: aToolClass [
	| toolInstance |
	toolInstance := self instantiate: aToolClass on: self.
	self registerExtensionTool: toolInstance.
	^ SpNotebookPage
		title: aToolClass debuggingExtensionToolName
		provider: [ toolInstance ]
]

{ #category : #'accessing context' }
StDebugger >> interruptedContext [

	^ self session interruptedContext
]

{ #category : #accessing }
StDebugger >> interruptedProcess [

	^ self session interruptedProcess
]

{ #category : #api }
StDebugger >> okToChange [

	self code canDiscardEdits
		ifTrue: [ ^ true ].
	self code changed: #wantToChange.
	^ self code canDiscardEdits
]

{ #category : #opening }
StDebugger >> openWithFullView [
	"Create and schedule a full debugger with the given label. Do not
	terminate the current active process."

	self
		openWithSpec;
		buildContextMenus;
		updateCodeFromContext
]

{ #category : #opening }
StDebugger >> openWithNotification: notificationString [
	self openWithFullView
]

{ #category : #actions }
StDebugger >> proceedDebugSession [ 
	self debuggerActionModel proceedDebugSession.
	self close
]

{ #category : #actions }
StDebugger >> recompileMethodTo: aString inContext: aContext notifying: aNotifyer [

	^ aContext 
		ifNil: [ false ]
		ifNotNil: [
			self session recompileMethodTo: aString inContext: aContext notifying: aNotifyer ]
]

{ #category : #'updating session' }
StDebugger >> registerActionsForSession: aSession [
	self flag: 'Rewrite it'.
	aSession
		ifNotNil: [ aSession
				when: #restart send: #updateRestart to: self;
				when: #resume send: #updateResume to: self;
				when: #stepInto send: #updateStepInto to: self;
				when: #stepOver send: #updateStepOver to: self;
				when: #stepThrough send: #updateStepThrough to: self;
				when: #contextChanged send: #updateContextChanged to: self ]
]

{ #category : #extensions }
StDebugger >> registerExtensionTool: anExtension [
	self extensionTools add: anExtension
]

{ #category : #'updating session' }
StDebugger >> removeActionsForSession: aSession [
	self flag: 'Rewrite it'.
	aSession
		ifNotNil: [ aSession
				removeActionsForEvent: #restart;
				removeActionsForEvent: #resume;
				removeActionsForEvent: #stepInto;
				removeActionsForEvent: #stepOver;
				removeActionsForEvent: #stepThrough;
				removeActionsForEvent: #contextChanged ]
]

{ #category : #'updating session' }
StDebugger >> removeSessionHolderSubscriptions [
	self sessionHolder announcer unsubscribe: self sessionHolder.
	self removeActionsForSession: self session
]

{ #category : #'ui requests' }
StDebugger >> requestSuperclassOf: aClass to: aSuperclass toImplement: aSelector ifCancel: cancelBlock [
	| classes |
	classes := OrderedCollection with: aClass.
	classes addAll: (aClass allSuperclassesIncluding: aSuperclass).
	classes
		addAll: (aClass traits sort: [ :t1 :t2 | t1 asString < t2 asString ]).
	classes size = 1
		ifTrue: [ ^ classes first ].
	^ (UIManager default
		chooseFrom: (classes collect: [ :c | c name ])
		values: classes
		title: 'Define #' , aSelector , ' in which class?')
		ifNil: [ cancelBlock ]
]

{ #category : #actions }
StDebugger >> restartCurrentContext [
	self debuggerActionModel restartContext: self currentContext
]

{ #category : #actions }
StDebugger >> returnEnteredValue [
	| expression |
	expression := UIManager default
		request: 'Enter expression for return value:'.
	self debuggerActionModel
		returnValueFromExpression: expression
		fromContext: self currentContext
]

{ #category : #actions }
StDebugger >> runToSelection [
	self debuggerActionModel
		runToSelection: self code selectionInterval
		inContext: self currentContext
]

{ #category : #actions }
StDebugger >> selectNextExecutedExpression [
	self code
		selectionInterval: (self session pcRangeForContext: self currentContext)
]

{ #category : #stack }
StDebugger >> selectTopContext [
	stackTable selectIndex: 1
]

{ #category : #'accessing context' }
StDebugger >> selectedContext [

	^ self stackTable selection selectedItem
]

{ #category : #accessing }
StDebugger >> session [
	^ self sessionHolder value
]

{ #category : #accessing }
StDebugger >> session: aSession [
	self sessionHolder value: aSession
]

{ #category : #accessing }
StDebugger >> sessionHolder [
	^ sessionHolder ifNil: [ sessionHolder := nil asValueHolder ]
]

{ #category : #initialization }
StDebugger >> setModelBeforeInitialization: aSession [

	self session: aSession
]

{ #category : #'updating session' }
StDebugger >> setSessionHolderSubscriptions [
	self sessionHolder
		whenChangedDo: [ :newSession :oldSession | 
			self removeActionsForSession: oldSession.
			self registerActionsForSession: newSession.
			self updateStackFromSession: newSession.
			self updateTitle.
			self updateExtensionsFrom: newSession ]
]

{ #category : #actions }
StDebugger >> showFullStack [
	stackTable items: (self filterStack: self session stack)

]

{ #category : #commands }
StDebugger >> stackSelectionMethodContext [
	^ [ stackTable selection selectedItem method ]
]

{ #category : #commands }
StDebugger >> stackSelectionMethodSelectorContext [
	^[ stackTable selection selectedItem method selector ]
]

{ #category : #commands }
StDebugger >> stackSelectionReceiverClassContext [
	^ [ stackTable selection selectedItem receiver class ]
]

{ #category : #commands }
StDebugger >> stackSelectionReceiverContext [
	^ [ stackTable selection selectedItem receiver ]
]

{ #category : #'accessing widgets' }
StDebugger >> stackTable [
	^stackTable
]

{ #category : #'accessing context' }
StDebugger >> statusLabelStyleForCurrentContext [
	self flag: 'deprecated?'.
"true ifTrue: [ ^ 'label.headerError' ]."
	(self context tempNames includes: #exception) ifTrue: [ 
		(self context tempNamed: #exception) ifNotNil: [ :ex | 
			^ 'label.headerError' ] ].
	self context currentNode isHaltNode ifTrue: [ ^ 'label.headerError' ].
	^ 'label.header'
]

{ #category : #'accessing context' }
StDebugger >> statusLabelTextForCurrentContext [
	(debuggerActionModel exceptionInContextOrNil: self context)
		ifNotNil: [ :ex | ^ ex description ].
	^ self context currentNode isHaltNode
		ifTrue: [ 'Halt' ]
		ifFalse: [ self context receiver class name , '>>' , self context selector ]
]

{ #category : #actions }
StDebugger >> stepInto [
	self debuggerActionModel stepInto: self currentContext
]

{ #category : #actions }
StDebugger >> stepOver [
	self debuggerActionModel stepOver: self currentContext
]

{ #category : #actions }
StDebugger >> stepThrough [
	self debuggerActionModel stepThrough: self currentContext
]

{ #category : #api }
StDebugger >> title [
	^ ((self session isContextPostMortem: self interruptedContext)
		ifTrue: [ '[PostMortem] ' ]
		ifFalse: [ '' ]) , self titlePrefixTextForCurrentContext, self currentContext asString
]

{ #category : #'accessing context' }
StDebugger >> titlePrefixTextForCurrentContext [
	self context sender == self currentContext
		ifTrue: [ (debuggerActionModel exceptionInContextOrNil: self context)
				ifNotNil: [ :ex | ^ ex description , ' in ' ] ].
	^ self currentContext currentNode isHaltNode
		ifTrue: [ 'Halt in ' ]
		ifFalse: [ '' ]
]

{ #category : #'accessing widgets' }
StDebugger >> toolbar [

	^ toolbar
]

{ #category : #'updating widgets' }
StDebugger >> updateCodeFromContext [

	self updateCodeFromContext: self currentContext
]

{ #category : #'updating widgets' }
StDebugger >> updateCodeFromContext: aContext [
	| selectionInterval |

	aContext ifNil: [ ^ self clearCode ].

	selectionInterval := self session selectedCodeRangeForContext: aContext.
	aContext sourceCode = self code text 
		ifFalse: [ self code text: aContext sourceCode ].
	self code beForContext: aContext.
	self code selectionInterval: selectionInterval.
	
	self flag: #DBG, 'the following leaves highlighted text everywhere when the code pane is not updated.'
	"self
		updateCodeTextSegmentDecoratorsIn: aContext
		forInterval: selectionInterval."
	
]

{ #category : #'updating widgets' }
StDebugger >> updateCodeHeaderLabel [
	codeHeader label: self statusLabelTextForCurrentContext
]

{ #category : #'updating widgets' }
StDebugger >> updateCodeTextSegmentDecoratorsIn: aContext forInterval: selectionInterval [
	self flag: #DBG, 'this is temporarily removed for NewTools integration into Pharo 9. We need better support for this.'
	"self code removeAllTextSegmentDecorations."
	
	"This decorates the receiver and the next node with an underline"
	"self code
		addTextSegmentDecoration:
			(SpTextPresenterDecorator new
				underlineColor: Color orange;
				interval: (aContext currentNode start to: aContext currentNode stop + 1);
				yourself)."
				
	"This decorates the next executing node"
	"self code
		addTextSegmentDecoration:
			(SpTextPresenterDecorator new
				highlightColor: (Color orange alpha: 0.5);
				underlineColor: (Color white alpha: 0);
				interval: (selectionInterval first to: selectionInterval last + 1);
				yourself)."
				
			"	icon: (self iconNamed: #warning);
				iconBlock: [ :n | n inspect ];
				title: 'Click me!';"
]

{ #category : #'updating actions' }
StDebugger >> updateContextChanged [
	self updateStep
]

{ #category : #'updating widgets' }
StDebugger >> updateExtensionsFrom: newSession [
	self extensionTools do:[:tool| tool updatePresenter]
]

{ #category : #'updating widgets' }
StDebugger >> updateInspectorFromContext: aContext [
	inspector
		updateLayoutForContexts: self session interruptedContext
		isAssertionFailure:
		self debuggerActionModel isInterruptedContextAnAssertEqualsFailure.
	inspector updateWith: (StDebuggerContext
			 context: aContext
			 session: self session
			 debugger: self).
	self flag: #DBG_INSPECTOR_UPDATE_BUG.
	inspector getRawInspectorPresenterOrNil ifNotNil: [:p| p update].
]

{ #category : #'updating actions' }
StDebugger >> updateRestart [
	self updateStep
]

{ #category : #'updating actions' }
StDebugger >> updateResume [

	
]

{ #category : #stack }
StDebugger >> updateStackFromSession: aSession [
	|stack|
	stack := (self filterStack: aSession shortStack).
	stackTable items: stack.
	stackTable selectIndex: (self findFirstRelevantStackIndexIn: stack)
]

{ #category : #'updating actions' }
StDebugger >> updateStep [
	self updateStackFromSession: self session.
	self updateCodeHeaderLabel.
	self updateExtensionsFrom: self session.
	self updateTitle.
	self updateToolbarDebugActions.
	self flag: #DBG_INSPECTOR_UPDATE_BUG.
	inspector getRawInspectorPresenterOrNil ifNotNil: [:p| p update].
]

{ #category : #'updating actions' }
StDebugger >> updateStepInto [
	self updateStep
]

{ #category : #'updating actions' }
StDebugger >> updateStepOver [

	self updateStep 
	
]

{ #category : #'updating actions' }
StDebugger >> updateStepThrough [

	self updateStep 
]

{ #category : #'updating widgets' }
StDebugger >> updateTitle [
	self withWindowDo: [ :window | window title: self title]
]

{ #category : #'updating widgets' }
StDebugger >> updateToolbarDebugActions [
	
	toolbarCommandGroup allCommands
		do: [ :spCommand | spCommand updateEnableStatus ]
]
