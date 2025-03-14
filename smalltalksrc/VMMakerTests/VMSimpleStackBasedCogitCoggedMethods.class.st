Class {
	#name : 'VMSimpleStackBasedCogitCoggedMethods',
	#superclass : 'VMSimpleStackBasedCogitAbstractTest',
	#pools : [
		'CogMethodConstants'
	],
	#category : 'VMMakerTests-JitTests',
	#package : 'VMMakerTests',
	#tag : 'JitTests'
}

{ #category : 'running' }
VMSimpleStackBasedCogitCoggedMethods >> setUp [
	super setUp.
	self setUpCogMethodEntry.
]

{ #category : 'tests' }
VMSimpleStackBasedCogitCoggedMethods >> testUsingEntryOffsetChecksClassRegisterAndContinue [

	| cogMethod otherBlock icTable |
	otherBlock := self compile: [ cogit Nop ].
	cogMethod := self
		             generateCogMethod: [ cogit Jump: otherBlock ]
		             selector: memory falseObject.

	icTable := memory
		           allocateICTable: (memory integerObjectOf: 0)
		           withUnlinkedHandler: 0
		           numArgs: 0.
	"Let's set the receiver class intext as the first cache tag"
	memory
		storeCacheTag: 0
		ofTable: icTable
		with: (memory classIndexOf: memory nilObject).

	"Load the icTable on the ClassRegister"
	machineSimulator classRegisterValue: icTable.

	self runFrom: cogMethod address + cogit entryOffset until: otherBlock.

	self
		assert: machineSimulator instructionPointerRegisterValue
		equals: otherBlock
]

{ #category : 'tests' }
VMSimpleStackBasedCogitCoggedMethods >> testUsingEntryOffsetChecksClassRegisterAndGoesToAbort [

	| cogMethod otherBlock icTable |
	otherBlock := self compile: [ cogit Nop ].
	cogMethod := self
		             generateCogMethod: [ cogit Jump: otherBlock ]
		             selector: memory falseObject.

	icTable := memory
		           allocateICTable: (memory integerObjectOf: 0)
		           withUnlinkedHandler: 0
		           numArgs: 0.
	"Let's set any value as the first cache tag"
	memory storeCacheTag: 0 ofTable: icTable with: 16rFF.

	"Load the icTable on the ClassRegister"
	machineSimulator classRegisterValue: icTable.

	self
		runFrom: cogMethod address + cogit entryOffset
		until: cogit ceMethodAbortTrampoline.

	self
		assert: machineSimulator instructionPointerRegisterValue
		equals: cogit ceMethodAbortTrampoline
]

{ #category : 'tests' }
VMSimpleStackBasedCogitCoggedMethods >> testUsingNoCheckEntryDoesNotCheckClassTag [

	| cogMethod otherBlock |
	otherBlock := self compile: [ cogit Nop ].
	cogMethod := self generateCogMethod: [ cogit Jump: otherBlock ] selector: memory falseObject.
	
	"Let's set any value in the ClassRegister"
	machineSimulator classRegisterValue: 16rFF.
	
	self runFrom: cogMethod address + cogit noCheckEntryOffset until: otherBlock.

	self assert: machineSimulator instructionPointerRegisterValue equals: otherBlock 
]
