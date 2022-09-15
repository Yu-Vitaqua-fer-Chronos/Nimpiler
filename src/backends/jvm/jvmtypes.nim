type
  Method* = object
    name*: string           # For constructors, it's `<init>` as an example. `main` for the main method.
    arguments*: seq[string] #  Types of arguments, names are irrelavant.
    body*: seq[string]      # Will make an actual instruction... Thing after, just need to test

  Class* = object
    source*: string          # Apparently good practice to have the source included
    name*: string            # Main, for top-level statements
    extends*: string         # Full name of the class it extends, by default it's `java/lang/Object`
    implements*: seq[string] # All interfaces it implements
    methods*: seq[Method]    # All methods that the class has.
    public*: bool            # Is it public?
    final*: bool              # Is it final?
    statik*: bool            # Is it static?


proc newClass*(source, name: string, # Mandatory arguments
    extends: string="java/lang/Object",
    implements: seq[string]=newSeq[string](0),
    public: bool=false, statik: bool=false, final: bool=false
  ): Class =

  result = Class(source:source, name:name, extends:extends, implements:implements,
  public:public, statik:statik, final:final, methods:newSeq[Method](0))