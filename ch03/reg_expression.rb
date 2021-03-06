require "set"

#####################################################################
# DFA: Deterministic Finite Automaton
#####################################################################

# Finite Automaton
class FARule < Struct.new(:state, :character, :next_state)
    def applies_to?(state, character)
        self.state == state && self.character == character
    end

    def follow
        next_state
    end

    def inspect
        "#<FARule #{state.inspect} --#{character}--> #{next_state.inspect}"
    end
end

class DFARulebook < Struct.new(:rules)
    def next_state(state, character)
        rule_for(state, character).follow
    end

    def rule_for(state, character)
        rules.detect { |rule| rule.applies_to?(state, character) }
    end
end

# Deterministic Finite Automaton
class DFA < Struct.new(:current_state, :accept_state, :rulebook)
    def accepting?
        accept_state.include?(current_state)
    end

    def read_character(character)
        self.current_state = rulebook.next_state(current_state, character)
    end

    def read_string(string)
        string.chars.each do |character|
            read_character(character)
        end
    end
end

class DFADesign < Struct.new(:start_state, :accept_state, :rulebook)
    def to_dfa
        DFA.new(start_state, accept_state, rulebook)
    end

    def accepts?(string)
        to_dfa.tap { |dfa| dfa.read_string(string) }.accepting?
    end
end

#####################################################################
# NFA: Non-deterministic Finite Automaton
#####################################################################

class NFARulebook < Struct.new(:rules)
    def next_states(states, character)
        states.flat_map { |state| follow_rules_for(state, character) }.to_set
    end

    def follow_rules_for(state, character)
        rules_for(state, character).map(&:follow)
    end

    def rules_for(state, character)
        rules.select { |rule| rule.applies_to?(state, character) }
    end

    def follow_free_moves(states)
        more_states = next_states(states, nil)

        if more_states.subset?(states)
            states
        else
            follow_free_moves(states + more_states)
        end
    end
end

class NFA < Struct.new(:current_states, :accept_states, :rulebook)
    def accepting?
        (current_states & accept_states).any?
    end

    def read_character(character)
        self.current_states = rulebook.next_states(current_states, character)
    end

    def read_string(string)
        string.chars.each do |character|
            read_character(character)
        end
    end

    def current_states
        rulebook.follow_free_moves(super)
    end
end

class NFADesign < Struct.new(:start_state, :accept_states, :rulebook)
    def accepts?(string)
        to_nfa.tap { |nfa| nfa.read_string(string) }.accepting?
    end

    def to_nfa
        NFA.new(Set[start_state], accept_states, rulebook)
    end
end

#####################################################################
# Regular expression
#####################################################################

module Pattern
    def bracket(outer_precedence)
        if precedence < outer_precedence
            "(" + to_s + ")"
        else
            to_s
        end
    end

    def inspect
        "/#{self}/"
    end

    def matches?(string)
        to_nfa_design.accepts?(string)
    end
end

class Empty
    include Pattern

    def to_s
        ""
    end

    def precedence
        3
    end

    def to_nfa_design
        start_state = Object.new
        accept_states = [start_state]
        rulebook = NFARulebook.new([])

        NFADesign.new(start_state, accept_states, rulebook)
    end
end

class Literal < Struct.new(:character)
    include Pattern

    def to_s
        character
    end

    def precedence
        3
    end

    def to_nfa_design
        start_state = Object.new
        accept_state = Object.new
        rule = FARule.new(start_state, character, accept_state)
        rulebook = NFARulebook.new([rule])

        NFADesign.new(start_state, [accept_state], rulebook)
    end
end

class Concatenate < Struct.new(:first, :second)
    include Pattern

    def to_set
        [first, second].map { |pattern| pattern.bracket(precedence)}.join
    end

    def precedence
        1
    end
end

class Choose < Struct.new(:first, :second)
    include Pattern

    def to_s
        [first, second].map { |pattern| pattern.bracket(precedence) }.join
    end

    def precedence
        0
    end
end

class Repeat < Struct.new(:pattern)
    include Pattern

    def to_s
        pattern.bracket(precedence) + "*"
    end

    def precedence
        2
    end
end

#####################################################################

nfa_design = Empty.new.to_nfa_design
puts nfa_design.accepts?("")
puts nfa_design.accepts?("a")
nfa_design = Literal.new("a").to_nfa_design
puts nfa_design.accepts?("")
puts nfa_design.accepts?("a")
puts nfa_design.accepts?("b")

rule
