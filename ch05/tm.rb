# DCM(deterministic turing mathine)

class Tape < Struct.new(:left, :middle, :right, :blank)
    def inspect
        "#<Tape #{left.join} (#{middle})#{right.join}>"
    end

    def write(character)
        Tape.new(left, character, right, blank)
    end

    def move_head_left
        Tape.new(left[0..-2], left.last || blank, [middle] + right, blank)
    end

    def move_head_right
        Tape.new(left + [middle], right.first || blank, right.drop(1), blank)
    end
end

class TMConfiguration < Struct.new(:state, :tape)
end

class TMRule < Struct.new(:state, :character, :next_state,
                            :write_character, :direction)
    def applies_to?(configuration)
        state == configuration.state && character == configuration.tape.middle
    end

    def follow(configuration)
        TMConfiguration.new(next_state, next_tape(configuration))
    end

    def next_tape(configuration)
        written_tape = configuration.tape.write(write_character)

        case direction
        when :left
            written_tape.move_head_left
        when :right
            written_tape.move_head_right
        end
    end
end

#####################################################################


# tape = Tape.new(["1", "0", "1"], "1", [], "_")
# puts tape.inspect
# tape = tape.move_head_left
# puts tape.inspect
# tape = tape.write("0")
# puts tape.inspect
# tape = tape.move_head_right
# puts tape.inspect
# tape = tape.move_head_right.write("0")
# puts tape.inspect

rule = TMRule.new(1, "0", 2, "1", :right)
puts rule.applies_to?(TMConfiguration.new(1, Tape.new([], "0", [], "_")))
puts rule.applies_to?(TMConfiguration.new(1, Tape.new([], "1", [], "_")))
puts rule.applies_to?(TMConfiguration.new(2, Tape.new([], "0", [], "_")))
