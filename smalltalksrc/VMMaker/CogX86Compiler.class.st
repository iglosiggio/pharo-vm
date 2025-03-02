Class {
	#name : 'CogX86Compiler',
	#superclass : 'CogAbstractInstruction',
	#category : 'VMMaker-JIT',
	#package : 'VMMaker',
	#tag : 'JIT'
}

{ #category : 'testing' }
CogX86Compiler class >> isAbstract [

	^ self == CogX86Compiler
]

{ #category : 'smalltalk calling convention' }
CogX86Compiler >> genPushRegisterArgsForAbortMissNumArgs: numArgs [
	"Ensure that the register args are pushed before the outer and
	 inner retpcs at an entry miss for arity <= self numRegArgs.  The
	 outer retpc is that of a call at a send site.  The inner is the call
	 from a method or PIC abort/miss to the trampoline."

	"This won't be as clumsy on a RISC.  But putting the receiver and
	 args above the return address means the CoInterpreter has a
	 single machine-code frame format which saves us a lot of work."

	"Iff there are register args convert
		base	->	outerRetpc		(send site retpc)
		sp		->	innerRetpc		(PIC abort/miss retpc)
	 to
		base	->	receiver
					(arg0)
					(arg1)
					outerRetpc
		sp		->	innerRetpc		(PIC abort/miss retpc)"
	numArgs <= cogit numRegArgs ifTrue:
		[self assert: cogit numRegArgs <= 2.
		 numArgs = 0 ifTrue:
			[cogit MoveMw: 0 r: SPReg R: TempReg.
			 cogit PushR: TempReg.
			 cogit MoveMw: objectMemory wordSize * 2 r: SPReg R: TempReg.
			 cogit MoveR: TempReg Mw: objectMemory wordSize r: SPReg.
			 cogit MoveR: ReceiverResultReg Mw: 2 * objectMemory wordSize r: SPReg.
			 ^self].
		 numArgs = 1 ifTrue:
			[cogit MoveMw: objectMemory wordSize r: SPReg R: TempReg.
			 cogit PushR: TempReg.
			 cogit MoveMw: objectMemory wordSize r: SPReg R: TempReg.
			 cogit PushR: TempReg.
			 cogit MoveR: ReceiverResultReg Mw: 3 * objectMemory wordSize r: SPReg.
			 cogit MoveR: Arg0Reg Mw: 2 * objectMemory wordSize r: SPReg.
			 ^self].
		 numArgs = 2 ifTrue:
			[cogit PushR: Arg1Reg.
			 cogit MoveMw: objectMemory wordSize * 2 r: SPReg R: TempReg.
			 cogit PushR: TempReg.
			 cogit MoveMw: objectMemory wordSize * 2 r: SPReg R: TempReg.
			 cogit PushR: TempReg.
			 cogit MoveR: ReceiverResultReg Mw: 4 * objectMemory wordSize r: SPReg.
			 cogit MoveR: Arg0Reg Mw: 3 * objectMemory wordSize r: SPReg.
			 ^self]]
]

{ #category : 'smalltalk calling convention' }
CogX86Compiler >> genPushRegisterArgsForPolymorphicSendTrampoline: numArgs scratchReg: scratchReg [
	"Ensure that the register args are pushed before the retpc at a
	 polymorphic send miss for arity <= self numRegArgs.  The retpc
	  is that of a call at a send site."

	"Putting the receiver and args above the return address means the
	 CoInterpreter has a single machine-code frame format which saves
	 us a lot of work."

	"Iff there are register args convert
	   sp      -> retpc      (send site retpc)
	 to
		base	->	receiver
					(arg0)
					(arg1)
		sp		->	retpc			(send site retpc)"

	numArgs <= cogit numRegArgs ifTrue: [ "
		Load retpc on scratch and replace it by the receiver"
		cogit MoveMw: 0 r: SPReg R: scratchReg.
		cogit MoveR: ReceiverResultReg Mw: 0 r: SPReg.
		1 <= numArgs ifTrue: [ cogit PushR: Arg0Reg ].
		2 <= numArgs ifTrue: [ cogit PushR: Arg1Reg ].
		self assert: numArgs <= 2.
		cogit PushR: scratchReg ]
]
