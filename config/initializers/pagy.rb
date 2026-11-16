# frozen_string_literal: true

Pagy::OPTIONS[:limit]       = 10                    # default
Pagy::OPTIONS[:overflow] = :last_page    # default  (other options: :last_page and :exception)
Pagy::OPTIONS.freeze
