# frozen_string_literal: true

def generate_random_string(length)
    characters = ('a'..'z').to_a + ('A'..'Z').to_a + (0..9).to_a
    (0...length).map { characters[rand(characters.length)] }.join
end