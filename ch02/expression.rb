class Number < Struct.new(:value)
    def to_s
        value.to_s
    end

    def reducible?
        false
    end

    def inspect
        "<<#{self}>>"
    end
end

class Add < Struct.new(:left, :right)
    def to_s
        "<<#{left} + #{right}>>"
    end

    def reducible?
        true
    end

    def reduce
        if left.reducible?
            Add.new(left.reduce, right)
        elsif right.reducible?
            Add.new(left, right.reduce)
        else
            Number.new(left.value + right.value)
        end
    end

    # オブジェクトをわかりやすい文字列にして返す
    def inspect
        "<<#{self}>>"
    end
end

class Multiply < Struct.new(:left, :right)
    def to_s
        "<<#{left} * #{right}>>"
    end

    def reducible?
        true
    end

    def reduce
        if left.reducible?
            Multiply.new(left.reduce, right)
        elsif right.reducible?
            Multiply.new(left, right.reduce)
        else
            Number.new(left.value * right.value)
        end
    end

    def inspect
        "<<#{self}>>"
    end
end

class Machine < Struct.new(:expression)
    def step
        self.expression = expression.reduce
    end

    def run
        while expression.reducible?
            puts expression
            step
        end
        puts expression
    end
end

class Boolean < Struct.new(:value)
    def to_s
        value.to_s
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        false
    end
end

class LessThan < Struct.new(:left, :right)
    def to_s
        "#{left} < #{right}"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce
        if left.reducible?
            LessThan.new(left.reduce, right)
        elsif right.reducible?
            LessThan.new(left, right.reduce)
        else
            Boolean.new(left.value < right.value)
        end
    end
end


# puts Number.new(3)
# puts Number.new(3).class
#
# puts Number.new(3).value
# puts Number.new(3).value.class
#
# puts Number.new(3).value.to_s
# puts Number.new(3).value.to_s.class



# m = Machine.new(
#         Add.new(
#             Multiply.new(Number.new(3), Number.new(5)),
#             Multiply.new(Number.new(7), Number.new(9))
#         )
#     ).run

m = Machine.new(
        LessThan.new(Number.new(5), Add.new(Number.new(2), Number.new(2)))
    ).run
