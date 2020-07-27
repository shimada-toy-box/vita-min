require "rails_helper"

RSpec.feature "Web Intake Joint Filers" do
  let(:ticket_id) { 9876 }

  before do
    allow_any_instance_of(ZendeskIntakeService).to receive(:create_intake_ticket_requester).and_return(4321)
    allow_any_instance_of(ZendeskIntakeService).to receive(:create_intake_ticket).and_return(ticket_id)
    # see note below about skipping redirects
  end

  scenario "new client filing joint taxes with spouse and dependents" do
    # Home
    visit "/"
    find("#firstCta").click

    # Welcome
    expect(page).to have_selector("h1", text: "Welcome! How can we help you?")
    click_on "File taxes with help"

    # File With Help
    expect(current_path).to eq(file_with_help_questions_path)
    click_on "Continue"

    # Ask about backtaxes
    expect(page).to have_selector("h1", text: "What years do you need to file for?")
    check "2019"
    click_on "Continue"

    #Non-production environment warning
    expect(page).to have_selector("h1", text: "Thanks for visiting the GetYourRefund demo application!")
    click_on "Continue to example"

    expect(page).to have_selector("h1", text: "Let's get started")
    click_on "Continue"

    # VITA eligibility checks
    expect(page).to have_selector("h1", text: "Let’s check a few things.")
    check "None of the above"
    click_on "Continue"

    # Overview
    expect(page).to have_selector("h1", text: "Just a few simple steps to file!")
    click_on "Continue"

    # Personal Info
    expect(page).to have_selector("h1", text: "First, let's get some basic information.")
    fill_in "Preferred name", with: "Gary"
    fill_in "ZIP code", with: "20121"
    click_on "Continue"

    # Chat with us
    expect(page).to have_selector("h1", text: "Our team at United Way of Greater Richmond and Petersburg is here to help!")
    click_on "Continue"

    # Phone number
    expect(page).to have_selector("h1", text: "Please share your contact number.")
    fill_in "Phone number", with: "(415) 553-7865"
    fill_in "Confirm phone number", with: "(415) 553-7865"
    click_on "Continue"

    # Email
    expect(page).to have_selector("h1", text: "Please share your e-mail address.")
    fill_in "E-mail address", with: "gary.gardengnome@example.green"
    fill_in "Confirm e-mail address", with: "gary.gardengnome@example.green"
    click_on "Continue"

    # Notification Preference
    expect(page).to have_text("How can we update you on your tax return?")
    check "Email Me"
    click_on "Continue"

    # Consent form
    expect(page).to have_selector("h1", text: "Great! Here's the legal stuff...")
    fill_in "Legal first name", with: "Gary"
    fill_in "Legal last name", with: "Gnome"
    fill_in "Last 4 of SSN/ITIN", with: "1234"
    select "March", from: "Month"
    select "5", from: "Day"
    select "1971", from: "Year"
    click_on "I agree"

    # right about here, our intake gets an intake_ticket_id in a background job
    allow_any_instance_of(Intake).to receive(:intake_ticket_id).and_return(ticket_id)

    # Primary filer personal information
    expect(page).to have_selector("h1", text: "Were you a full-time student in 2019?")
    click_on "No"
    expect(page).to have_selector("h1", text: "In 2019, were you in the United States on a Visa?")
    click_on "No"
    expect(page).to have_selector("h1", text: "In 2019, did you have a permanent disability?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, were you legally blind?")
    click_on "No"
    expect(page).to have_selector("h1", text: "Have you ever been issued an IP PIN because of identity theft?")
    click_on "No"

    # Marital status
    expect(page).to have_selector("h1", text: "Have you ever been legally married?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "As of December 31, 2019, were you legally married?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "Did you live with your spouse during any part of the last six months of 2019?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "Are you legally separated?")
    click_on "No"
    expect(page).to have_selector("h1", text: "As of December 31, 2019, were you divorced?")
    click_on "No"
    expect(page).to have_selector("h1", text: "As of December 31, 2019, were you widowed?")
    click_on "No"

    # Filing status
    expect(page).to have_selector("h1", text: "Are you filing joint taxes with your spouse?")
    click_on "Yes"

    # Alimony
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse receive any income from alimony?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse make any alimony payments?")
    click_on "Yes"

    # Spouse email
    expect(page).to have_selector("h1", text: "Please share your spouse's e-mail address")
    fill_in "E-mail address", with: "greta.gardengnome@example.green"
    fill_in "Confirm e-mail address", with: "greta.gardengnome@example.green"
    click_on "Continue"

    # Spouse consent
    expect(page).to have_selector("h1", text: "We need your spouse to review our legal stuff...")
    fill_in "Spouse's legal first name", with: "Greta"
    fill_in "Spouse's legal last name", with: "Gnome"
    fill_in "Last 4 of SSN/ITIN", with: "1234"
    select "March", from: "Month"
    select "5", from: "Day"
    select "1971", from: "Year"
    click_on "I agree"

    # Spouse personal information
    expect(page).to have_selector("h1", text: "Was your spouse a full-time student in 2019?")
    click_on "No"
    expect(page).to have_selector("h1", text: "In 2019, was your spouse in the United States on a Visa?")
    click_on "No"
    expect(page).to have_selector("h1", text: "In 2019, did your spouse have a permanent disability?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, was your spouse legally blind?")
    click_on "No"
    expect(page).to have_selector("h1", text: "Has your spouse been issued an Identity Protection PIN?")
    click_on "No"

    # Dependents
    expect(page).to have_selector("h1", text: "Would you or your spouse like to claim anyone for 2019?")
    click_on "Yes"

    expect(page).to have_selector("h1", text: "Let’s claim someone!")
    expect(track_progress).to be_present
    click_on "Add a person"
    fill_in "First name", with: "Greg"
    fill_in "Last name", with: "Gnome"
    select "March", from: "Month"
    select "5", from: "Day"
    select "2003", from: "Year"
    fill_in "Relationship to you", with: "Son"
    select "6", from: "How many months did they live in your home in 2019?"
    check "Full time higher education student"
    click_on "Save this person"
    expect(page).to have_text("Greg Gnome")

    click_on "Add a person"
    fill_in "First name", with: "Gallagher"
    fill_in "Last name", with: "Gnome"
    select "November", from: "Month"
    select "24", from: "Day"
    select "2005", from: "Year"
    fill_in "Relationship to you", with: "Nibling"
    select "2", from: "How many months did they live in your home in 2019?"
    check "Is this person here on a VISA?"
    check "Married as of 12/31/2019"
    click_on "Save this person"
    expect(page).to have_text("Gallagher Gnome")

    click_on "Done with this step"

    # Dependent related questions
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse pay any child or dependent care expenses?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse adopt a child?")
    click_on "Yes"

    # Student questions
    expect(page).to have_selector("h1", text: "In 2019, was someone in your family a college or other post high school student?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse pay any student loan interest?")
    click_on "Yes"

    # Income from working
    select "3 jobs", from: "In 2019, how many jobs did you or your spouse have?"
    click_on "Next"
    expect(page).to have_selector("h1", text: "In 2019, did you live or work in any other states besides Virginia?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse receive wages or salary?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse have any income from contract or self-employment work?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse receive any tips?")
    click_on "Yes"

    # Income from benefits
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse receive any unemployment benefits?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse receive any disability benefits?")
    click_on "Yes"

    # Investment income/loss
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse have any income from interest or dividends?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse have any income from the sale of stocks, bonds, or real estate?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "Did you or your spouse report a loss from the sale of stocks, bonds, or real estate on your 2018 return?")
    click_on "Yes"

    # Retirement income/contributions
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse have any income from Social Security or Railroad Retirement Benefits?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse have any income from a retirement account, pension, or annuity proceeds?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse make any contributions to a retirement account?")
    click_on "Yes"

    # Other income
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse receive any other money?")
    click_on "Yes"
    fill_in "What were the other types of income that you or your spouse received?", with: "cash from gardening"
    click_on "Next"

    # Health insurance
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse purchase health insurance through the marketplace or exchange?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse have a Health Savings Account?")
    click_on "Yes"

    # Itemizing
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse pay any medical, dental, or prescription expenses?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse make any charitable contributions?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse have any income from gambling winnings, including the lottery?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse pay for any eligible school supplies as a teacher, teacher's aide, or other educator?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse pay any state, local, real estate, sales, or other taxes?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse receive a state or local income tax refund?")
    click_on "Yes"

    # Related to home ownership
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse sell a home?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse pay any mortgage interest?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "Did you or your spouse receive the First Time Homebuyer Credit in 2008?")
    click_on "Yes"

    # Miscellaneous
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse have a loss related to a declared Federal Disaster Area?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse have debt cancelled or forgiven by a lender?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse receive any letter or bill from the IRS?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "Have you or your spouse had the Earned Income Credit, Child Tax Credit, American Opportunity Credit, or Head of Household filing status disallowed in a prior year?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse make any estimated tax payments or apply your 2018 refund to your 2019 taxes?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "Did you or your spouse report a business loss on your 2018 tax return?")
    click_on "Yes"
    expect(page).to have_selector("h1", text: "In 2019, did you or your spouse purchase energy efficient home items?")
    click_on "Yes"

    # Additional Information
    fill_in "Is there any more information you think we should know?", with: "One of my kids moved away for college, should I include them as a dependent?"
    click_on "Next"

    # Overview: Documents
    expect(page).to have_selector("h1", text: "Collect all your documents and have them with you.")
    click_on "Continue"

    # IRS guidance
    expect(page).to have_selector("h1", text: "First, we need to confirm your basic information.")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Attach photos of ID cards")
    attach_file("document_type_upload_form[document]", Rails.root.join("spec", "fixtures", "attachments", "picture_id.jpg"))
    click_on "Upload"
    attach_file("document_type_upload_form[document]", Rails.root.join("spec", "fixtures", "attachments", "picture_id.jpg"))
    click_on "Upload"
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Confirm your identity with a photo of yourself")
    click_on "Submit a photo"

    expect(page).to have_selector("h1", text: "Share a photo of yourself holding your ID card")
    attach_file("document_type_upload_form[document]", Rails.root.join("spec", "fixtures", "attachments", "picture_id.jpg"))
    click_on "Upload"
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Attach photos of Social Security Card or ITIN")
    attach_file("document_type_upload_form[document]", Rails.root.join("spec", "fixtures", "attachments", "picture_id.jpg"))
    click_on "Upload"
    click_on "Continue"

    # Documents: Intro
    expect(page).to have_selector("h1", text: "All right, let's collect your documents!")
    click_on "Continue"


    expect(page).to have_selector("h1", text: "Attach your 1095-A's")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Attach your 1098's")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Attach your 1098-E's")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Attach your 1098-T's")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Attach your 1099-A's")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Attach your 1099-B's")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Attach your 1099-C's")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Attach your 1099-DIV's")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Attach your 1099-INT's")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Share your employment documents")
    attach_file("document_type_upload_form[document]", Rails.root.join("spec", "fixtures", "attachments", "test-pattern.png"))
    click_on "Upload"

    expect(page).to have_content("test-pattern.png")
    expect(page).to have_link("Remove")

    attach_file("document_type_upload_form[document]", Rails.root.join("spec", "fixtures", "attachments", "picture_id.jpg"))
    click_on "Upload"

    expect(page).to have_content("test-pattern.png")
    expect(page).to have_content("picture_id.jpg")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Attach your 1099-R's")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Attach your 1099-S's")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Attach your 1099-SA's")
    click_on "I don't have this right now"

    expect(page).to have_selector("h1", text: "Attach your 1099-G's")
    click_on "I don't have this right now"

    expect(page).to have_selector("h1", text: "Attach your 5498-SA's")
    click_on "I don't have this right now"

    expect(page).to have_selector("h1", text: "Attach your IRA Statements")
    click_on "I don't have this right now"

    expect(page).to have_selector("h1", text: "Attach your Property Tax Statements")
    click_on "I don't have this right now"

    expect(page).to have_selector("h1", text: "Attach your RRB-1099's")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Attach your SSA-1099's")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Attach your student account statements")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Attach your statements from childcare facilities or individuals who provided care.")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Attach your W-2G's")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Attach your 2018 tax return")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Do you have any additional documents?")
    attach_file("document_type_upload_form[document]", Rails.root.join("spec", "fixtures", "attachments", "test-pattern.png"))
    click_on "Upload"
    expect(page).to have_content("test-pattern.png")
    click_on "Continue"

    expect(page).to have_selector("h1", text: "Great work! Here's a list of what we've collected.")
    click_on "I've shared all my documents"

    # Interview time preferences
    fill_in "Do you have any time preferences for your interview phone call?", with: "During school hours"
    click_on "Continue"

    # Payment info
    expect(page).to have_selector("h1", text: "If due a refund, how would like to receive it?")
    choose "Mail me a check (slower)"
    click_on "Continue"
    expect(page).to have_selector("h1", text: "If due a refund, are you interested in using these savings options?")
    click_on "Continue"
    expect(page).to have_selector("h1", text: "If you have a balance due, would you like to make a payment directly from your bank account?")
    click_on "No"
    # Don't ask for bank details

    # Contact information
    expect(page).to have_text("What is your mailing address?")
    expect(page).to have_select('State', selected: 'Virginia')

    fill_in "Street address", with: "123 Main St."
    fill_in "City", with: "Anytown"
    select "California", from: "State"
    fill_in "ZIP code", with: "94612"
    click_on "Confirm"

    # Demographic Questions
    expect(page).to have_selector("h1", text: "Are you willing to answer some additional questions to help us better serve you?")
    click_on "Skip questions"

    # Additional Information
    fill_in "Anything else you'd like your tax preparer to know about your situation?", with: "Nope."
    click_on "Submit"

    expect(page).to have_selector("h1", text: "Success! Your tax information has been submitted.")
    expect(page).to have_text("Your confirmation number is: #{ticket_id}")
  end
end

