require 'rparsec'

module ForthParser
  extend RParsec::Parsers

  def self.stringer(opener, closer=nil, translate={})
    closer = opener if closer.nil?
    escape = (string('\\') >> any).map do |charnum|
      escaped = charnum.chr
      translate[escaped] || escaped
    end
    open   = string(opener)
    close  = string(closer)
    other  = not_string(closer).map{|charnum| charnum.chr }
    string = (open >> (escape|other).many << close).map {|strings| strings.to_s }
  end

  Integer = regexp(/-?\d+(?!\w)/).map{|x| x.to_i }
  Float = regexp(/-?\d+(\.\d+)?/).map{|x| x.to_f }
  Number = longest(Integer, Float)
  Special = Regexp.escape('+*/=<>?!@#$%^&:\\~|^.;')
  Symbol = regexp(/[\w#{Special}]*[A-Za-z#{Special}][\w#{Special}]*/).map{|s| s.to_sym }
  String = stringer(%q{"}, %q{"}, "n" => "\n", "t" => "\t")
	Block = char("[") >> lazy{Exprs} << char("]")
	
	Comment = char("(") >> regexp(/[^()]*/).map{|x| nil} << char(")")
	Expr = whitespace.many_ >> alt(Number,Symbol,String,Block,Comment) << whitespace.many_
	Exprs = Expr.many
	Parser = Exprs << eof

	def self.parse str
    denilify Parser.parse str
	end
	protected
  def self.denilify(list)
    list.reject{|x| x.nil?}.map{|x| x.is_a?(Array) ? denilify(x) : x}
  end
end
