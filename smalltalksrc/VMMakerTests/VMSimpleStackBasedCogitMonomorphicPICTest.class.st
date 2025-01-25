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

	| sendingMethod targetCog selector executedTheTrampoline |
	self setUpCogMethodEntry.
	sendTrampolineAddress := self compile: [ cogit RetN: 0 ].
	cogit ordinarySendTrampolineAt: 0 put: sendTrampolineAddress. "num args"

	selector := memory falseObject.
	targetCog := self
		             generateCogMethod: [ cogit RetN: 0 ]
		             selector: selector.

	self createFramefulCallFrom: callerAddress.

	cogit byte0: 0.
	sendingMethod := methodBuilder
		                 newMethod;
		                 literals: { selector };
		                 buildMethod.
	cogit methodObj: sendingMethod.
	sendAddress := self compile: [
		               cogit genSendLiteralSelector0ArgsBytecode ].

	"Push receiver then send"
	self pushAddress: memory falseObject.
	self runFrom: sendAddress until: sendTrampolineAddress.

	cogit
		linkSendAt: machineSimulator classRegisterValue
		to: targetCog
		offset: cogit entryOffset
		receiver: memory falseObject.

	self pushAddress: memory falseObject.

	executedTheTrampoline := false.
	machineSimulator
		registerHook: [ executedTheTrampoline := true ]
		atAddress: sendTrampolineAddress.

	self
		runFrom: sendAddress
		until: targetCog asInteger + cogit entryOffset.
	self deny: executedTheTrampoline
]

{ #category : 'tests - PIC' }
VMSimpleStackBasedCogitMonomorphicPICTest >> testObtainInlineCacheFromLinkedCall [

	| sendingMethod targetCog selector |
	self setUpCogMethodEntry.
	sendTrampolineAddress := self compile: [ cogit RetN: 0 ].
	cogit ordinarySendTrampolineAt: 0 put: sendTrampolineAddress. "num args"

	selector := memory falseObject.
	targetCog := self
		             generateCogMethod: [ cogit RetN: 0 ]
		             selector: selector.

	self createFramefulCallFrom: callerAddress.

	cogit byte0: 0.
	sendingMethod := methodBuilder newMethod
		                 literals: { selector };
		                 buildMethod.
	cogit methodObj: sendingMethod.
	sendAddress := self compile: [
		               cogit genSendLiteralSelector0ArgsBytecode ].

	"Push receiver then send"
	self pushAddress: memory falseObject.
	self runFrom: sendAddress until: sendTrampolineAddress.

	cogit
		linkSendAt: machineSimulator classRegisterValue
		to: targetCog
		offset: cogit entryOffset
		receiver: memory falseObject.
"FIXME: This test does not make sense, we are hand-patching the IC table and then checking that the patch patched the table"
	self
		assert:
		(cogit backend inlineCacheTagAt: machineSimulator getReturnAddress)
		equals: (cogit objectRepresentation inlineCacheTagForInstance:
				 memory falseObject)
]
