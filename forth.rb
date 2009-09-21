require 'rubygems'
require 'forth_parser'

class Object
  def fortheval(env,valstack,callstack)
    valstack.push self
	end
end

class Symbol
  def fortheval(env,valstack,callstack)
    if env.has_key? self
      env[self].call(env,valstack,callstack)
	  else
		  raise "No word called #{self}"
		end
	end
end

class Block
  def initialize(ast)
	  @inst = ast
	end

	def call(env,valstack, callstack)
    callstack << self
    @inst.each do |i|
      i.fortheval(env,valstack,callstack)
		end
		callstack.pop
	end
end

def parse_blocks(data)
	data.map do |d|
    if d.is_a? Array
		  Block.new parse_blocks(d)
		else
      d
		end
  end
end

DEFAULTS = {
	:"." => lambda do |env,valstack,callstack|
    num = valstack.pop
		args = []
		num.times{ args << valstack.pop }
	  msg = valstack.pop
		receiver = valstack.pop
		valstack.push receiver.send(msg,*args)
	end
	:";" => lambda do |env,valstack,callstack|
    name = valstack.pop.to_sym
		code = valstack.pop
		env[name] = code
	end
}
STDLIB = "std/std.forth"


class Interpreter
  attr_reader :valstack
  def initialize
	  @env = DEFAULTS
    @valstack = []
		@callstack = []
		load_file STDLIB
	end
  
  def eval_str(str)
	  ast = parse_blocks ForthParser.parse(str)
    Block.new(ast).call(@env,@valstack,@callstack)
	end

	def load_file(name)
	  eval_str File.read(name) 
	end
end

