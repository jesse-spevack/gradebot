require "application_system_test_case"

class NavbarTest < ApplicationSystemTestCase
  test "unauthenticated user sees only logo and sign in button" do
    visit root_url

    # Verify the logo is visible in the header
    assert_selector "header .logo", count: 1

    # Verify the sign in button is visible
    assert_selector "header button", text: /Sign in/i, count: 1

    # Verify the sidebar is not visible
    assert_no_selector "#mobile-sidebar[data-controller='sidebar']", visible: :all
    assert_no_selector "div.lg\\:fixed.lg\\:flex.lg\\:w-72", visible: :all
  end

  test "authenticated user sees logo in sidebar, sign out button in header" do
    # Log in as a normal user
    user = users(:teacher)
    login_as(user)

    visit root_url

    # Verify the logo is NOT visible in the header but is in the sidebar
    assert_no_selector "header a.logo"

    # Verify either mobile or desktop sidebar is present (depending on viewport size)
    sidebar_exists = has_selector?("#mobile-sidebar .logo", visible: :all) ||
                    has_selector?("div.lg\\:fixed.lg\\:flex.lg\\:w-72 .logo", visible: :all)
    assert sidebar_exists, "No sidebar logo found in either mobile or desktop view"

    # Verify the sign out button is visible in the header
    assert_selector "header a[data-turbo-method='delete']", count: 1

    # Verify regular navigation links exist in either mobile or desktop view
    assert has_selector?("a", text: "My Grading Tasks", count: 1, visible: true),
          "No 'My Grading Tasks' link found"

    # Verify admin links are not visible for regular users
    assert_no_selector "a", text: "Feature Flags", visible: :all
    assert_no_selector "a", text: "LLM Pricing", visible: :all
    assert_no_selector "a", text: "Cost Reports", visible: :all
  end

  test "admin user sees admin links in sidebar" do
    # Log in as an admin user
    admin = users(:admin)
    login_as(admin)

    visit root_url

    # Verify the admin links exist in either mobile or desktop view
    assert has_selector?("a", text: "Feature Flags", count: 1, visible: true),
          "No 'Feature Flags' link found"
    assert has_selector?("a", text: "LLM Pricing", count: 1, visible: true),
          "No 'LLM Pricing' link found"
    assert has_selector?("a", text: "Cost Reports", count: 1, visible: true),
          "No 'Cost Reports' link found"
  end
end
