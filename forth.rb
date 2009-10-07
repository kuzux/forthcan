require 'rubygems'
require 'forth_parser'

class Object
  def fortheval(env,valstack,callstack)
    valstack.push self
	end
	alias_method :call, :fortheval
end

class NilClass
  def fortheval(e,v,c); end
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

class Array
  def pushn v
    self << v
		nil
	end
  def popn
    self.pop
    nil
  end
end

class Block
  attr_accessor :name
  def initialize(ast)
	  @inst = ast
		@iptr = 0
		@name = "<BLOCK>"
	end

	def eval_next(e,v,c)
		if @iptr >= @inst.length
      c.pop
			@iptr = 0
			return
		end
	  @inst[@iptr].fortheval(e,v,c)
    @iptr += 1
	end

	def call(e,v,c)
    c << self
		nil
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
	:"." => lambda do |e,v,c|
    num = v.pop; args = []
		num.times{ args << v.pop }
	  msg = v.pop; receiver = v.pop
		res = receiver.send(msg,*args)
	  v << res unless res.nil?	
	end,
	:";" => lambda do |e,v,c|
    name = v.pop.to_sym;	code = v.pop
		code.name = name
		e[name] = code
	end,
	:swap => lambda do |e,v,c|
    v1 = v.pop;	v2 = v.pop
		v << v1 << v2
	end,
	:rot => lambda do |e,v,c|
    v1 = v.pop;	v2 = v.pop; v3 = v.pop
		v << v2 << v1 << v3
	end,
	:dup => lambda do |e,v,c|
    val = v.pop
		v << val << val
	end,
	:true => lambda{|e,v,c| v << true},
	:false => lambda{|e,v,c| v << false},
	:ruby => lambda do |e,v,c|
    name = v.pop
		v << Kernel.const_get(name)
  end,
	:if => lambda do |e,v,c|
    xelse = v.pop; xthen = v.pop; cond = v.pop
		cond ? xthen.call(e,v,c) : xelse.call(e,v,c)
	end,
	:while => lambda do |e,v,c|
    body = v.pop; cond = v.pop
		while cond.call(e,v,c)
      body.call(e,v,c)
		end
	end,
}
STDLIB = "std/std.forth"

class Interpreter
  def initialize
	  @env = DEFAULTS
    @valstack = []
		@callstack = []
		@vars = {}
		@env[:stack] = lambda{|e,v,c| v << @valstack}
		@env[:callstack] = lambda{|e,v,c| v << @callstack}
		@env[:env] = lambda{|e,v,c| v << @env}
		@env[:vars] = lambda{|e,v,c| v << @vars}
		load_file STDLIB
	end
  
  def eval_str(str)
	  ast = parse_blocks ForthParser.parse(str)
    top = Block.new(ast)
	  top.name = "<TOPLEVEL>"
    top.call(@env,@valstack,@callstack)
	  until @callstack.empty?
      @callstack.last.eval_next(@env,@valstack,@callstack) 
		end
	end

	def load_file(name)
	  eval_str File.read(name) 
	end

	def repl
	  require 'readline'
		Readline.completion_proc = lambda{ |start| @env.keys.select{|x| x.to_s =~ /^#{Regexp.escape(start)}/} }
    while line = Readline.readline("> ",true)
		  begin
		    eval_str line
        p @valstack
			rescue StandardError => e
        puts "ERROR: #{e}"
				p @valstack, @callstack
			end
    end
	end
end

Interpreter.new.repl
