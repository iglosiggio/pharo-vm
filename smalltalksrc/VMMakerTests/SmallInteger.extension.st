Extension { #name : 'SmallInteger' }

{ #category : '*VMMakerTests' }
SmallInteger >> forMemory: aMemory inMethod: anObject [
	
	self assert: (self between: aMemory minSmallInteger and: aMemory maxSmallInteger).
	
	^ aMemory integerObjectOf: self
]
