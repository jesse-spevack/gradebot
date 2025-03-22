# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data, "https://fonts.gstatic.com", "https://docs.google.com", "https://fonts.sandbox.google.com"
    policy.img_src     :self, :https, :data, "https://docs.google.com"
    policy.object_src  :none
    policy.script_src  :self, :https, "https://apis.google.com", :unsafe_inline, :unsafe_eval
    policy.style_src   :self, :https, :unsafe_inline, "https://fonts.googleapis.com"
    policy.connect_src :self, :https, "https://docs.google.com"
    policy.frame_src   :self, :https, "https://docs.google.com"
    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Comment out the nonce generator, as it conflicts with unsafe_inline
  # config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  # config.content_security_policy_nonce_directives = %w(script-src style-src)

  # Report violations without enforcing the policy.
  config.content_security_policy_report_only = true
end
