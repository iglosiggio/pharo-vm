Class {
	#name : 'VMSimpleStackBasedCogitMonomorphicPICTest',
	#superclass : 'VMSimpleStackBasedCogitAbstractTest',
	#category : 'VMMakerTests-JitTests',
	#package : 'VMMakerTests',
	#tag : 'JitTests'
}

{ #category : 'tests - PIC' }
VMSimpleStackBasedCogitMonomorphicPICTest >> testLinkCallDuringSendInTrampolineReplacesTheCallTargetWithTheCogMethodAddress [
	"This is for the monomorphic case"

	| sendingMethod targetCog selector executedTheTrampoline icTable |
	self setUpCogMethodEntry.
	sendTrampolineAddress := self compile: [ cogit RetN: 0 ].
	cogit ordinarySendTrampolineAt: 0 put: sendTrampolineAddress. "num args"

	selector := memory falseObject.
	targetCog := self generateCogMethod: [ cogit RetN: 0 ] selector: selector.

	self createFramefulCallFrom: callerAddress.

	cogit byte0: 0.
	sendingMethod := methodBuilder
		                 newMethod;
		                 literals: { selector };
		                 buildMethod.
	cogit methodObj: sendingMethod.
	sendAddress := self compile: [ cogit genSendLiteralSelector0ArgsBytecode ].

	"Push receiver then send"
	self pushAddress: memory falseObject.
	self runFrom: sendAddress until: sendTrampolineAddress.

	"This is not a reasonable test. Why aren't we testing the real trampoline?"
	icTable := machineSimulator classRegisterValue.
	cogit
		transitionToMonomorphicSend: icTable
		cacheTag: (memory classIndexOf: memory falseObject)
		cogMethod: targetCog
		isSuper: 0.

	self pushAddress: memory falseObject.

	executedTheTrampoline := false.
	machineSimulator
		registerHook: [ executedTheTrampoline := true ]
		atAddress: sendTrampolineAddress.

	self runFrom: sendAddress until: targetCog asInteger + cogit entryOffset.
	self deny: executedTheTrampoline
]

{ #category : 'tests - PIC' }
VMSimpleStackBasedCogitMonomorphicPICTest >> testObtainInlineCacheFromLinkedCall [

	| sendingMethod targetCog selector icTable |
	self setUpCogMethodEntry.
	sendTrampolineAddress := self compile: [ cogit RetN: 0 ].
	cogit ordinarySendTrampolineAt: 0 put: sendTrampolineAddress. "num args"

	selector := memory falseObject.
	targetCog := self generateCogMethod: [ cogit RetN: 0 ] selector: selector.

	self createFramefulCallFrom: callerAddress.

	cogit byte0: 0.
	sendingMethod := methodBuilder newMethod
		                 literals: { selector };
		                 buildMethod.
	cogit methodObj: sendingMethod.
	sendAddress := self compile: [ cogit genSendLiteralSelector0ArgsBytecode ].

	"Push receiver then send"
	self pushAddress: memory falseObject.
	self runFrom: sendAddress until: sendTrampolineAddress.

	icTable := machineSimulator classRegisterValue.
	cogit
		transitionToMonomorphicSend: icTable
		cacheTag: (memory classIndexOf: memory falseObject)
		cogMethod: targetCog
		isSuper: 0.

	self
		assert: (memory fetchCacheTag: 0 ofTable: icTable)
		equals:
		(cogit objectRepresentation inlineCacheTagForInstance: memory falseObject)
]
