class TestMailer < ApplicationMailer
  def test_email(to_address)
    @test_time = Time.current
    
    from_email = SiteSetting.get('default_from_email', 'noreply@railspress.com')
    from_name = SiteSetting.get('default_from_name', 'RailsPress')
    
    mail(
      from: "#{from_name} <#{from_email}>",
      to: to_address,
      subject: "Test Email from RailsPress - #{@test_time.strftime('%Y-%m-%d %H:%M:%S')}"
    )
  end
end




