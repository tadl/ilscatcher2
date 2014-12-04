class MelmismatchMailer < ActionMailer::Base
  default from: "tech@tadl.org"

  def melmismatch_email(bad_links)
  	@users = ENV["emails"]
  	@bad_links = bad_links
  	mail to: @users, subject: 'TADL - Mel Mismatched links'
  end

end