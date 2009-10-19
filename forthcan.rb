#!/usr/bin/ruby 
require 'rubygems'
require 'forth_parser'

module Forthcan
  class Block
    attr_accessor :name
    def initialize(ast)
      @inst = ast
      @name = "<BLOCK>"
    end
    
    def length
      @inst.length
    end
    
    def [](i)
      @inst[i]
    end

    def call(st)
      Forthcan::Continuation.new(self).call(st)
    end

    def to_proc(st)
      cont = Forthcan::Continuation.new(self)
      lambda do |*args|
        args.each{ |a| st.valstack << a }
        cont.call
        while c.include? cont
          st.eval_next
        end
      end
    end

    def self.parse_blocks(data)
      data.map do |d|
        if d.is_a? Array
          Block.new parse_blocks(d)
        else
          d
        end
      end
    end
  end
  
  class Continuation
    def initialize(block)
      @block = block
      @iptr = 0
    end
    
    def eval_next(st)
      if @iptr >= @block.length
        st.callstack.pop
        return
      end
      @block[@iptr].fortheval(st)
      @iptr += 1
    end
    
    def name
      @block.name
    end
    
    def call(st)
      if @block.is_a? Proc
        @block.call(st)
        return
      end
      
      st.callstack << self
      nil
    end
  end

  DEFAULTS = {
    :"." => lambda do |st|
      v = st.valstack
      num = v.pop; args = []
      num.times{ args << v.pop }
      msg = v.pop; receiver = v.pop
      res = receiver.send(msg,*args)
      v << res unless res.nil?  
    end,
    :"::" => lambda do |st|
      v = st.valstack
      child = v.pop
      parent = v.pop
      v << parent.const_get(child)
    end,
    :";" => lambda do |st|
      v = st.valstack
      name = v.pop.to_sym;  code = v.pop
      code.name = name
      st.env[name] = code
    end,
    :swap => lambda do |st|
      v = st.valstack
      v1 = v.pop;  v2 = v.pop
      v << v1 << v2
    end,
    :rot => lambda do |st|
      v = st.valstack
      v1 = v.pop;  v2 = v.pop; v3 = v.pop
      v << v2 << v1 << v3
    end,
    :dup => lambda do |st|
      v = st.valstack
      val = v.pop
      v << val << val
    end,
    :true => lambda{|st| st.valstack << true},
    :false => lambda{|st| st.valstack << false},
    :ruby => lambda do |st|
      v = st.valstack
      name = v.pop
      v << Kernel.const_get(name)
    end,
    :if => lambda do |st|
      v = st.valstack
      xelse = v.pop; xthen = v.pop; cond = v.pop
      cond ? xthen.call(st) : xelse.call(st)
    end,
    :while => lambda do |st|
      v = st.valstack
      body = v.pop; cond = v.pop
      condp = lambda{ cond.call(st); v.pop }
      while r = condp.call
        body.call(st)
      end
    end,
		:stack => lambda{|st| st.valstack << st.valstack},
		:callstack => lambda{|st| st.valstack << st.callstack},
		:env => lambda{|st| st.valstack << st.env},
		:vars => lambda{|st| st.valstack << st.vars},
  }
  STDLIB = "std/std.forth"

  module CoreExt
    module Object
      def fortheval(st)
        st.valstack.push self
      end
      alias_method :call, :fortheval
    end
    
    module Nil
      def fortheval(st); end
    end
    
    module Symbol
      def fortheval(st)
        if st.env.has_key? self
          st.env[self].call(st)
        else
          raise "No word called #{self}"
        end
      end
    end
    
    module Array
      def pushn v
        self << v
        nil
      end
      def popn
        self.pop
        nil
      end
    end
  end

  class State
    attr_reader :valstack, :callstack, :env, :vars
    def initialize(env)
      @env = env
      @valstack = []
      @callstack = []
      @vars = {}
    end
  end

  class Interpreter
    attr_reader :valstack, :callstack, :env, :vars
    def initialize
      @state = State.new(DEFAULTS)
      ::Object.send(:include, CoreExt::Object)
      ::NilClass.send(:include, CoreExt::Nil)
      ::Symbol.send(:include, CoreExt::Symbol)
      ::Array.send(:include, CoreExt::Array)
      load_file STDLIB
    end
    
    def eval_str(str)
      ast = Block.parse_blocks ForthParser.parse(str)
      top = Block.new(ast)
      top.name = "<TOPLEVEL>"
      Continuation.new(top).call(@state)
      eval_next until @state.callstack.empty?
    end

    def eval_next
      @state.callstack.last.eval_next(@state)
    end

    def load_file(name)
      eval_str File.read(name)
    end

    def repl
      require 'readline'
      Readline.completion_proc = lambda{ |start| @state.env.keys.select{|x| x.to_s =~ /^#{Regexp.escape(start)}/} }
      while line = Readline.readline("> ",true)
        begin
          eval_str line
          p @state.valstack
        rescue StandardError => e
          puts "ERROR: #{e}"
          p @state.valstack, @state.callstack.map{|c| c.name}
        end
      end
    end
  end
end

if __FILE__ == $0
  int = Forthcan::Interpreter.new
  if ARGV.size >= 1
    int.load_file(ARGV[0])
  end
  int.repl
end
