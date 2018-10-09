# Using a big-step semantics, we interpret the simple-lang.
# Each class has evaluate method and using a this method
# we RECURSIVELY interpret the simple-lang.

#####################################################################
# expression
#####################################################################

class Number < Struct.new(:value)
    def to_s
        value.to_s
    end

    def evaluate(environment)
        self
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

    def evaluate(environment)
        Number.new(left.evaluate(environment).value + right.evaluate(environment).value)
    end

    def reduce(environment)
        if left.reducible?
            Add.new(left.reduce(environment), right)
        elsif right.reducible?
            Add.new(left, right.reduce(environment))
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

    def evaluate(environment)
        Number.new(left.evaluate(environment).value * right.evaluate(environment).value)
    end

    def reduce(environment)
        if left.reducible?
            Multiply.new(left.reduce(environment), right)
        elsif right.reducible?
            Multiply.new(left, right.reduce(environment))
        else
            Number.new(left.value * right.value)
        end
    end

    def inspect
        "<<#{self}>>"
    end
end

class Machine < Struct.new(:statement, :environment)
    def step
        self.statement, self.environment = statement.reduce(environment)
    end

    def run
        while statement.reducible?
            puts "#{statement}, #{environment}"
            step
        end

        puts "#{statement}, #{environment}"
    end
end

class Boolean < Struct.new(:value)
    def to_s
        value.to_s
    end

    def evaluate(environment)
        self
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

    def evaluate(environment)
        Number.new(left.evaluate(environment).value < right.evaluate(environment).value)
    end

    def reducible?
        true
    end

    def reduce(environment)
        if left.reducible?
            LessThan.new(left.reduce(environment), right)
        elsif right.reducible?
            LessThan.new(left, right.reduce(environment))
        else
            Boolean.new(left.value < right.value)
        end
    end
end

class Variable < Struct.new(:name)
    def to_s
        name.to_s
    end

    def inspect
        "<<#{self}>>"
    end

    def evaluate(environment)
        environment[name]
    end

    def reduce(environment)
        environment[name]
    end

    def reducible?
        true
    end
end


#####################################################################
# statement
#####################################################################

class DoNothing
    def to_s
        "do-nothing"
    end

    def inspect
        "<<#{self}>>"
    end

    def ==(other_statement)
        other_statement.instance_of?(DoNothing)
    end

    def evaluate(environment)
        environment
    end

    def reducible?
        false
    end
end

class Assign < Struct.new(:name, :expression)
    def to_s
        "#{name} = #{expression}"
    end

    def inspect
        "<<#{self}>>"
    end

    def evaluate(environment)
        environment.merge({ name => expression.evaluate(environment) })
    end

    def reducible?
        true
    end

    def reduce(environment)
        if expression.reducible?
            [Assign.new(name, expression.reduce(environment)), environment]
        else
            [DoNothing.new, environment.merge({name => expression})]
        end
    end
end

class If < Struct.new(:condition, :consequence, :alternative)
    def to_s
        "if (#{condition}) { #{consequence} } else { #{alternative} }"
    end

    def inspect
        "<<#{self}>>"
    end

    def evaluate(environment)
        case condition.evaluate(environment)
        when Boolean.new(true)
            consequence.evaluate(environment)
        when Boolean.new(false)
            alternative.evaluate(environment)
        end
    end

    def reducible?
        true
    end

    def reduce(environment)
        if condition.reducible?
            [If.new(condition.reduce(environment), consequence, alternative), environment]
        else
            case condition
            when Boolean.new(true)
                [consequence, environment]
            when Boolean.new(false)
                [alternative, environment]
            end
        end
    end
end


# sequence文: <<x = 1 + 1; y = x + 3; z = y + 5>>
class Sequence < Struct.new(:first, :second)
    def to_s
        "#{first}; #{second}"
    end

    def inspect
        "<<#{self}>>"
    end

    def evaluate(environment)
        second.evaluate(first.evaluate(environment))
    end

    def reducible?
        true
    end

    def reduce(environment)
        case first
        when DoNothing.new
            [second, environment]
        else
            reduced_first, reduced_environment = first.reduce(environment)
            [Sequence.new(reduced_first, second), reduced_environment]
        end
    end
end

class While < Struct.new(:condition, :body)
    def to_s
        "while (#{condition}) { #{body} }"
    end

    def inspect
        "<<#{self}>>"
    end

    def evaluate(environment)
        case condition.evaluate(environment)
        when Boolean.new(true)
            evaluate(body.evaluate(environment))
        when Boolean.new(false)
            environment
        end
    end

    def reducible?
        true
    end

    def reduce(environment)
        [If.new(condition, Sequence.new(body, self), DoNothing.new), environment]
    end
end


#####################################################################



# x = Number.new(23).evaluate({})
# puts x
# y = Variable.new(:x).evaluate({x: Number.new(2)})
# puts y
# z = LessThan.new(
#     Add.new(Variable.new(:x), Number.new(2)),
#     Variable.new(:y)
# ).evaluate({x: Number.new(2), y: Number.new(5)})
# puts z

# statement =
#     Sequence.new(
#         Assign.new(:x, Add.new(Number.new(1), Number.new(1))),
#         Assign.new(:y, Add.new(Variable.new(:x), Number.new(3)))
#     )
# puts statement
# puts statement.evaluate({})

statement =
    While.new(
        LessThan.new(Variable.new(:x), Number.new(5)),
        Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
    )
puts statement
puts statement.evaluate({ x: Number.new(1) })
