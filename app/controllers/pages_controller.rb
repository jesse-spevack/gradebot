class PagesController < ApplicationController
  allow_unauthenticated_access only: [ :privacy, :terms ]

  def privacy
  end

  def terms
  end
end
