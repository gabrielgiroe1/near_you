require "language_filter"

module LanguageFilter
  class << self
    attr_accessor :combined_filter
  end

  # Custom bad words list
  CUSTOM_BAD_WORDS = [
    # English Bad Words
    "fuck", "shit", "asshole", "bitch", "cunt", "bastard", "dick", "damn", "slut", "whore",
    "fag", "retard", "prick", "pussy", "bitchass", "motherfucker", "cock", "crap", "douchebag",
    "jackass", "sonofabitch",

    # Romanian Bad Words
    "mizerabil", "curvă", "prost", "idiot", "tâmpit", "mă-ta", "bădăran", "nenorocit", "porcar",
    "jivină", "gunoi", "jigodie", "sclav", "jigodă", "țărănuș", "țeapă", "rahat", "drac", "hoț"
  ].freeze

  # Combine all matchlists into one, including custom bad words
  combined_matchlist = CUSTOM_BAD_WORDS +
    LanguageFilter::Filter.new(matchlist: :hate).matchlist +
    LanguageFilter::Filter.new(matchlist: :profanity).matchlist +
    LanguageFilter::Filter.new(matchlist: :sex).matchlist +
    LanguageFilter::Filter.new(matchlist: :violence).matchlist

  # Ensure the combined matchlist is not empty
  if combined_matchlist.empty?
    raise LanguageFilter::EmptyContentList, "Combined matchlist is empty. Please check your custom bad words and predefined matchlists."
  end

  # Create a new combined filter with unique entries
  self.combined_filter = LanguageFilter::Filter.new(
    matchlist: combined_matchlist.uniq, # Ensure uniqueness
    replacement: :stars # or :garbled, :vowels, etc. based on your preference
  )
end
