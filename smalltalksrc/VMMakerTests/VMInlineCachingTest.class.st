Class {
	#name : 'VMInlineCachingTest',
	#superclass : 'VMStackToRegisterMappingCogitTest',
	#instVars : [
		'argCount',
		'sendTrampolines',
		'classes',
		'classMethodOops',
		'instances',
		'icTable',
		'cacheTags',
		'oopMethod',
		'cogMethod',
		'oopSelector'
	],
	#classVars : [
		'IsSendCall'
	],
	#pools : [
		'CogMethodConstants',
		'ICTableConstants',
		'VMMethodCacheConstants'
	],
	#category : 'VMMakerTests-JitTests',
	#package : 'VMMakerTests',
	#tag : 'JitTests'
}

{ #category : 'building suites' }
VMInlineCachingTest class >> argCountParameters [

	^ ParametrizedTestMatrix new
		  forSelector: #argCount addOptions: #( 0 1 2 3 );
		  yourself
]

{ #category : 'building suites' }
VMInlineCachingTest class >> testParameters [

	^ super testParameters * self argCountParameters
]

{ #category : 'running' }
VMInlineCachingTest >> argCount: anArgumentCount [

	argCount := anArgumentCount
]

{ #category : 'as yet unclassified' }
VMInlineCachingTest >> cacheOperandsFor: anICTableOop [

	| result |
	result := Array new: ICCacheEntryCount.
	1 to: ICCacheEntryCount do: [ :i |
		| cacheTag |
		cacheTag := memory fetchCacheOperand: i - 1 ofTable: anICTableOop.
		result at: i put: cacheTag ].
	^ result
]

{ #category : 'as yet unclassified' }
VMInlineCachingTest >> cacheTagsFor: anICTableOop [

	| result |
	result := Array new: ICCacheEntryCount.
	1 to: ICCacheEntryCount do: [ :i |
		| cacheTag |
		cacheTag := memory fetchCacheTag: i - 1 ofTable: anICTableOop.
		result at: i put: cacheTag ].
	^ result
]

{ #category : 'as yet unclassified' }
VMInlineCachingTest >> cacheValuesFor: anICTableOop [

	| result |
	result := Array new: ICCacheEntryCount.
	1 to: ICCacheEntryCount do: [ :i |
		| cacheTag |
		cacheTag := memory fetchCacheValue: i - 1 ofTable: anICTableOop.
		result at: i put: cacheTag ].
	^ result
]

{ #category : 'as yet unclassified' }
VMInlineCachingTest >> cogMethodForClass: classID [

	^ cogit cog: (self methodForClass: classID) selector: oopSelector
]

{ #category : 'running' }
VMInlineCachingTest >> createSimpleClass [

	| class |
	class := self
		         newClassInOldSpaceWithSlots: 0
		         instSpec: memory nonIndexablePointerFormat.
	memory ensureBehaviorHash: class.
	self setUpMethodDictionaryIn: class.
	memory
		storePointer: SuperclassIndex
		ofObject: class
		withValue: memory nilObject.
	^ class
]

{ #category : 'tests - metadata' }
VMInlineCachingTest >> initialCodeSize [

	^ 16 * 1024
]

{ #category : 'running' }
VMInlineCachingTest >> installMethodInto: aMethodDictOop classID: classID [

	| method |
	method := methodBuilder
		newMethod;
		numberOfTemporaries: argCount;
		numberOfArguments: argCount;
		bytecodes: {
			16r20 "pushConstant: 0 (first literal)".
			16r5C "returnTop" };
		literals: {
			(memory integerObjectOf: classID). "Literal to load"
			oopSelector. "Method selector"
			memory nilObject "#className -> Class association" };
		buildMethod.
	self
		installSelector: oopSelector
		method: method
		inMethodDictionary: aMethodDictOop.

	classMethodOops at: classID put: method
]

{ #category : 'running' }
VMInlineCachingTest >> installSelector: aSelectorOop method: aMethodOop inMethodDictionary: aMethodDictionary [
	
	| anArrayOfMethods |
	anArrayOfMethods := memory fetchPointer: MethodArrayIndex ofObject: aMethodDictionary.
	memory
		storePointer: SelectorStart + (memory methodDictionaryHash: aSelectorOop mask: 2r11)
		ofObject: aMethodDictionary
		withValue: aSelectorOop.
	memory
		storePointer: (memory methodDictionaryHash: aSelectorOop mask: 2r11)
		ofObject: anArrayOfMethods
		withValue: aMethodOop
]

{ #category : 'as yet unclassified' }
VMInlineCachingTest >> methodForClass: classID [

	^ classMethodOops at: classID
]

{ #category : 'tests - metadata' }
VMInlineCachingTest >> send0To: anObject [

	<compilerOptions: #( #- #optionOptimiseSpecialSends )>
	^ anObject value
]

{ #category : 'tests - metadata' }
VMInlineCachingTest >> send1To: anObject [

	<compilerOptions: #( #- #optionOptimiseSpecialSends )>
	^ anObject value: 0
]

{ #category : 'tests - metadata' }
VMInlineCachingTest >> send2To: anObject [

	<compilerOptions: #( #- #optionOptimiseSpecialSends )>
	^ anObject value: 0 value: 0
]

{ #category : 'tests - metadata' }
VMInlineCachingTest >> send3To: anObject [

	<compilerOptions: #( #- #optionOptimiseSpecialSends )>
	^ anObject value: 0 value: 0 value: 0
]

{ #category : 'running' }
VMInlineCachingTest >> setArrayClassIntoClassTable [
	| aClass |
	aClass := self
		newClassInOldSpaceWithSlots: 0
		instSpec: Array instSpec.
	memory setHashBitsOf: aClass to: ClassArrayCompactIndex.
	memory
		storePointer: ClassArrayCompactIndex
		ofObject: memory classTableFirstPage
		withValue: aClass
]

{ #category : 'running' }
VMInlineCachingTest >> setMessageClassIntoClassTable [
	| aClass |
	aClass := self
		newClassInOldSpaceWithSlots: MessageSend allSlots size 
		instSpec: MessageSend instSpec.
	memory setHashBitsOf: aClass to: ClassMessageCompactIndex.
	memory
		storePointer: ClassMessageCompactIndex
		ofObject: memory classTableFirstPage
		withValue: aClass
]

{ #category : 'running' }
VMInlineCachingTest >> setUp [

	<flag: #FIXME>
	super setUp.

	isa = #IA32 ifTrue: [ self skip ].

	cogit
		generateTrampolines;
		computeEntryOffsets.

	interpreter methodDictLinearSearchLimit: 3.
	memory coInterpreter moveMethodCacheToMemoryAt:
		(memory memoryManager allocate:
			 MethodCacheEntrySize * MethodCacheSize * (interpreter sizeof: #sqInt)).

	cogit generateOpenPICPrototype.

	self
		setUpStack;
		setUpMethods;
		setUpClasses.
	"FIXME: Ugly and breaks encapsulation"
	sendTrampolines := cogit instVarNamed: #ordinarySendTrampolines
]

{ #category : 'running' }
VMInlineCachingTest >> setUpClasses [
	"This code sets up seven classes and seven instances.
	 Each class implements value, value:value: and value:value:value: returning either 0 or 1"

	| classCount |
	classCount := ICCacheEntryCount + 1.

	"Create and fill all the classes"
	classMethodOops := Array new: classCount.
	classes := (1 to: classCount) collect: [ :i |
		           | class methodDict |
		           class := self createSimpleClass.
		           methodDict := memory
			                         fetchPointer: MethodDictionaryIndex
			                         ofObject: class.
		           self installMethodInto: methodDict classID: i.
		           class ].

	"Instance each class"
	instances := classes collect: [ :class | memory instantiateClass: class ].

	"Collect all the cache tags"
	cacheTags := classes collect: [ :class | memory rawHashBitsOf: class ]
]

{ #category : 'running' }
VMInlineCachingTest >> setUpMethodDictionaryIn: aClass [
	"2 instances variables the array of methods and the tally
	and 12 entries to put elemetns of the collection"
	
	| aMethodDictionary anArrayOfMethods |
	aMethodDictionary := self
		newObjectWithSlots: 2 + 12
		format: MethodDictionary instSpec
		classIndex: memory arrayClassIndexPun.
	anArrayOfMethods := self
		newObjectWithSlots: 12
		format: Array instSpec
		classIndex: memory arrayClassIndexPun.
	memory
		storePointer: MethodDictionaryIndex
		ofObject: aClass
		withValue: aMethodDictionary.
	memory
		storePointer: MethodArrayIndex
		ofObject: aMethodDictionary
		withValue: anArrayOfMethods.
		
	

]

{ #category : 'running' }
VMInlineCachingTest >> setUpMethods [

	| selector |
	selector := #( #send0To: #send1To: #send2To: #send3To: ) at: argCount + 1.
	oopMethod := self createMethodOopFromHostMethod: self class >> selector.
	cogMethod := cogit cog: oopMethod selector: memory nilObject.
	oopSelector := memory fetchPointer: 1 ofObject: oopMethod.
	memory hashBitsOf: oopSelector.
	cogit mapFor: cogMethod do: [ :annotation :mcpc |
		(cogit isSendAnnotation: annotation)
			ifTrue: [
				icTable := cogit fetchLiteralAtAnnotatedAddress: mcpc asUnsignedInteger.
				true ]
			ifFalse: [ false ] ]
]

{ #category : 'running' }
VMInlineCachingTest >> setUpStack [

	self createBaseFrame.

	"Initialize Stack to the correct pointers in the selected page"
	machineSimulator smalltalkStackPointerRegisterValue: interpreter stackPointer.
	machineSimulator framePointerRegisterValue: interpreter framePointer.
	machineSimulator baseRegisterValue: cogit varBaseAddress.

	cogit setCStackPointer: interpreter rumpCStackAddress.
	cogit setCFramePointer: interpreter rumpCStackAddress
]

{ #category : 'tests - metadata' }
VMInlineCachingTest >> testInlineCacheCanExecuteCoggedDoesNotUnderstandMethods [

	| dnuSelector expectedReturnValue class methodDict methodOop methodCog |
	self
		setArrayClassIntoClassTable;
		setMessageClassIntoClassTable.

	dnuSelector := memory integerObjectOf: 404. "Selector not found"
	memory splObj: SelectorDoesNotUnderstand put: dnuSelector.

	expectedReturnValue := memory integerObjectOf: 16rB0CA.
	class := self createSimpleClass.
	methodOop := methodBuilder
		             newMethod;
		             numberOfTemporaries: 1;
		             numberOfArguments: 1;
		             bytecodes: { 16r20. 16r5C };
		             literals: {
				             expectedReturnValue. "Literal to load"
				             dnuSelector. "Method selector"
				             memory nilObject "#className -> Class association" };
		             buildMethod.
	methodDict := memory fetchPointer: MethodDictionaryIndex ofObject: class.
	self
		installSelector: dnuSelector
		method: methodOop
		inMethodDictionary: methodDict.
	methodCog := cogit cog: methodOop selector: dnuSelector.

	cogit transitionToPolymorphicSend: icTable numArgs: argCount.
	cogit
		configurePolymorphicSendCase: icTable
		entryIndex: 0
		cacheTag: (memory rawHashBitsOf: class)
		operand: methodOop
		value: (cogit polymorphicSendMNUFor: argCount).

	callerAddress := cogit simulatedAddressFor: [ self fail ].
	machineSimulator arg0RegisterValue: (memory instantiateClass: class).
	self prepareCall.
	self runUntilReturnFrom: cogMethod address + cogit noCheckEntryOffset.

	self
		assert: machineSimulator receiverRegisterValue
		equals: expectedReturnValue
]

{ #category : 'tests - metadata' }
VMInlineCachingTest >> testInlineCacheCanLinkAgainstDoesNotUnderstand [

	| dnuSelector class methodDict methodOop methodCog |
	self
		setArrayClassIntoClassTable;
		setMessageClassIntoClassTable.

	dnuSelector := memory integerObjectOf: 404. "Selector not found"
	memory splObj: SelectorDoesNotUnderstand put: dnuSelector.

	class := self createSimpleClass.
	methodOop := methodBuilder
		             newMethod;
		             numberOfTemporaries: 1;
		             numberOfArguments: 1;
		             bytecodes: { 16r20. 16r5C };
		             literals: {
				             dnuSelector. "Literal to load"
				             dnuSelector. "Method selector"
				             memory nilObject "#className -> Class association" };
		             buildMethod.
	methodDict := memory fetchPointer: MethodDictionaryIndex ofObject: class.
	self
		installSelector: dnuSelector
		method: methodOop
		inMethodDictionary: methodDict.
	methodCog := cogit cog: methodOop selector: dnuSelector.

	machineSimulator arg0RegisterValue: (memory instantiateClass: class).
	self
		runFrom: cogMethod address + cogit noCheckEntryOffset
		until: methodCog address + cogit noCheckEntryOffset.

	self
		assert: machineSimulator instructionPointerRegisterValue
		equals: methodCog address + cogit noCheckEntryOffset.
	self
		assert: (memory fetchHandlerOfTable: icTable)
		equals: (cogit polymorphicSendFor: argCount).
	self
		assert: (memory fetchCacheTag: 0 ofTable: icTable)
		equals: (memory rawHashBitsOf: class).
	self
		assert: (memory fetchCacheOperand: 0 ofTable: icTable)
		equals: methodOop.
	self
		assert: (memory fetchCacheValue: 0 ofTable: icTable)
		equals: (cogit polymorphicSendMNUFor: argCount)
]

{ #category : 'tests - metadata' }
VMInlineCachingTest >> testInlineCacheCanLinkAgainstInterpretedMethods [

	machineSimulator arg0RegisterValue: (instances at: 1).
	[
		interpreter sigset: nil jmp: 0.
		self runFrom: cogMethod address + cogit noCheckEntryOffset until: 0.
		self fail ]
			on: ReenterInterpreter
			do: [ ].

	self assert: interpreter method equals: (self methodForClass: 1).
	self
		assert: (memory fetchHandlerOfTable: icTable)
		equals: (cogit polymorphicSendFor: argCount).
	self 
		assert: (memory fetchCacheTag: 0 ofTable: icTable)
		equals: (cacheTags at: 1).
	self
		assert: (memory fetchCacheOperand: 0 ofTable: icTable)
		equals: (self methodForClass: 1).
	self
		assert: (memory fetchCacheValue: 0 ofTable: icTable)
		equals: (cogit polymorphicSendInterpretFor: argCount)
]

{ #category : 'tests - metadata' }
VMInlineCachingTest >> testInlineCacheCanUpdateACachedInterpretedMethodAfterItWasCogged [

	| method methodCog |
	machineSimulator arg0RegisterValue: (instances at: 1).
	method := self methodForClass: 1.
	methodCog := self cogMethodForClass: 1.

	cogit transitionToPolymorphicSend: icTable numArgs: argCount.
	cogit
		configurePolymorphicSendCase: icTable
		entryIndex: 0
		cacheTag: (cacheTags at: 1)
		operand: method
		value: (cogit polymorphicSendInterpretFor: argCount).

	self
		runFrom: cogMethod address + cogit noCheckEntryOffset
		until: methodCog address + cogit noCheckEntryOffset.

	self
		assert: machineSimulator instructionPointerRegisterValue
		equals: methodCog address + cogit noCheckEntryOffset.
	self
		assert: (memory fetchHandlerOfTable: icTable)
		equals: (cogit polymorphicSendFor: argCount).
	self
		assert: (memory fetchCacheTag: 0 ofTable: icTable)
		equals: (cacheTags at: 1).
	self
		assert: (memory fetchCacheOperand: 0 ofTable: icTable)
		equals: (self methodForClass: 1).
	self
		assert: (memory fetchCacheValue: 0 ofTable: icTable)
		equals: methodCog address + cogit noCheckEntryOffset
]

{ #category : 'tests - metadata' }
VMInlineCachingTest >> testInlineCacheStateMachineProperlyGoesThroughAllStates [

	| doCall expectedCacheTags monomorphicallyLinkedCogMethod |
	callerAddress := cogit simulatedAddressFor: [ self fail ].
	doCall := [ :i |
	          machineSimulator arg0RegisterValue: (instances at: i).
	          self prepareCall.
	          self runUntilReturnFrom: cogMethod address + cogit noCheckEntryOffset ].

	expectedCacheTags := Array new: 6 withAll: memory illegalClassTag.

	"First monomorphic"
	monomorphicallyLinkedCogMethod := self cogMethodForClass: 1.
	expectedCacheTags at: 1 put: (cacheTags at: 1).
	doCall value: 1.

	self
		assert: machineSimulator receiverRegisterValue
		equals: (memory integerObjectOf: 1).
	self
		assert: (memory fetchHandlerOfTable: icTable)
		equals: monomorphicallyLinkedCogMethod address + cogit entryOffset.
	self assert: (self cacheTagsFor: icTable) equals: expectedCacheTags.

	"Then polymorphic"
	2 to: ICCacheEntryCount do: [ :i |
		self cogMethodForClass: i.
		expectedCacheTags at: i put: (cacheTags at: i).
		doCall value: i.

		self
			assert: machineSimulator receiverRegisterValue
			equals: (memory integerObjectOf: i).
		self
			assert: (memory fetchHandlerOfTable: icTable)
			equals: (cogit polymorphicSendFor: argCount).
		self assert: (self cacheTagsFor: icTable) equals: expectedCacheTags ].

	"Finally megamorphic"
	self cogMethodForClass: 7.
	expectedCacheTags := Array new: 6 withAll: memory illegalClassTag.
	doCall value: 7.

	self
		assert: (cogit cogMethodSurrogateAt:
				 (memory fetchHandlerOfTable: icTable) - cogit entryOffset) cmType
		equals: CMMegamorphicIC.
	self
		assert: machineSimulator receiverRegisterValue
		equals: (memory integerObjectOf: 7).
	self assert: (self cacheTagsFor: icTable) equals: expectedCacheTags
]

{ #category : 'tests - metadata' }
VMInlineCachingTest >> testMonomorphicallyLinkedTrasitionsToPolymorphic [

	| method0Cog method1Cog |
	method0Cog := self cogMethodForClass: 1.
	method1Cog := self cogMethodForClass: 2.

	cogit
		transitionToMonomorphicSend: icTable
		cacheTag: (cacheTags at: 1)
		cogMethod: method0Cog
		isSuper: 0.

	machineSimulator arg0RegisterValue: (instances at: 2).
	self
		runFrom: cogMethod address + cogit noCheckEntryOffset
		until: method1Cog address + cogit noCheckEntryOffset.

	self
		assert: machineSimulator instructionPointerRegisterValue
		equals: method1Cog address + cogit noCheckEntryOffset.
	self
		assert: (memory fetchHandlerOfTable: icTable)
		equals: (cogit polymorphicSendFor: argCount).
	self assert: (self cacheTagsFor: icTable) equals: {
			(cacheTags at: 1).
			(cacheTags at: 2).
			memory illegalClassTag.
			memory illegalClassTag.
			memory illegalClassTag.
			memory illegalClassTag }.
	self assert: (self cacheOperandsFor: icTable) equals: {
			(self methodForClass: 1).
			(self methodForClass: 2).
			memory nilObject.
			memory nilObject.
			memory nilObject.
			memory nilObject }.
	self assert: (self cacheValuesFor: icTable) equals: {
			(method0Cog address + cogit noCheckEntryOffset).
			(method1Cog address + cogit noCheckEntryOffset).
			0.
			0.
			0.
			0 }
]

{ #category : 'tests - metadata' }
VMInlineCachingTest >> testPolymorphicallyLinkedSendCanBeExtended [

	| method0Cog method1Cog method2Cog |
	method0Cog := self cogMethodForClass: 1.
	method1Cog := self cogMethodForClass: 2.
	method2Cog := self cogMethodForClass: 3.

	cogit transitionToPolymorphicSend: icTable numArgs: argCount.
	cogit
		configurePolymorphicSendCase: icTable
		entryIndex: 0
		cacheTag: (cacheTags at: 1)
		operand: (self methodForClass: 1)
		value: method0Cog address + cogit noCheckEntryOffset.
	cogit
		configurePolymorphicSendCase: icTable
		entryIndex: 1
		cacheTag: (cacheTags at: 2)
		operand: (self methodForClass: 2)
		value: method1Cog address + cogit noCheckEntryOffset.

	machineSimulator arg0RegisterValue: (instances at: 3).
	self
		runFrom: cogMethod address + cogit noCheckEntryOffset
		until: method2Cog address + cogit noCheckEntryOffset.

	self
		assert: machineSimulator instructionPointerRegisterValue
		equals: method2Cog address + cogit noCheckEntryOffset.
	self
		assert: (memory fetchHandlerOfTable: icTable)
		equals: (cogit polymorphicSendFor: argCount).
	self assert: (self cacheTagsFor: icTable) equals: {
			(cacheTags at: 1).
			(cacheTags at: 2).
			(cacheTags at: 3).
			memory illegalClassTag.
			memory illegalClassTag.
			memory illegalClassTag }.
	self assert: (self cacheOperandsFor: icTable) equals: {
			(self methodForClass: 1).
			(self methodForClass: 2).
			(self methodForClass: 3).
			memory nilObject.
			memory nilObject.
			memory nilObject }.
	self assert: (self cacheValuesFor: icTable) equals: {
			(method0Cog address + cogit noCheckEntryOffset).
			(method1Cog address + cogit noCheckEntryOffset).
			(method2Cog address + cogit noCheckEntryOffset).
			0.
			0.
			0 }
]

{ #category : 'tests - metadata' }
VMInlineCachingTest >> testPolymorphicallyLinkedSendFullyExtendedTransitionsToMegamorphic [

	| linkedCogMethods megamorphicStub |
	linkedCogMethods := (1 to: classes size) collect: [ :i |
		                    self cogMethodForClass: i ].

	cogit transitionToPolymorphicSend: icTable numArgs: argCount.
	1 to: ICCacheEntryCount do: [ :i |
		cogit
			configurePolymorphicSendCase: icTable
			entryIndex: i - 1
			cacheTag: (cacheTags at: i)
			operand: (self methodForClass: i)
			value: (linkedCogMethods at: i) address + cogit noCheckEntryOffset ].

	megamorphicStub := cogit cogOpenPICSelector: oopSelector numArgs: argCount.

	machineSimulator arg0RegisterValue: (instances at: 7).
	{
		interpreter inMemoryCStackPointerAddress hex.
		(memory long64At: interpreter inMemoryCStackPointerAddress) hex }.
	self
		runFrom: cogMethod address + cogit noCheckEntryOffset
		until: (linkedCogMethods at: 7) address + cogit noCheckEntryOffset.

	self
		assert: machineSimulator instructionPointerRegisterValue
		equals: (linkedCogMethods at: 7) address + cogit noCheckEntryOffset.
	self
		assert: (memory fetchHandlerOfTable: icTable)
		equals: megamorphicStub address + cogit entryOffset.
	self assert: (self cacheTagsFor: icTable) equals: {
			memory illegalClassTag.
			memory illegalClassTag.
			memory illegalClassTag.
			memory illegalClassTag.
			memory illegalClassTag.
			memory illegalClassTag }.
	self assert: (self cacheOperandsFor: icTable) equals: {
			memory nilObject.
			memory nilObject.
			memory nilObject.
			memory nilObject.
			memory nilObject.
			memory nilObject }.
	self assert: (self cacheValuesFor: icTable) equals: { 0. 0. 0. 0. 0. 0 }
]

{ #category : 'tests - metadata' }
VMInlineCachingTest >> testTheCallingConventionUnderTestDidNotChange [

	"This assertion is here in order to have a test that fails if we extend the number of special-cased arities"
	self assert: sendTrampolines size equals: 4.
]

{ #category : 'tests - metadata' }
VMInlineCachingTest >> testUnlinkedSendRunsUnlinkedTrampoline [

	self
		runFrom: cogMethod address + cogit noCheckEntryOffset
		until: (sendTrampolines at: argCount).

	self
		assert: machineSimulator instructionPointerRegisterValue
		equals: (sendTrampolines at: argCount)
]

{ #category : 'tests - metadata' }
VMInlineCachingTest >> testUnlinkedTrampolineTrasitionsToMonomorphic [

	| methodCog |
	methodCog := self cogMethodForClass: 1.

	machineSimulator arg0RegisterValue: (instances at: 1).
	self
		runFrom: cogMethod address + cogit noCheckEntryOffset
		until: methodCog address + cogit noCheckEntryOffset.

	self
		assert: machineSimulator instructionPointerRegisterValue
		equals: methodCog address + cogit noCheckEntryOffset.
	self
		assert: (memory fetchHandlerOfTable: icTable)
		equals: methodCog address + cogit entryOffset
]
