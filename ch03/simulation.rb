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
end

#####################################################################

# DFAの例

# rulebook = DFARulebook.new([
#     FARule.new(1, "a", 2), FARule.new(1, "b", 1),
#     FARule.new(2, "a", 2), FARule.new(2, "b", 3),
#     FARule.new(3, "a", 3), FARule.new(3, "b", 3)
#     ])

# puts rulebook.next_state(1, "a")
# puts rulebook.next_state(1, "b")
# puts rulebook.next_state(2, "b")

# puts DFA.new(1, [1, 3], rulebook).accepting?
# puts DFA.new(1, [3], rulebook).accepting?

# dfa = DFA.new(1, [3], rulebook);
# puts dfa.accepting?
# dfa.read_character("b");
# puts dfa.accepting?
# 3.times do dfa.read_character("a") end;
# puts dfa.accepting?
# dfa.read_character("b");
# puts dfa.accepting?

# dfa = DFA.new(1, [3], rulebook);
# puts dfa.accepting?
# # automaton上を文字baaabと読んで、状態を移動する。
# # 受理状態の3に移動するため, dfa.accepting?はtrueを返す
# dfa.read_string("baaab")
# puts dfa.accepting?

# dfa_design = DFADesign.new(1, [3], rulebook)
# puts dfa_design.accepts?("a")
# puts dfa_design.accepts?("baa")
# puts dfa_design.accepts?("baba")

#####################################################################

# class FARule < Struct.new(:state, :character, :next_state)
rulebook = NFARulebook.new([
    FARule.new(1, "a", 1), FARule.new(1, "b", 1), FARule.new(1, "b", 2),
    FARule.new(2, "a", 3), FARule.new(2, "b", 3),
    FARule.new(3, "a", 4), FARule.new(3, "b", 4)
    ])

# puts rulebook.next_states(Set[1], "b")
# puts rulebook.next_states(Set[1, 2], "a")
# puts rulebook.next_states(Set[1, 3], "b")

# puts NFA.new(Set[1], [4], rulebook).accepting?
# puts NFA.new(Set[1, 2, 4], [4], rulebook).accepting?

nfa = NFA.new(Set[1], [4], rulebook); puts nfa.accepting?
nfa.read_character('b'); puts nfa.accepting?
nfa.read_character('a'); puts nfa.accepting?
nfa.read_character('b'); puts nfa.accepting?

nfa = NFA.new(Set[1], [4], rulebook); puts nfa.accepting?
nfa.read_string("bbbbb"); puts nfa.accepting?
