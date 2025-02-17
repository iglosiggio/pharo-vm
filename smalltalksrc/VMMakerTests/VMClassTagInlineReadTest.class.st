Class {
	#name : 'VMClassTagInlineReadTest',
	#superclass : 'VMPrimitiveCallAbstractTest',
	#pools : [
		'CogRTLOpcodes'
	],
	#category : 'VMMakerTests-JitTests',
	#package : 'VMMakerTests',
	#tag : 'JitTests'
}

{ #category : 'tests' }
VMClassTagInlineReadTest >> testLinkingWithEntryOffset [

	| sendingMethod targetMethod icTable cacheTag |
	sendingMethod := self
		                 jitMethod: (self findMethod: #methodWithSend)
		                 selector: memory nilObject.

	targetMethod := self
		                jitMethod: (self findMethod: #yourself)
		                selector: memory trueObject.

	cogit sendTablesIn: sendingMethod do: [ :annotation :table | icTable := table ].

	cacheTag := memory classIndexOf: memory falseObject.
	cogit
		transitionToMonomorphicSend: icTable
		cacheTag: cacheTag
		cogMethod: targetMethod
		isSuper: 0.

	self assert: (memory fetchCacheTag: 0 ofTable: icTable) equals: cacheTag
]

{ #category : 'tests' }
VMClassTagInlineReadTest >> testLinkingWithEntryOffsetLargeClassIndex [

	| sendingMethod targetMethod icTable cacheTag |
	sendingMethod := self
		                 jitMethod: (self findMethod: #methodWithSend)
		                 selector: memory nilObject.

	targetMethod := self
		                jitMethod: (self findMethod: #yourself)
		                selector: memory trueObject.

	cogit sendTablesIn: sendingMethod do: [ :annotation :table | icTable := table ].

	obj := self newZeroSizedObject.

	cacheTag := 1 << memory classIndexFieldWidth - 5.
	memory setClassIndexOf: obj to: cacheTag.

	cogit
		transitionToMonomorphicSend: icTable
		cacheTag: cacheTag
		cogMethod: targetMethod
		isSuper: 0.

	self assert: (memory fetchCacheTag: 0 ofTable: icTable) equals: cacheTag
]
