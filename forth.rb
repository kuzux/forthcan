require 'rubygems'
require 'forth_parser'

class Object
  def fortheval(env,valstack,callstack)
    valstack.push self
	end
	def call(e,v,c)
    fortheval e,v,c
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
	end,
	:";" => lambda do |env,valstack,callstack|
    name = valstack.pop.to_sym
		code = valstack.pop
		env[name] = code
	end,
	:swap => lambda do |env,valstack,callstack|
    v1 = valstack.pop
		v2 = valstack.pop
		valstack << v1 << v2
	end,
	:rot => lambda do |e,v,c|
    v1 = v.pop
		v2 = v.pop
		v3 = v.pop
		v << v2 << v1 << v3
	end,
	:pop => lambda { |e,v,c| v.pop },
	:dup => lambda do |e,v,c|
    val = v.pop
		v << val << val
	end,
	:true => lambda{|e,v,c| v << true},
	:false => lambda{|e,v,c| v << false},
	:if => lambda do |e,v,c|
    xelse = v.pop
	  xthen = v.pop
		cond = v.pop
		if cond
      xthen.call(e,v,c)
		else
			xelse.call(e,v,c)
		end
	end
}
STDLIB = "std/std.forth"

class Interpreter
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

	def repl
	  require 'readline'
    while line = Readline.readline("> ",true)
		  begin
		    eval_str line
			  p @valstack
			rescue StandardError => e
        puts "ERROR: #{e}"
				p @callstack
			end
    end
	end
end

Interpreter.new.repl
