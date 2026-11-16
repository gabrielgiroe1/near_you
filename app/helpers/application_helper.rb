module ApplicationHelper
  # Remove or comment out the Gravatar method if it's no longer needed
  # def gravatar_url(email, size = 200)
  #   gravatar_id = Digest::MD5.hexdigest(email.downcase)
  #   "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}&d=identicon"
  # end

  def google_maps_directions_url(location)
    "https://www.google.com/maps/dir/?api=1&destination=#{CGI.escape(location)}"
  end
end
