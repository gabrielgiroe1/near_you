class NewReviewNotifier < Noticed::Event


  def message_provider
    "You have received a new review from #{params[:review]&.user&.name}."
  end

  def url
    provider_path(params[:review].provider)
  end
end 