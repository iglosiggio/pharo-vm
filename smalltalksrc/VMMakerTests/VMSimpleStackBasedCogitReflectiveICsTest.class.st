Class {
	#name : 'VMSimpleStackBasedCogitReflectiveICsTest',
	#superclass : 'VMSimpleStackBasedCogitAbstractTest',
	#instVars : [
		'receiver',
		'receiverTag',
		'selector',
		'numArgs',
		'compiledMethod',
		'inlineCaches',
		'cogMethod',
		'compiledCacheHit',
		'cogCacheHit',
		'compiledCacheHitUncogged'
	],
	#pools : [
		'CogMethodConstants'
	],
	#category : 'VMMakerTests-JitTests',
	#package : 'VMMakerTests',
	#tag : 'JitTests'
}

{ #category : 'running' }
VMSimpleStackBasedCogitReflectiveICsTest >> setUp [
	| pharoMethod cacheHitMethod isNullOop |
	super setUp.

	wordSize ~= 8 ifTrue: [ self skip ].

	self setUpCogMethodEntry.
	cogit generateSendTrampolines.

	receiver := memory nilObject.
	receiverTag := memory classIndexOf: receiver.
	numArgs := 0.

	pharoMethod := OpalCompilerWithInlineCaches new
		class: UndefinedObject;
		compile: 'isNull ^ self methodName'.
	(pharoMethod literalAt: 1) compiledCode: nil. "FIXME: We don't have a nice way to transform the backpointer so just use nil instead"

	cacheHitMethod := OpalCompilerWithInlineCaches new
		class: UndefinedObject;
		compile: 'methodName ^ true'.
	(cacheHitMethod literalAt: 1) compiledCode: nil. "FIXME: We don't have a nice way to transform the backpointer so just use nil instead"

	isNullOop := #isNull forMemory: memory inMethod: nil.

	compiledMethod := self createMethodOopFromHostMethod: pharoMethod.
	cogMethod := cogit cog: compiledMethod selector: isNullOop.

	selector := memory fetchPointer: 2 ofObject: compiledMethod.
	inlineCaches := memory fetchPointer: 1 ofObject: compiledMethod.

	compiledCacheHit := self createMethodOopFromHostMethod: cacheHitMethod.
	cogCacheHit := cogit cog: compiledCacheHit selector: selector.

	compiledCacheHitUncogged := self createMethodOopFromHostMethod: cacheHitMethod.
]

{ #category : 'tests - hit/miss' }
VMSimpleStackBasedCogitReflectiveICsTest >> testHit0 [
	| tagSlot methodSlot |

	tagSlot := memory slotForClassAtSendSite: 1 forOption: 1.
	methodSlot := memory slotForMethodAtSendSite: 1 forOption: 1.
	memory storePointer: tagSlot    - 1 ofObject: inlineCaches withValue: (memory integerObjectOf: receiverTag).
	memory storePointer: methodSlot - 1 ofObject: inlineCaches withValue: compiledCacheHitUncogged.

	machineSimulator pushWord: receiver.
	self runFrom: cogMethod address + cogit noCheckEntryOffset until: cogit ceInterpretedSendTrampoline.

	self assert: machineSimulator instructionPointerRegisterValue equals: cogit ceInterpretedSendTrampoline.
	self assert: machineSimulator classRegisterValue equals: compiledCacheHitUncogged.
	self assert: machineSimulator receiverRegisterValue equals: receiver.
	"FIXME: We should also assert the stack and the parameters passed-by-register"
]

{ #category : 'tests - hit/miss' }
VMSimpleStackBasedCogitReflectiveICsTest >> testHit0Cogged [
	| tagSlot methodSlot |

	tagSlot := memory slotForClassAtSendSite: 1 forOption: 1.
	methodSlot := memory slotForMethodAtSendSite: 1 forOption: 1.
	memory storePointer: tagSlot    - 1 ofObject: inlineCaches withValue: (memory integerObjectOf: receiverTag).
	memory storePointer: methodSlot - 1 ofObject: inlineCaches withValue: compiledCacheHit.

	machineSimulator pushWord: receiver.
	self runFrom: cogMethod address + cogit noCheckEntryOffset until: cogCacheHit address + cogit noCheckEntryOffset.

	self assert: machineSimulator instructionPointerRegisterValue equals: cogCacheHit address + cogit noCheckEntryOffset.
	self assert: machineSimulator classRegisterValue equals: compiledCacheHit.
	self assert: machineSimulator receiverRegisterValue equals: receiver.
	"FIXME: We should also assert the stack and the parameters passed-by-register"
]

{ #category : 'tests - hit/miss' }
VMSimpleStackBasedCogitReflectiveICsTest >> testHit1 [
	| tagSlot methodSlot |

	tagSlot := memory slotForClassAtSendSite: 1 forOption: 2.
	methodSlot := memory slotForMethodAtSendSite: 1 forOption: 2.
	memory storePointer: tagSlot    - 1 ofObject: inlineCaches withValue: (memory integerObjectOf: receiverTag).
	memory storePointer: methodSlot - 1 ofObject: inlineCaches withValue: compiledCacheHitUncogged.

	machineSimulator pushWord: receiver.
	self runFrom: cogMethod address + cogit noCheckEntryOffset until: cogit ceInterpretedSendTrampoline.

	self assert: machineSimulator instructionPointerRegisterValue equals: cogit ceInterpretedSendTrampoline.
	self assert: machineSimulator classRegisterValue equals: compiledCacheHitUncogged.
	self assert: machineSimulator receiverRegisterValue equals: receiver.
	"FIXME: We should also assert the stack and the parameters passed-by-register"
]

{ #category : 'tests - hit/miss' }
VMSimpleStackBasedCogitReflectiveICsTest >> testHit1Cogged [
	| tagSlot methodSlot |

	tagSlot := memory slotForClassAtSendSite: 1 forOption: 2.
	methodSlot := memory slotForMethodAtSendSite: 1 forOption: 2.
	memory storePointer: tagSlot    - 1 ofObject: inlineCaches withValue: (memory integerObjectOf: receiverTag).
	memory storePointer: methodSlot - 1 ofObject: inlineCaches withValue: compiledCacheHit.

	machineSimulator pushWord: receiver.
	self runFrom: cogMethod address + cogit noCheckEntryOffset until: cogCacheHit address + cogit noCheckEntryOffset.

	self assert: machineSimulator instructionPointerRegisterValue equals: cogCacheHit address + cogit noCheckEntryOffset.
	self assert: machineSimulator classRegisterValue equals: compiledCacheHit.
	self assert: machineSimulator receiverRegisterValue equals: receiver.
	"FIXME: We should also assert the stack and the parameters passed-by-register"
]

{ #category : 'tests - hit/miss' }
VMSimpleStackBasedCogitReflectiveICsTest >> testHit2 [
	| tagSlot methodSlot |

	tagSlot := memory slotForClassAtSendSite: 1 forOption: 3.
	methodSlot := memory slotForMethodAtSendSite: 1 forOption: 3.
	memory storePointer: tagSlot    - 1 ofObject: inlineCaches withValue: (memory integerObjectOf: receiverTag).
	memory storePointer: methodSlot - 1 ofObject: inlineCaches withValue: compiledCacheHitUncogged.

	machineSimulator pushWord: receiver.
	self runFrom: cogMethod address + cogit noCheckEntryOffset until: cogit ceInterpretedSendTrampoline.

	self assert: machineSimulator instructionPointerRegisterValue equals: cogit ceInterpretedSendTrampoline.
	self assert: machineSimulator classRegisterValue equals: compiledCacheHitUncogged.
	self assert: machineSimulator receiverRegisterValue equals: receiver.
	"FIXME: We should also assert the stack and the parameters passed-by-register"
]

{ #category : 'tests - hit/miss' }
VMSimpleStackBasedCogitReflectiveICsTest >> testHit2Cogged [
	| tagSlot methodSlot |

	tagSlot := memory slotForClassAtSendSite: 1 forOption: 3.
	methodSlot := memory slotForMethodAtSendSite: 1 forOption: 3.
	memory storePointer: tagSlot    - 1 ofObject: inlineCaches withValue: (memory integerObjectOf: receiverTag).
	memory storePointer: methodSlot - 1 ofObject: inlineCaches withValue: compiledCacheHit.

	machineSimulator pushWord: receiver.
	self runFrom: cogMethod address + cogit noCheckEntryOffset until: cogCacheHit address + cogit noCheckEntryOffset.

	self assert: machineSimulator instructionPointerRegisterValue equals: cogCacheHit address + cogit noCheckEntryOffset.
	self assert: machineSimulator classRegisterValue equals: compiledCacheHit.
	self assert: machineSimulator receiverRegisterValue equals: receiver.
	"FIXME: We should also assert the stack and the parameters passed-by-register"
]

{ #category : 'tests - hit/miss' }
VMSimpleStackBasedCogitReflectiveICsTest >> testMiss [

	machineSimulator pushWord: receiver.
	self runFrom: cogMethod address + cogit noCheckEntryOffset until: cogit ceCPICMissTrampoline.

	"Failing all two PIC cases calls the fallback mechanism.
	 - The instruction pointer is at the fallback
	 - The class register value contains the fallback data
	 - The receiver register value contains the receiver
	 - The temp register value contains the sendsite index"
	self assert: machineSimulator instructionPointerRegisterValue equals: cogit ceCPICMissTrampoline.
	self assert: machineSimulator classRegisterValue equals: inlineCaches.
	self assert: machineSimulator receiverRegisterValue equals: receiver.
	self assert: machineSimulator sendNumberOfArgumentsRegisterValue equals: numArgs.
	"FIXME: lookup the extra registers too"
]
